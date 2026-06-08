#!/usr/bin/env python3
"""
Cluster extracted questions by type, topic, and action.

PIPELINE (run in order)
───────────────────────
  1. ~/.pi/agent/extract_questions.py <session_dir>
       → produces a .txt file of extracted questions
  2. ~/.pi/agent/cluster_questions.py <questions_file> [--json <outfile>]
       → classifies into clusters, prints summary, optionally writes JSON

EXAMPLE INVOCATIONS
───────────────────
  # Read a previously extracted questions file, print cluster output to terminal
  python3 ~/.pi/agent/cluster_questions.py /tmp/stop-questions-xxxxx.txt

  # Write JSON records alongside terminal output
  python3 ~/.pi/agent/cluster_questions.py /tmp/stop-questions-xxxxx.txt --json /tmp/clustered.json

  # Full pipeline from session extraction to clustered JSON
  txt=$(python3 ~/.pi/agent/extract_questions.py /path/to/session/dir | tail -1 | grep -o '/[^ ]*\.txt')
  python3 ~/.pi/agent/cluster_questions.py "$txt" --json /tmp/clustered.json

INPUT FORMAT
────────────
  One question per line (plain text, no labels). This is exactly the output
  format produced by ~/.pi/agent/extract_questions.py.

OUTPUT
──────
  Terminal: color-coded cluster groups with subcluster breakdown + summary table
  JSON (--json): array of {"input", "cluster", "subcluster_key", "domains"} records

GOAL
────

GOAL
────
AI coding agents generate thousands of "stop" messages — questions asking
the user for decisions, approvals, guidance. These questions overwhelm users
because they're repetitive, context-buried, or scattered across sessions.

This script's job is to REDUCE that noise into digestible groups:
  - "Which cluster dominates my session?" (68% of questions are PERMISSION + CHOICE)
  - "What doesn't fit?" (the UNCLUSTERED bucket flags extraction issues)
  - "What domain keeps coming up?" (product, order, admin, etc.)

PIPELINE
────────
  1. load_questions()       — read the deduped, sorted question list
  2. classify_domain()      — tag each line with topic keywords (non-exclusive)
  3. CLUSTER_CLASSIFIERS[]  — first-match-wins priority chain of 14 classifiers
  4. print_cluster()        — group by subcluster, display with domain tags
  5. UNCLUSTERED            — lines that matched no classifier (debug signal)

CLASSIFIER DESIGN
─────────────────
  PRIORITY matters. More specific classifiers come first:
    JUNK → COMMIT → SHOULD_I → PROCEED → CHOICE → VALIDATE → YES_NO →
    OPEN → CLARIFY → OFFER → ACTION_ITEM → HOW → WHEN_WHERE_WHY → MISC

  Each classifier returns (CLUSTER_NAME, subcluster_key) or None.
  subcluster_key enables intra-cluster grouping (e.g. "want_me_to_fix",
  "want_me_to_check", "should_i_add").

  Domain tags are independent — they're added alongside the cluster label
  so you can see, e.g., "CHOICE (which) [product]" vs "CHOICE (which) [admin]".

WHY 33% UNCLUSTERED IS NORMAL
──────────────────────────────
  The 327 lines in UNCLUSTERED are primarily EXTRACTION ARTIFACTS:
    - Code refs with inline ? (loginMutation.data?, success?)
    - Markdown formatting surviving the trimmer (**bold** prefixes, backticks)
    - Full commit-diff paragraphs with a trailing ?
    - Mid-sentence "Want me to" (the extraction kept prefix context)
  These are not real questions — they're signals to improve the EXTRACTION
  script's trimmer, not the clustering script's classifiers.

Usage:
  python3 cluster_questions.py <questions_file>
  python3 cluster_questions.py /var/folders/r9/.../stop-questions-xxxxx.txt
"""

import re, sys
from collections import defaultdict
from pathlib import Path


# ══════════════════════════════════════════════════════════════════════
# Utilities
# ══════════════════════════════════════════════════════════════════════

def load_questions(path):
    """Load one question per line, skipping blanks."""
    with open(path) as f:
        return [line.strip() for line in f if line.strip()]


