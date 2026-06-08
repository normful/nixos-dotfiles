#!/usr/bin/env python3
"""
Extract all socrates question/answer pairs from pi agent session JSONL files.

What this does:
  - Scans every *.jsonl file in a session directory (pi stores one session per file)
  - Finds "socrates" tool calls (where the LLM asked the user a structured question)
  - Pairs each tool call with its corresponding tool result (the user's response)
  - Writes all pairs to a single JSON array file

The output JSON file is an array of objects — one per question asked. Each object
has these fields:

    question_id         unique identifier for the question within its session
    question_text       the question text shown to the user
    options             list of option labels the user could pick from
    recommended         index of the option the LLM recommended (null if none)
    recommended_label   string label of the recommended option
    user_answer_text    what the user responded (selected option label or free text)
    user_answer_type    "selected" | "custom" | "unanswered"
    session_file        filename of the source session JSONL


Usage:
    python3 extract_socrates_pairs.py <session_dir> <output.json>

Example:
    python3 extract_socrates_pairs.py ~/.pi/agent/sessions/my-project/ socrates_pairs.json
"""

import json
import sys
from pathlib import Path


def extract_pairs(filepath: Path) -> list[dict]:
    """
    Parse a single session JSONL file and return a list of question/answer pairs.

    The .jsonl format has one JSON object per line. Each line represents a
    conversation event: a message from the user, a message from the assistant,
    a tool result, a model change, etc. We look for two specific event types:

    1. Assistant messages containing a toolCall block for the "socrates" tool.
       This is where the LLM asks a structured question to the user via the
       socrates tool (defined in the system prompt). The question details
       (id, text, options, recommendation) are in the tool call arguments.

    2. Tool result messages where toolName is "socrates". This is where the
       user's response comes back. The response is in the 'details' field,
       specifically the 'results' array which has one entry per question
       asked in that call (a single socrates call can ask multiple questions).

    We match calls to results by toolCallId, then for each question within
    a call, we extract the user's answer from the corresponding result entry.
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
