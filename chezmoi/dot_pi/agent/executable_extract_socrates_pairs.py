#!/usr/bin/env python3
"""
extract_socrates_pairs.py

Extract all socrates question/answer pairs from pi agent session files and
output them as a single JSON array.

WHAT IT DOES
------------
Pi stores each agent session as a .jsonl file (one JSON object per line) in
a session directory. This script:

  1. Scans every *.jsonl file in the given session directory.
  2. For each file, finds messages where the LLM called the "socrates" tool
     (a structured question to the user) and matches each call with the
     corresponding user response (toolResult).
  3. Pairs them up by toolCallId and extracts each individual question
     within a multi-question socrates call.
  4. Writes all pairs from all files into a single JSON array.

OUTPUT FORMAT
-------------
The output is a JSON array. Each element is an object with:

    question_id       unique identifier within the source session
    question_text     the question displayed to the user
    options           list of option labels (strings)
    recommended       index of the LLM's recommended option (null if none)
    recommended_label the label of the recommended option (string or null)
    user_answer_text  what the user answered (selected label or free text)
    user_answer_type  "selected" | "custom" | "unanswered"
    session_file      filename of the source .jsonl file

HOW SESSION FILES ARE PARSED
----------------------------
The .jsonl file contains one JSON object per line. Each line is a "message"
event with a role (user, assistant, toolResult, etc). We only care about two:

  - Assistant messages → may contain a "toolCall" content block where the
    tool name is "socrates". The tool call's "arguments.questions" array has
    the question text, options, and recommended index.

  - ToolResult messages → the user's response. The "details.results[]" array
    has one entry per question, containing selectedOptions[] and/or
    customInput.

We index all results by toolCallId, then for each call we iterate through
each question and find its answer in the matching result. Some socrates calls
ask multiple questions at once; we handle that by matching on question_id
within the results list.

USAGE
-----
  python3 extract_socrates_pairs.py <session_dir> <output.json>

EXAMPLES
--------
  # Scan a specific project's session directory
  python3 extract_socrates_pairs.py \
      ~/.pi/agent/sessions/my-project/ \
      my-project_socrates_pairs.json

  # Scan the default sessions directory (all projects)
  python3 extract_socrates_pairs.py \
      ~/.pi/agent/sessions/ \
      all_sessions_socrates_pairs.json

  # Scan and pipe through jq to analyze
  python3 extract_socrates_pairs.py ~/.pi/agent/sessions/ /tmp/pairs.json
  cat /tmp/pairs.json | jq 'group_by(.user_answer_type) | map({key: .[0].user_answer_type, value: length})'
"""

import json
import sys
from pathlib import Path