# ══════════════════════════════════════════════════════════════════════
# CLASSIFIERS
# ══════════════════════════════════════════════════════════════════════
#
# Each classifier accepts a single question line and returns either:
#   (CLUSTER_NAME, subcluster_key)          ← matched
#   None                                     ← did not match
#
# Subcluster keys enable intra-cluster grouping when printed.
# They're descriptive strings, not enums — chosen to be human-readable.
#
# ══════════════════════════════════════════════════════════════════════

def classify_junk(line):
    """Lines that aren't really questions — extraction artifacts like code refs, dangling bullets, quotes, backticks.

    These slip through extract_questions.py's trimmer because it only checks
    for backtick or paren immediately BEFORE the ?, but misses leading
    formatting characters or `?` inside code snippets like loginMutation.data?.

    Priority: 1 (must be first — every other classifier would produce false positives on these).
    """
    # Starts with a quote, bullet, backtick, or bare asterisk (markdown formatting residues)
    if re.match(r'^["*`\-\u2022\u3000]', line):
        return ("JUNK", "leading_formatting")
    # ? appears INSIDE backticks and not as the final character — this is a code ref, not a question.
    # e.g. "loginMutation.data?" inside a sentence, vs "Want me to check this?" at end.
    if re.search(r'`[^`]*\?', line) and not re.search(r'\?\s*$', line):
        return ("JUNK", "code_reference")
    return None


def classify_commit(line):
    """Agent asking about git committing.

    These are so frequent they merit their own cluster, separate from PROCEED,
    because "commit" is a distinct workflow step the user often wants to batch
    or defer.

    Priority: 2 (before PROCEED — commit questions are more specific greenlights).
    """
    lo = line.lower()
    if re.match(r'^[Cc]ommit ', lo):
        return ("COMMIT", "commit")
    if re.match(r'^[Ww]ant me to commit', lo):
        return ("COMMIT", "commit")
    if re.search(r'\bcommit\b.*\?$', lo):
        return ("COMMIT", "commit")
    return None


def classify_should_I(line):
    """'Should I' / 'Shall I' questions — agent asking permission for a specific action.

    Distinguished from PROCEED because "Should I add X?" or "Should I test Y?"
    asks about WHAT action to take, not just whether to start.

    Priority: 3 (before PROCEED — Should I is more specific than general proceed).
    """
    lo = line.lower()
    if re.match(r'^[Ss]hould I ', lo):
        action = re.sub(r'^[Ss]hould I ', '', line, re.IGNORECASE).split('?')[0].strip()
        verb = action.split()[0].lower() if action.split() else ""
        return ("SHOULD_I", f"should_i_{verb}")
    if re.match(r'^[Ss]hall [Ii] ', lo):
        return ("SHOULD_I", "shall_i")
    return None


def classify_proceed(line):
    """Permission / greenlight questions — agent asking for a go/no-go to continue.

    These are the MOST COMMON cluster (~23% of all questions). The agent
    completed something and is waiting for the user to say "yes, continue."

    Subclusters break down by phrasing (want_me_to_*, ready_to, shall_i, good_to_go)
    and by action verb (want_me_to_fix: 26, want_me_to_update: 11, etc.)

    Priority: 4.
    """
    lo = line.lower()
    # "Want me to" — the single most common pattern (227 occurrences).
    # Subclassifies by the verb after "want me to" (e.g., fix, check, update, add).
    if re.match(r'^[Ww]ant me to ', lo):
        action = re.sub(r'^[Ww]ant me to ', '', line, flags=re.IGNORECASE).split('?')[0].strip()
        verb = action.split()[0].lower() if action.split() else ""
        # Strip non-alpha chars (backticks, quotes) from verb so subcluster key stays clean
        verb = re.sub(r'[^a-zA-Z]', '', verb)
        return ("PROCEED", f"want_me_to_{verb}" if verb else "want_me_to")
    # "Shall I" — overlaps with SHOULD_I but these proceed/begin/start variants
    # are pure greenlight, not "which action."
    if re.match(r'^[Ss]hall [Ii] ', lo):
        return ("PROCEED", "shall_i")
    # "Ready to" — checking if user is prepared for next step
    if re.match(r'^[Rr]eady to ', lo):
        return ("PROCEED", "ready_to")
    # "Should I proceed/begin/start/implement" — specific proceed variants
    if re.match(r'^[Ss]hould I (proceed|begin|start|implement)', lo):
        return ("PROCEED", "should_i_proceed")
    if re.match(r'^[Gg]ood to go', lo):
        return ("PROCEED", "good_to_go")
    return None


