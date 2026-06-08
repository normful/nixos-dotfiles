#!/usr/bin/env python3
"""
Extract natural-language questions from AI coding agent session logs.

Goal: From thousands of assistant "stop" messages (where the agent finishes
a turn without calling tools), extract only the sentences that contain
questions — the agent asking the user for decisions, approvals, or guidance.

Pipeline:
  Phase 1 - Collect every assistant stop message across all .jsonl session files
  Phase 2 - Flatten each message to one line, split into sentences, keep those with ?
  Phase 3 - Walk backwards from ? to discard markdown/context junk before the question

Tricky parts (why simple split doesn't work):
  - Stop messages are markdown-heavy: tables, lists, code blocks, headings, --- rules.
    A naive sentence split on ". " breaks on code like "p.manufacturer?.id".
  - Flattening \n to spaces destroys section boundaries. We preserve them with
    \x00 sentinel markers before flattening, then use those in Phase 3.
  - Questions often appear at the END of a long paragraph of analysis
    ("Here's what I found... \n## Questions: \n1. Want me to proceed?")
    We need to walk backwards to find where the actual question starts.
  - Code references like `sort?` or `p.manufacturer?` contain ? but are not questions.
    We check the character before ? — if it's a backtick or paren, skip it.
"""

import json, glob, re, tempfile, sys

if len(sys.argv) < 2:
    print("Usage: python extract_questions.py <session_dir>")
    sys.exit(1)
session_dir = sys.argv[1]


# ════════════════════════════════════════════════
# Phase 1: Collect all assistant stop messages
# ════════════════════════════════════════════════

stop_texts = []
for path in glob.glob(f"{session_dir}/*.jsonl"):
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            # Only assistant messages with stopReason="stop"
            if obj.get("type") != "message":
                continue
            msg = obj.get("message", {})
            if msg.get("role") != "assistant":
                continue
            if msg.get("stopReason") != "stop":
                continue
            for block in msg.get("content", []):
                if block.get("type") == "text":
                    stop_texts.append(block["text"])
print(f"Phase 1: {len(stop_texts)} stop messages")


# ════════════════════════════════════════════════
# Phase 2: Flatten to single line, split into sentences
# ════════════════════════════════════════════════

raw_questions = []
for text in stop_texts:
    # Remove fenced code blocks entirely (```...```)
    text = re.sub(r'```[\s\S]*?```', '', text)

    # TRICKY: Before flattening newlines, preserve markdown section boundaries
    # that we'll need later to discard context before questions.
    # We use null bytes (\x00) as sentinels that won't appear in normal text.
    text = re.sub(r'\n---\s*\n', ' \x00SEP\x00 ', text)   # horizontal rules
    text = re.sub(r'\n##+\s+', ' \x00H\x00 ', text)         # headings (##, ###)

    # Now flatten: collapse all whitespace (including newlines) to single spaces
    text = re.sub(r'\s+', ' ', text).strip()
    if not text or "?" not in text:
        continue

    # Split on sentence boundaries: . ! ? followed by space + capital letter/quote
    # TRICKY: The lookbehind (?<=[.!?]) keeps the punctuation attached to the sentence.
    # The lookahead (?=[A-Za-z...]) ensures we don't split on "e.g." or "i.e."
    sentences = re.split(r'(?<=[.!?])\s+(?=[A-Za-z0-9\"\u300c\u300e\(])', text)

    # Also split on sentinel markers (--- and ## boundaries) — these are preserved
    # during flattening and indicate section boundaries that should cut context
    parts = []
    for s in sentences:
        sub = re.split(r'\x00SEP\x00|\x00H\x00', s)
        parts.extend(sub)
    sentences = parts

    # Also split on ": " followed by numbered items (e.g., "Questions: 1. Which...")
    parts = []
    for s in sentences:
        sub = re.split(r'(?<=:)\s+(?=\d+\.)', s)
        parts.extend(sub)
    sentences = parts

    # Strip sentinel markers now — they've served their purpose as split boundaries
    sentences = [s.replace('\x00SEP\x00', ' ').replace('\x00H\x00', ' ') for s in sentences]
    for sent in sentences:
        sent = sent.strip()
        if not sent or "?" not in sent:
            continue
        # Strip leading bullet markers (-, *, numbers)
        sent = re.sub(r'^[\s\-*\d\.\u2022\u3000]+', '', sent).strip()
        if not sent or len(sent.split()) < 3:
            continue
        raw_questions.append(sent)
print(f"Phase 2: {len(raw_questions)} raw question lines")


# ════════════════════════════════════════════════
# Phase 3: Walk backwards from ? to find question start
# ════════════════════════════════════════════════