def extract_pairs(filepath: Path) -> list[dict]:
    """
    Parse a single session JSONL file and return a list of question/answer pairs.

    This function:
      1. Reads all lines, parsing each as JSON (skipping malformed ones).
      2. Scans for two event types:
         - Assistant messages containing a socrates toolCall block.
         - Tool result messages where toolName is "socrates".
      3. Indexes results by toolCallId.
      4. For each socrates call, iterates over each question it asked and
         extracts the user's answer from the paired result.
    """
    lines = []
    with open(filepath) as f:
        for i, line in enumerate(f, 1):
            try:
                obj = json.loads(line)
                obj["_line"] = i
                lines.append(obj)
            except json.JSONDecodeError:
                # Skip malformed lines (shouldn't happen but be defensive)
                continue

    # Collect all socrates tool calls and tool results from the session
    calls = []
    results = []

    for obj in lines:
        msg = obj.get("message", {})
        role = msg.get("role")

        # --- Assistant message: may contain toolCall blocks ---
        if role == "assistant":
            content = msg.get("content", [])
            for block in content:
                if block.get("type") == "toolCall" and block.get("name") == "socrates":
                    calls.append({
                        "line": obj["_line"],
                        "id": obj["id"],
                        "toolCallId": block.get("id"),
                        "arguments": block.get("arguments", {}),
                    })

        # --- Tool result message: response to a tool call ---
        if role == "toolResult" and msg.get("toolName") == "socrates":
            results.append({
                "line": obj["_line"],
                "toolCallId": msg.get("toolCallId"),
                # 'details' contains the parsed user response with selected
                # options and/or custom input text
                "details": msg.get("details"),
                "content_text": (
                    msg.get("content", [{}])[0].get("text", "")
                    if msg.get("content") else ""
                ),
            })

    # Index results by toolCallId for O(1) pairing
    result_by_id = {r["toolCallId"]: r for r in results}

    # Build pairs: for each call, iterate over each question in the call
    pairs = []
    for c in calls:
        r = result_by_id.get(c["toolCallId"])
        questions = c["arguments"].get("questions", [])

        for q in questions:
            qid = q.get("id", "")
            qtext = q.get("question", "")
            opts = q.get("options", [])
            # recommended can be an int (index) or sometimes a list [0]
            rec_raw = q.get("recommended")
            rec = rec_raw[0] if isinstance(rec_raw, list) else rec_raw

            user_answer_text = ""
            user_answer_type = ""

            # If we have a result for this call, find the matching
            # question entry by question_id and extract the answer
            if r:
                details = r.get("details", {})
                results_list = details.get("results", [])
                for res in results_list:
                    if res.get("id") == qid:
                        sel = res.get("selectedOptions", [])
                        ci = res.get("customInput")
                        if ci:
                            user_answer_text = ci
                            user_answer_type = "custom"
                        elif sel:
                            # sel entries can be int indices or string labels
                            parts = []
                            for s in sel:
                                if isinstance(s, int) and s < len(opts):
                                    parts.append(str(opts[s]))
                                else:
                                    parts.append(str(s))
                            user_answer_text = "; ".join(parts)
                            user_answer_type = "selected"
                        break

            pair = {
                "question_id": qid,
                "question_text": qtext,
                # Options may be plain strings or objects with a 'label' key
                "options": [str(o) if isinstance(o, dict) else str(o) for o in opts],
                "recommended": rec,
                "recommended_label": (
                    str(opts[rec])
                    if rec is not None and isinstance(rec, int) and rec < len(opts)
                    else None
                ),
                "user_answer_text": user_answer_text,
                "user_answer_type": user_answer_type or "unanswered",
                "session_file": filepath.name
            }
            pairs.append(pair)

    return pairs


def main():
    if len(sys.argv) != 3:
        print(
            "Usage: python3 extract_socrates_pairs.py <session_dir> <output.json>",
            file=sys.stderr,
        )
        sys.exit(1)

    session_dir = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    if not session_dir.is_dir():
        print(f"Error: not a directory: {session_dir}", file=sys.stderr)
        sys.exit(1)

    files = sorted(session_dir.glob("*.jsonl"))
    print(f"Scanning {len(files)} files in {session_dir}...")

    all_pairs = []
    for i, f in enumerate(files, 1):
        if i % 100 == 0:
            print(
                f"  Progress: {i}/{len(files)}"
                f" ({len(all_pairs)} pairs found so far)"
            )
        try:
            pairs = extract_pairs(f)
            if pairs:
                all_pairs.extend(pairs)
        except Exception as e:
            print(f"  Error on {f.name}: {e}", file=sys.stderr)

    with open(output_file, "w") as out:
        json.dump(all_pairs, out, indent=2, ensure_ascii=False)

    print(f"\nDone. {len(all_pairs)} socrates question pairs written to {output_file}")

    if all_pairs:
        answered = sum(1 for p in all_pairs if p["user_answer_type"] != "unanswered")
        custom = sum(1 for p in all_pairs if p["user_answer_type"] == "custom")
        selected = sum(1 for p in all_pairs if p["user_answer_type"] == "selected")
        print(
            f"  Answered: {answered}"
            f" | Custom: {custom}"
            f" | Selected: {selected}"
            f" | Unanswered: {len(all_pairs) - answered}"
        )


if __name__ == "__main__":
    main()