def classify_choice(line):
    """Decision / alternative questions — agent presents options and asks user to pick.

    Second most common cluster (~16%). The agent identified multiple valid paths
    and needs user direction.

    Subclusters: which, option_list (A/B/C choices), or_alternative, 
    what_would_you_like, would_you_like.

    Priority: 5.
    """
    lo = line.lower()
    if re.match(r'^[Ww]hich ', lo):
        return ("CHOICE", "which")
    # "Option A", "Option B", "Approach 1", "Approach 2" etc.
    if re.search(r'(Option [A-D]|Approach \d)', line, re.IGNORECASE):
        return ("CHOICE", "option_list")
    if re.match(r'^[Oo]r ', lo):
        return ("CHOICE", "or_alternative")
    if re.match(r'^[Ww]hat would you like', lo):
        return ("CHOICE", "what_would_you_like")
    if re.match(r'^[Ww]ould you like', lo):
        if re.search(r'(Option [A-D]|Approach \d)', line, re.IGNORECASE):
            return ("CHOICE", "option_list")
        return ("CHOICE", "would_you_like")
    return None


def classify_validate(line):
    """Validation / approval questions — 'Is this right?' 'Does this look good?'

    These are status checks, not asking for a decision between alternatives.
    The agent has done something and wants confirmation it's correct.

    Subclusters: does_this, is_this, is_there, is_the, are_you_there, what_about, any.

    Priority: 6.
    """
    lo = line.lower()
    if re.match(r'^[Dd]oes (this|that) ', lo):
        return ("VALIDATE", "does_this")
    if re.match(r'^[Ii]s this ', lo):
        return ("VALIDATE", "is_this")
    if re.match(r'^[Ii]s there ', lo):
        return ("VALIDATE", "is_there")
    if re.match(r'^[Dd]oes the ', lo):
        return ("VALIDATE", "does_the")
    if re.match(r'^[Ii]s the ', lo):
        return ("VALIDATE", "is_the")
    if re.match(r'^[Aa]re (you|there) ', lo):
        return ("VALIDATE", "are_you_there")
    if re.match(r'^[Ww]hat about ', lo):
        return ("VALIDATE", "what_about")
    if re.match(r'^[Aa]ny ', lo):
        return ("VALIDATE", "any")
    return None


def classify_open(line):
    """Open-ended 'what next / anything else' questions.

    No specific action proposed — just asking for general direction.
    Distinct from CHOICE because there are no options presented.

    Subclusters: what_next, anything_else, open_offer.

    Priority: 7.
    """
    lo = line.lower()
    if re.search(r'what (next|else|would you like|do you want)', lo):
        return ("OPEN", "what_next")
    if re.match(r'^[Ii]s there anything else', lo):
        return ("OPEN", "anything_else")
    if re.match(r'^[Aa]nything else', lo):
        return ("OPEN", "anything_else")
    if re.match(r'^[Nn]ow,? what', lo):
        return ("OPEN", "what_next")
    if re.match(r'^[Ww]here would you like to go', lo):
        return ("OPEN", "what_next")
    if re.match(r'^[Ww]hat can I', lo):
        return ("OPEN", "open_offer")
    if re.match(r'^[Ww]hat do you need', lo):
        return ("OPEN", "open_offer")
    if re.match(r'^[Ww]hat\'s on your mind', lo):
        return ("OPEN", "open_offer")
    return None


def classify_clarify(line):
    """Agent asking user to clarify their request — the agent doesn't understand.

    These are rare (~0.4%) but important: they indicate the user's input was
    ambiguous or the agent couldn't resolve context.

    Priority: 8.
    """
    lo = line.lower()
    if re.match(r'^[Cc]ould you (clarify|describe|explain|elaborate|share)', lo):
        return ("CLARIFY", "could_you")
    if re.match(r'^[Cc]an you (clarify|describe|explain|elaborate|share|provide)', lo):
        return ("CLARIFY", "can_you")
    if re.match(r'^[Ww]hat do you mean', lo):
        return ("CLARIFY", "what_do_you_mean")
    if re.search(r'is this what you', lo):
        return ("CLARIFY", "is_this_what")
    return None