def trim_to_question(line):
    """Find the `?` in a line, walk backwards to find where the actual question
    sentence starts. Discard everything before that point.
    
    This handles cases like:
      "Here's my analysis... --- ## Questions Before Proceeding: 1. **Which auth method do you prefer?"
      → "Which auth method do you prefer?"
    """
    q_idx = line.find("?")
    if q_idx < 0:
        return line

    before_q = line[:q_idx+1]

    # Walk backwards: find markdown section boundaries
    # --- (horizontal rule) — everything before it is context, discard
    last_sep = before_q.rfind('\x00SEP\x00')
    if last_sep >= 0:
        before_q = before_q[last_sep + 7:]
        if before_q.find('?') < 0:
            return line
    else:
        # ## heading — also discard context before the heading
        last_h = before_q.rfind('\x00H\x00')
        if last_h >= 0:
            before_q = before_q[last_h + 6:]

    # Split on ". " sentence boundaries, keep only the fragment containing ?
    candidates = re.split(r'(?<=[.!])\s+(?=[A-Z])', before_q)
    for c in reversed(candidates):
        if "?" in c:
            before_q = c
            break

    # Strip leading markdown/table prefixes
    before_q = re.sub(r'^[\d\s\-*\.\u2022\u3000\|]+', '', before_q).strip()
    if not before_q or len(before_q) < 5:
        return line

    # Strip heading labels ("Questions Before Proceeding:" etc.)
    # Only strip if the heading is shorter than 40% of the remaining text
    m = re.match(r'^[A-Z][^:]+:\s*', before_q)
    if m and len(m.group()) < len(before_q) * 0.4:
        before_q = before_q[m.end():]

    # Ensure the result starts with a capital letter or quote
    if not re.match(r'^[A-Za-z\"\u300c]', before_q):
        m = re.search(r'[A-Z][a-z]', before_q)
        if m:
            before_q = before_q[m.start():]

    return before_q


trimmed = []
for q in raw_questions:
    t = trim_to_question(q)
    if not t or "?" not in t:
        continue
    # Cut at first ? — discard anything after it (another sentence)
    first_q = t.find("?")
    t = t[:first_q+1]
    # TRICKY: Strip trailing parenthetical fragments like "(cascade nullify?)"
    t = re.sub(r'\s*\([^)]*\?\s*\)?\s*$', '', t).strip()
    if not t or "?" not in t or len(t.split()) < 3:
        continue

    # TRICKY: If text is still >80 chars, find the last known question-start
    # phrase and cut there. Catches markdown list/table content that survived
    # earlier passes (e.g., "1. **Keep it** - explanation... Want me to rename?")
    if len(t) > 80:
        qpos = t.rfind('?')
        if qpos > 0:
            sub = t[:qpos]
            patterns = [
                'Want me', 'Would you', 'Should I', 'Could you', 'Do you',
                'Can I', 'Shall I', 'Will you', 'Are you', 'Is there',
                'What would', 'Which do', 'Which folder', 'What do',
                'How can', 'Ready to', 'Good to', 'Delete the',
            ]
            best = -1
            for p in patterns:
                idx = sub.rfind(p)
                if idx > best:
                    best = idx
            if best >= 0:
                t = t[best:]

    # Reject ? attached to code references: `sort?` or p.manufacturer?)
    q_idx = t.find("?")
    if q_idx > 0 and t[q_idx-1] in ('`', ')'):
        continue

    trimmed.append(t)

# Remove any remaining table rows (lines containing pipe characters)
# TRICKY: Table cells can contain ? inside code references like {id? or .method?
# These look like questions but aren't — dropping all pipe lines is safe
# because no real question uses markdown table syntax.
final = [t for t in trimmed if '|' not in t]
trimmed = final

# Deduplicate (case-insensitive, preserving first occurrence)
seen = set()
deduped = []
for t in trimmed:
    key = t.lower().strip()
    if key not in seen:
        seen.add(key)
        deduped.append(t)
print(f"Phase 3: {len(trimmed)} → deduped to {len(deduped)}")


# ════════════════════════════════════════════════
# Phase 4: Alphabetically sort the deduplicated questions
# ════════════════════════════════════════════════
deduped.sort(key=lambda s: s.lower())
print(f"Phase 4: sorted {len(deduped)} questions")


# ════════════════════════════════════════════════
# Output to temp file
# ════════════════════════════════════════════════

with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".txt", prefix="stop-questions-") as tmp:
    for s in deduped:
        tmp.write(s + "\n")
    outpath = tmp.name
print(f"Output: {outpath}")