def classify_offer(line):
    """'Do you want me to?' / 'Do you want?' — agent offering a service.

    Similar to PROCEED but phrased as an offer/question to the user rather
    than a request for permission. The agent is presenting options it can execute.

    Subclusters: do_you_want_me_to, do_you_want.

    Priority: 9.
    """
    lo = line.lower()
    if re.match(r'^[Dd]o you want me to', lo):
        return ("OFFER", "do_you_want_me_to")
    if re.match(r'^[Dd]o you want ', lo):
        return ("OFFER", "do_you_want")
    return None


def classify_action_item(line):
    """Lines starting with imperative verbs — agent proposing specific tasks.

    "Add X?", "Delete Y?", "Create Z?" — the agent proposes a concrete action.
    These look like task items more than questions, but the trailing ? means
    the agent is asking for approval.

    Priority: 10 (after more specific patterns like PROCEED, CHOICE).
    """
    lo = line.lstrip()  # preserve case for verb matching; strip leading whitespace/bold markers
    action_verbs = r'^(Add|Remove|Update|Delete|Create|Fix|Change|Convert|Implement|Build|Rename|Refactor|Move|Keep|Skip|Start|Use|Extract|Include|Document|Investigate|Run|Merge|Rebuild|Replace|Drop)\b'
    if re.match(action_verbs, lo, re.IGNORECASE):
        verb = re.match(action_verbs, lo, re.IGNORECASE).group(1).lower()
        return ("ACTION_ITEM", verb)
    return None


def classify_yes_no(line):
    """Catch-all for yes/no questions starting with auxiliary verbs not caught above.

    These are structurally simple questions (auxiliary verb + subject + rest + ?)
    that don't fit the more specific clusters. They tend to be about specific
    technical details: "Does Inertia pass cart data?", "Has the migration run?".

    Subclusters: do, are, has, was, were, did, can, but, what, so.

    Priority: 11.
    """
    lo = line.lower()
    if re.match(r'^[Dd]o(es)? (we|the|I|you|this) ', lo):
        return ("YES_NO", "do")
    if re.match(r'^[Aa]re (we|the|there|you|they) ', lo):
        return ("YES_NO", "are")
    if re.match(r'^[Hh]as ', lo):
        return ("YES_NO", "has")
    if re.match(r'^[Ww]ere ', lo):
        return ("YES_NO", "were")
    if re.match(r'^[Ww]as ', lo):
        return ("YES_NO", "was")
    if re.match(r'^[Dd]id ', lo):
        return ("YES_NO", "did")
    if re.match(r'^[Cc]an ', lo):
        return ("YES_NO", "can")
    if re.match(r'^[Bb]ut ', lo):
        return ("YES_NO", "but")
    if re.match(r'^[Ww]hat (if|are|do|should|could|would) ', lo):
        return ("YES_NO", "what")
    if re.match(r'^[Ss]o ', lo):
        return ("YES_NO", "so")
    return None


def classify_how_question(line):
    """'How' questions — agent asking about implementation approach.

    "How to handle part number uniqueness?", "How should we handle the data layer?"
    These are architecture/design questions, not permission questions.

    Priority: 12.
    """
    lo = line.lower()
    if re.match(r'^[Hh]ow ', lo):
        return ("HOW", "how_question")
    return None


def classify_when_where_why(line):
    """'When / Where / Why / Who' questions — agent probing for context.

    "When does each branch fire?", "Where are you seeing the slowness?",
    "Why in the constructor?" — these ask about timing, location, or rationale.

    Priority: 13.
    """
    lo = line.lower()
    if re.match(r'^[Ww]hen ', lo):
        return ("WHEN_WHERE_WHY", "when")
    if re.match(r'^[Ww]here ', lo):
        return ("WHEN_WHERE_WHY", "where")
    if re.match(r'^[Ww]hy ', lo):
        return ("WHEN_WHERE_WHY", "why")
    if re.match(r'^[Ww]ho ', lo):
        return ("WHEN_WHERE_WHY", "who")
    return None


def classify_misc(line):
    """Oddball patterns that don't fit elsewhere — last resort before UNCLUSTERED.

    Catches:
      - "Questions:" / "Question 1:" headers (extraction script kept labels)
      - Greetings ("Hello!", "Hi! 👋 How can I help you?")
      - Lowercase-starting fragments that somehow survived extraction
      - Section labels ("Purpose:", "Scope:", "Summary:")

    Priority: 14 (last).
    """
    lo = line.lower()
    if lo.startswith('questions') or lo.startswith('question'):
        return ("MISC", "question_header")
    if lo.startswith('purpose') or lo.startswith('summary') or lo.startswith('scope'):
        return ("MISC", "section_header")
    if re.match(r'^(hello|hi)', lo):
        return ("MISC", "greeting")
    # Lowercase-starting lines with ? but no code-ref pattern — likely fragments
    if re.match(r'^[a-z]', lo) and '?' in line:
        if not re.search(r'\b[a-z_]+\?', lo):
            return ("MISC", "fragment")
    return None


# ══════════════════════════════════════════════════════════════════════
# DOMAIN CLASSIFIER (non-exclusive, independent of cluster)
# ══════════════════════════════════════════════════════════════════════
#
# Unlike the cluster classifiers above (first-match-wins), domain tags
# are additive — one question can be tagged [product, admin, route] if
# it mentions all three. These tags appear in brackets after each line.
#
# ══════════════════════════════════════════════════════════════════════

def classify_domain(line):
    """Tag a question with technical domain topics. Multiple domains per question allowed."""
    lo = line.lower()
    domains = []
    if re.search(r'\b(product|sku|category|manufacturer)\b', lo):
        domains.append("product")
    if re.search(r'\b(order|checkout|cart|purchase)\b', lo):
        domains.append("order")
    if re.search(r'\b(admin|role|permission|sanctum|auth)\b', lo):
        domains.append("admin")
    if re.search(r'\b(migration|column|table|schema|database|db)\b', lo):
        domains.append("migration")
    if re.search(r'\b(test|spec|snapshot|assert)\b', lo):
        domains.append("test")
    if re.search(r'\b(route|endpoint|api|url|path)\b', lo):
        domains.append("route")
    if re.search(r'\b(frontend|ui|component|page|blade|inertia|react)\b', lo):
        domains.append("frontend")
    if re.search(r'\b(backend|controller|service|model|action)\b', lo):
        domains.append("backend")
    if re.search(r'\b(php|laravel|type(script)?|zod)\b', lo):
        domains.append("tech_stack")
    return domains if domains else None


# ══════════════════════════════════════════════════════════════════════
# PRIORITIZED CLASSIFIER PIPELINE
# ══════════════════════════════════════════════════════════════════════
#
# ORDER MATTERS. First match wins. More specific classifiers go first.
# If JUNK didn't come first, many code-ref lines would be misclassified as
# VALIDATE or YES_NO. If SHOULD_I came after PROCEED, "Should I proceed..."
# would match PROCEED as "should_i_proceed" instead.
#
# ══════════════════════════════════════════════════════════════════════

CLUSTER_CLASSIFIERS = [
    ("JUNK", classify_junk),            # 1. Extraction artifacts — not real questions
    ("COMMIT", classify_commit),         # 2. Git commit decisions
    ("SHOULD_I", classify_should_I),     # 3. "Should I X?" / "Shall I X?"
    ("PROCEED", classify_proceed),       # 4. "Want me to...", "Ready to...", greenlights
    ("CHOICE", classify_choice),         # 5. "Which...", "Or...", Option A/B
    ("VALIDATE", classify_validate),     # 6. "Does this look good?", "Is there...?"
    ("OPEN", classify_open),            # 7. "What next?", "Anything else?"
    ("CLARIFY", classify_clarify),       # 8. "Could you clarify...?"
    ("OFFER", classify_offer),           # 9. "Do you want me to...?"
    ("ACTION_ITEM", classify_action_item),  # 10. "Add X?", "Delete Y?" imperative proposals
    ("YES_NO", classify_yes_no),         # 11. Misc yes/no auxiliary verb questions
    ("HOW", classify_how_question),      # 12. "How to...?"
    ("WHEN_WHERE_WHY", classify_when_where_why),  # 13. "When/Where/Why/Who...?"
    ("MISC", classify_misc),            # 14. Last resort — greetings, fragments, headers
]


# ══════════════════════════════════════════════════════════════════════
# MAIN CLUSTERING LOGIC
# ══════════════════════════════════════════════════════════════════════

def cluster(questions):
    """Run each question through the classifier pipeline.

    Returns:
        buckets: dict of cluster_name → list of (question_text, subcluster_key, domain_tags)
        unclustered: list of (question_text, domain_tags) that matched no classifier
    """
    buckets = defaultdict(list)
    unclustered = []

    for q in questions:
        # Always compute domain tags (independent of cluster classification)
        domains = classify_domain(q)
        matched = False
        # First-match-wins through the priority-ordered classifier list
        for cluster_name, classifier in CLUSTER_CLASSIFIERS:
            result = classifier(q)
            if result:
                sub = result[1]
                buckets[result[0]].append((q, sub, domains))
                matched = True
                break
        if not matched:
            unclustered.append((q, domains))

    return buckets, unclustered


# ══════════════════════════════════════════════════════════════════════
# OUTPUT FORMATTING
# ══════════════════════════════════════════════════════════════════════

def print_cluster(cluster_name, items):
    """Print a cluster group with its subcluster breakdown and domain tags."""
    if not items:
        return
    # Group by subcluster for readable output
    by_sub = defaultdict(list)
    for q, sub, domains in items:
        by_sub[sub].append((q, domains))

    print(f"\n{'='*70}")
    print(f"  {cluster_name}  ({len(items)} questions)")
    print(f"{'='*70}")
    for sub in sorted(by_sub.keys()):
        group = by_sub[sub]
        print(f"\n  ── {sub} ({len(group)}):")
        for q, domains in group:
            domain_tag = f"  [{', '.join(domains)}]" if domains else ""
            # Truncate long lines for readability; actual text is in source file
            display = q if len(q) <= 120 else q[:117] + "..."
            print(f"    • {display}{domain_tag}")


def print_unclustered(items):
    """Print questions that didn't match any cluster — these signal extraction problems."""
    if not items:
        return
    print(f"\n{'='*70}")
    print(f"  UNCLUSTERED  ({len(items)} questions)")
    print(f"  {'='*70}")
    for q, domains in items:
        domain_tag = f"  [{', '.join(domains)}]" if domains else ""
        display = q if len(q) <= 120 else q[:117] + "..."
        print(f"  ?  {display}{domain_tag}")


# ══════════════════════════════════════════════════════════════════════
# CLI ENTRY POINT
# ══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import json as json_mod

    if len(sys.argv) < 2:
        print("Usage: python3 cluster_questions.py <questions_file> [--json <outfile>]")
        sys.exit(1)

    path = sys.argv[1]
    json_out = None
    if "--json" in sys.argv:
        idx = sys.argv.index("--json")
        if idx + 1 < len(sys.argv):
            json_out = sys.argv[idx + 1]

    questions = load_questions(path)
    print(f"Loaded {len(questions)} questions from {path}")

    buckets, unclustered = cluster(questions)

    # Build JSON records: one per input line, preserving input order
    records = []
    for q in questions:
        matched = False
        for cluster_name, classifier in CLUSTER_CLASSIFIERS:
            result = classifier(q)
            if result:
                sub = result[1]
                domains = classify_domain(q)
                records.append({
                    "input": q,
                    "cluster": result[0],
                    "subcluster_key": sub,
                    "domains": domains or [],
                })
                matched = True
                break
        if not matched:
            domains = classify_domain(q)
            records.append({
                "input": q,
                "cluster": "UNCLUSTERED",
                "subcluster_key": None,
                "domains": domains or [],
            })

    if json_out:
        with open(json_out, "w") as f:
            json_mod.dump(records, f, indent=2, ensure_ascii=False)
        print(f"JSON output: {json_out} ({len(records)} records)")
    else:
        # Print to stdout as JSON
        print(json_mod.dumps(records, indent=2, ensure_ascii=False))

    # Print summary table with percentages
    clustered = sum(len(v) for v in buckets.values())
    print(f"\n{'='*70}")
    print(f"  SUMMARY")
    print(f"{'='*70}")
    CLUSTER_ORDER = [
        "JUNK", "SHOULD_I", "PROCEED", "CHOICE", "VALIDATE", "YES_NO",
        "OPEN", "CLARIFY", "OFFER", "COMMIT", "HOW", "WHEN_WHERE_WHY",
        "ACTION_ITEM", "MISC",
    ]
    for name in CLUSTER_ORDER:
        count = len(buckets.get(name, []))
        pct = count / len(questions) * 100 if questions else 0
        print(f"  {name:15s}  {count:4d}  ({pct:5.1f}%)")
    print(f"  {'UNCLUSTERED':15s}  {len(unclustered):4d}  ({len(unclustered)/len(questions)*100 if questions else 0:5.1f}%)")
    print(f"  {'─'*30}")
    print(f"  {'TOTAL':15s}  {len(questions):4d}")
