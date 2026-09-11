#!/usr/bin/env python3
"""
maintain.py — single script to maintain chezmoi/dot_config/tokscale/custom-pricing.json

Replaces 9 previous scripts (extract_model_ids.py, extract_provider_map.py,
build_custom_pricing.py, fix_cc_k26.py, add_big_pickle.py, add_solar.py,
backfill_cache_creation.py, validate_full.py, save_to_temp.py).

Does it all: fetch catalog, extract sessions, filter strict aihubmix, resolve
aliases, transform pricing (including cache_creation), add explicit free entries,
overwrite authoritative chezmoi file, and validate.

Usage:
  python3 scripts/maintain.py                 # full run, uses cached /tmp catalog if present
  python3 scripts/maintain.py --fetch         # force re-fetch aihubmix catalog
  python3 scripts/maintain.py --dry-run       # build to /tmp only, don't overwrite chezmoi
  python3 scripts/maintain.py --check         # validate current file vs catalog only
"""
import argparse
import json
import re
import pathlib
import collections
import subprocess
import sys
from pathlib import Path

# --- Config (Norman's preferences, confirmed via socrates 2026-08-21) ---
AUTHORITATIVE = Path.home() / "code/nixos-dotfiles/chezmoi/dot_config/tokscale/custom-pricing.json"
LIVE = Path.home() / ".config/tokscale/custom-pricing.json"
SESSIONS_DIR = Path.home() / ".pi/agent/sessions"
CATALOG_ALL = Path("/tmp/aihubmix_models_all.json")  # 856, full — authoritative
CATALOG_LLM = Path("/tmp/aihubmix_models.json")      # 398, reference only
MODELS_DEV = Path("/tmp/models_dev.json")           # models.dev per-provider costs (non-aihubmix)
PROVIDER_MAP_TMP = Path("/tmp/provider_map.json")
UNIQUE_IDS_TMP = Path("/tmp/unique_model_ids.json")

ALIAS_MAP = {
    "alicloud-deepseek-v4-flash-0731": "deepseek-v4-flash-0731",
    "baidu-deepseek-v4-flash-0731": "deepseek-v4-flash-0731",
    "deep-deepseek-v4-flash": "deepseek-v4-flash-0731",
    "deep-deepseek-v4-flash-0731": "deepseek-v4-flash-0731",
    "deepinfra-deepseek-v4-flash-0731": "deepseek-v4-flash-0731",
    "fireworks-deepseek-v4-flash-0731": "deepseek-v4-flash-0731",
    "fireworks-deepseek-v4-pro": "deepseek-v4-pro-0813",
    "deepseek-v4-flash-think": "deepseek-v4-flash-0731",
    "tencent-hy3": "hy3",
    "xiaomi-mimo-v2.5": "mimo-v2.5",  # catalog renamed (prices match 0.155/0.31/0.0031 exactly)
    "xiaomi-mimo-v2.5-pro": "mimo-v2.5-pro",  # catalog renamed (prices match 0.48/0.96/0.00384 exactly)
    "cc-k2.6-code-preview": "cc-k2.6-code-preview",  # 0.2/0.2/0.02 via full catalog, not kimi-k2.6
    "gemini-3.1-flash-lite-preview": "gemini-3.1-flash-lite",
    "crush-glm-5-turbo": None,         # skip, Norman: ignore
    "crush-glm-5-turbo-free": None,
    "crush-glm-5.1-free": None,
    "cheap": None,
    "@preset/glm47": None,             # skip, openrouter preset alias: unknown mapping
}
# Explicit session-ID -> models.dev (provider, key) lookups for non-aihubmix
# models tokscale can't resolve (verified 2026-09-05 via `tokscale pricing --provider`).
# Values are per-1M-token USD from models.dev.
MODELS_DEV_MAP = {
    # cerebras (models.dev [cerebras] / litellm fallback)
    "gpt-oss-120b": ("cerebras", "gpt-oss-120b"),  # 0.35/0.75
    "qwen-3-235b-a22b-instruct-2507": ("litellm", "vercel_ai_gateway/alibaba/qwen-3-235b"),  # 0.2/0.6
    "zai-glm-4.7": ("litellm", "cerebras/zai-glm-4.7"),  # 2.25/2.75
    # openrouter (models.dev [openrouter]/[zenmux], provider's own price)
    "x-ai/grok-code-fast-1": ("zenmux", "x-ai/grok-code-fast-1"),  # 0.2/1.5/0.02
    "google/gemini-3.7-flash": ("openrouter", "google/gemini-3.7-flash"),  # 0.75/3.75/0.075+w0.041667
    "minimax/minimax-m3": ("openrouter", "minimax/minimax-m3"),  # 0.3/1.2/0.06
    "z-ai/glm-4.7": ("openrouter", "z-ai/glm-4.7"),  # 0.4/1.75/0.08
    "upstage/solar-pro4": ("openrouter", "upstage/solar-pro4"),  # 0.03/0.12/0.006
}
# models.dev costs keyed inline for sources without a JSON section (litellm-only).
# Format mirrors models.dev cost dicts.
LITELLM_COSTS = {
    "vercel_ai_gateway/alibaba/qwen-3-235b": {"input": 0.2, "output": 0.6},
    "cerebras/zai-glm-4.7": {"input": 2.25, "output": 2.75},
}
FREE_ADDITIONS = ["big-pickle", "solar-pro4:free"]  # explicit free 0/0/0, not in catalog
# Session IDs that are always free regardless of provider resolution.
FREE_IDS = {"upstage/solar-pro4:free"}
# Any used ID ending in ":free" is an explicit 0/0/0 (free-tier endpoint).
# Docs-grounded: explicit 0 declares a free model; omitted fields mean unknown.
# OpenRouter confirms e.g. poolside/laguna-s-2.1:free at 0/0.
FREE_SUFFIX = ":free"
# Exact model-half keys for `tokscale submit` warnings, priced from the
# provider Norman actually pays. Key = the `model` half of the submit
# warning's provider/model pair (slashes included — exact-only match, so
# "minimax-m3" does NOT cover "MiniMaxAI/MiniMax-M3", and one key covers
# every provider/client using that model half, e.g. hermes+nous+openrouter
# sharing "poolside/laguna-s-2.1:free").
# Format: key -> dict(input, output, cache_read?, cache_write?, source).
# Verified 2026-09-05 (see SKILL.md third-run section for sources).
PINNED_RATES = {
    "minimax-m2.7": {"input": 0.3, "output": 1.2, "cache_read": 0.06, "cache_write": 0,
                     "source": "pi models.json opencode-go cost block + OpenRouter minimax/minimax-m2.7"},
    "inclusionai/ling-3.0-flash": {"input": 0.021, "output": 0.063, "cache_read": 0.0042,
                                   "source": "OpenRouter API + models.dev [openrouter]"},
    "MiniMaxAI/MiniMax-M3": {"input": 0.3, "output": 1.2, "cache_read": 0.06,
                             "source": "siliconflow.com/pricing row MiniMax-M3 0.3/0.06/1.2"},
    "deepseek-ai/DeepSeek-V4-Flash": {"input": 0.14, "output": 0.28, "cache_read": 0.028,
                                      "source": "models.dev [siliconflow]"},
    "kwaipilot/kat-coder-air-v2.5": {"input": 0.15, "output": 0.6, "cache_read": 0.03,
                                     "source": "openrouter.ai/kwaipilot/kat-coder-air-v2.5 + pricepertoken"},
    # Norman 2026-09-05: include (paid endpoint, no :free suffix). haimaker
    # 0.10/0.20 chosen over Requesty's "free upstream" (that's their router's
    # upstream rate, not OpenRouter's bill). Flip to 0 if invoice says free.
    "poolside/laguna-xs.2": {"input": 0.1, "output": 0.2,
                             "source": "haimaker.ai + designforonline from-$0.10 (unverified, Norman default)"},
}
# Submit-warning model halves with NO entry (intentional, documented in SKILL.md):
#   @preset/glm47, @preset/glm47-flash-fast, @preset/kimi25-high-reasoning
#     -> router/preset labels, unknown rate (accepted loss, @preset/glm47 precedent)


def zero_rates() -> dict:
    return {
        "input_cost_per_million_tokens": 0,
        "output_cost_per_million_tokens": 0,
        "cache_read_input_token_cost_per_million_tokens": 0,
    }

def fetch_catalog(force=False):
    if CATALOG_ALL.exists() and not force:
        print(f"[fetch] using cached {CATALOG_ALL} ({CATALOG_ALL.stat().st_size} bytes)")
    else:
        print(f"[fetch] curl https://aihubmix.com/api/v1/models -> {CATALOG_ALL}")
        subprocess.run(["curl", "-s", "https://aihubmix.com/api/v1/models", "-o", str(CATALOG_ALL)], check=True)
    # also fetch llm filtered for reference/drift detection
    if CATALOG_LLM.exists() and not force:
        print(f"[fetch] using cached {CATALOG_LLM}")
    else:
        print(f"[fetch] curl https://aihubmix.com/api/v1/models?type=llm -> {CATALOG_LLM}")
        subprocess.run(["curl", "-s", "https://aihubmix.com/api/v1/models?type=llm", "-o", str(CATALOG_LLM)], check=True)
    for p in (CATALOG_ALL, CATALOG_LLM):
        data = json.loads(p.read_text())
        print(f"  {p.name}: {len(data['data'])} models")

def extract_sessions():
    """Extract unique modelIds and provider map directly from sessions (1M lines)."""
    if not SESSIONS_DIR.exists():
        print(f"Sessions dir not found: {SESSIONS_DIR}", file=sys.stderr)
        sys.exit(1)
    jsonl_files = list(SESSIONS_DIR.rglob("*.jsonl"))
    print(f"[extract] {len(jsonl_files)} jsonl files under {SESSIONS_DIR}")
    model_id_re = re.compile(r'"modelId"\s*:\s*"([^"]+)"')
    unique_ids = set()
    counter = collections.Counter()
    id_to_providers = collections.defaultdict(set)
    provider_to_ids = collections.defaultdict(set)
    total_lines = 0
    for idx, fpath in enumerate(jsonl_files, 1):
        if idx % 500 == 0:
            print(f"  [{idx}/{len(jsonl_files)}] unique so far: {len(unique_ids)}")
        try:
            with fpath.open("r", encoding="utf-8", errors="ignore") as fh:
                for line in fh:
                    total_lines += 1
                    if '"modelId"' not in line:
                        continue
                    try:
                        obj = json.loads(line)
                        if obj.get("type") == "model_change" and "modelId" in obj:
                            mid = obj["modelId"]
                            prov = obj.get("provider", "?")
                            unique_ids.add(mid)
                            counter[(prov, mid)] += 1
                            id_to_providers[mid].add(prov)
                            provider_to_ids[prov].add(mid)
                            continue
                    except json.JSONDecodeError:
                        pass
                    m = model_id_re.search(line)
                    if m:
                        mid = m.group(1)
                        unique_ids.add(mid)
                        counter[mid] += 1
        except Exception as e:
            print(f"Error reading {fpath}: {e}", file=sys.stderr)
    sorted_ids = sorted(unique_ids)
    print(f"[extract] total lines {total_lines}, unique {len(sorted_ids)}, combos {len(counter)}")
    # Persist for inspection / skill reuse
    UNIQUE_IDS_TMP.write_text(json.dumps(sorted_ids, indent=2))
    PROVIDER_MAP_TMP.write_text(json.dumps({k: list(v) for k, v in id_to_providers.items()}, indent=2))
    counter_dump = {}
    for k, c in counter.most_common():
        if isinstance(k, tuple) and len(k) == 2:
            p, m = k
            counter_dump[f"{p}::{m}"] = c
        else:
            counter_dump[str(k)] = c
    Path("/tmp/provider_counter.json").write_text(json.dumps(counter_dump, indent=2))
    print(f"  wrote {UNIQUE_IDS_TMP} ({len(sorted_ids)}) and {PROVIDER_MAP_TMP}")
    return sorted_ids, {k: set(v) for k, v in id_to_providers.items()}

def resolve_catalog_id(session_id: str):
    if session_id in ALIAS_MAP:
        return ALIAS_MAP[session_id]
    if "-deepseek-v4-flash" in session_id:
        return "deepseek-v4-flash-0731"
    return session_id

def to_tokscale(pricing: dict) -> dict:
    out = {}
    if "input" in pricing:
        out["input_cost_per_million_tokens"] = pricing["input"]
    if "output" in pricing:
        out["output_cost_per_million_tokens"] = pricing["output"]
    if "cache_read" in pricing:
        out["cache_read_input_token_cost_per_million_tokens"] = pricing["cache_read"]
    if "cache_write" in pricing:
        out["cache_creation_input_token_cost_per_million_tokens"] = pricing["cache_write"]
    return out


def load_models_dev_costs():
    """Load models.dev per-provider costs: {(provider, model_key) -> cost dict}."""
    if not MODELS_DEV.exists():
        return {}
    dev = json.loads(MODELS_DEV.read_text())
    costs = {}
    for provider, pdata in dev.items():
        if not isinstance(pdata, dict):
            continue
        for key, m in (pdata.get("models") or {}).items():
            if isinstance(m, dict) and m.get("cost"):
                costs[(provider, key)] = m["cost"]
    return costs


def models_dev_to_tokscale(cost: dict) -> dict:
    """Map models.dev cost {input,output,cache_read,cache_write} to tokscale fields."""
    return to_tokscale({
        k: v for k, v in {
            "input": cost.get("input"),
            "output": cost.get("output"),
            "cache_read": cost.get("cache_read", cost.get("cacheRead")),
            "cache_write": cost.get("cache_write", cost.get("cacheWrite")),
        }.items() if v is not None
    })


BUCKETS_TMP = Path("/tmp/session_buckets.json")

# tokscale entry field per session token bucket
BUCKET_FIELDS = {
    "cacheRead": "cache_read_input_token_cost_per_million_tokens",
    "cacheWrite": "cache_creation_input_token_cost_per_million_tokens",
}


def load_session_buckets():
    """Per-model populated token buckets from cached `tokscale models --json` scan.

    Regenerate with: tokscale models --json > /tmp/tokscale_models.json
    (takes ~1 min). Falls back to {} when the cache is absent.
    """
    cache = Path("/tmp/tokscale_models.json")
    if not cache.exists():
        print("[buckets] no /tmp/tokscale_models.json, skipping bucket backfill")
        return {}
    d = json.loads(cache.read_text())
    buckets = {}
    for e in d.get("entries", []):
        populated = {b for b in BUCKET_FIELDS if e.get(b)}
        if populated:
            buckets.setdefault(e["model"], set()).update(populated)
    BUCKETS_TMP.write_text(json.dumps({k: sorted(v) for k, v in buckets.items()}, indent=2))
    print(f"[buckets] {len(buckets)} models with cache buckets from {cache}")
    return buckets


def backfill_buckets(entry: dict, populated: set) -> dict:
    """Add explicit 0 rates for populated buckets the catalog has no price for.

    tokscale submit excludes messages when pricing lacks a rate for a populated
    token bucket; the local report already prices those buckets at $0, so this
    makes submit consistent with local (verified: cc-minimax-m2.7-highspeed
    $8.21 both ways). 0 = unknown/unpublished rate, not free tier.
    """
    for bucket in populated:
        field = BUCKET_FIELDS[bucket]
        if field not in entry:
            entry[field] = 0
    return entry

def build(dry_run=False):
    # Ensure we have data
    if not UNIQUE_IDS_TMP.exists() or not PROVIDER_MAP_TMP.exists():
        print("[build] provider_map or unique_ids missing, extracting sessions...")
        used_ids, id_to_providers = extract_sessions()
    else:
        used_ids = json.loads(UNIQUE_IDS_TMP.read_text())
        raw = json.loads(PROVIDER_MAP_TMP.read_text())
        id_to_providers = {k: set(v) for k, v in raw.items()}
        print(f"[build] loaded {len(used_ids)} used, {len(id_to_providers)} provider mappings from tmp")

    strict_ids = [mid for mid in used_ids if any("aihubmix" in p for p in id_to_providers.get(mid, []))]
    print(f"[build] strict aihubmix used: {len(strict_ids)} / {len(used_ids)} total")

    catalog = json.loads(CATALOG_ALL.read_text())
    catalog_map = {m["model_id"]: m["pricing"] for m in catalog["data"]}
    print(f"[build] full catalog {len(catalog_map)} models")

    llm_map = {}
    if CATALOG_LLM.exists():
        llm = json.loads(CATALOG_LLM.read_text())
        llm_map = {m["model_id"]: m["pricing"] for m in llm["data"]}

    dev_costs = load_models_dev_costs()
    print(f"[build] models.dev costs {len(dev_costs)} entries")

    # Session token buckets per model (from cached tokscale scan): messages
    # are excluded at submit when pricing lacks a rate for a populated bucket.
    buckets = load_session_buckets()

    new_models = {}
    skipped = []
    missing = []
    for sid in sorted(strict_ids):
        cid = resolve_catalog_id(sid)
        if cid is None:
            skipped.append(sid)
            continue
        pricing = catalog_map.get(cid)
        if pricing is None:
            missing.append((sid, cid))
            continue
        if cid in llm_map and llm_map[cid] != pricing:
            print(f"  drift {cid}: llm {llm_map[cid]} vs full {pricing} (using full)")
        new_models[sid] = backfill_buckets(to_tokscale(pricing), buckets.get(sid, set()))

    # Non-aihubmix session IDs tokscale can't resolve itself (models.dev prices).
    dev_ids = [mid for mid in used_ids if mid in MODELS_DEV_MAP and mid not in new_models]
    print(f"[build] models.dev-mapped non-aihubmix used: {len(dev_ids)}")
    for sid in sorted(dev_ids):
        provider, key = MODELS_DEV_MAP[sid]
        cost = dev_costs.get((provider, key), LITELLM_COSTS.get(key))
        if cost is None:
            missing.append((sid, f"{provider}:{key}"))
            continue
        new_models[sid] = backfill_buckets(models_dev_to_tokscale(cost), buckets.get(sid, set()))

    # Exact model-half keys for tokscale submit warnings (any provider/client).
    pinned_ids = [mid for mid in used_ids if mid in PINNED_RATES and mid not in new_models]
    print(f"[build] pinned submit-warning keys used: {len(pinned_ids)}")
    for sid in sorted(pinned_ids):
        rate = PINNED_RATES[sid]
        new_models[sid] = backfill_buckets(models_dev_to_tokscale(rate), buckets.get(sid, set()))

    # Generic free-tier rule: any used ID ending in ":free" is explicit 0/0/0.
    free_ids = [mid for mid in used_ids if mid.endswith(FREE_SUFFIX) and mid not in new_models]
    print(f"[build] free-suffix used: {len(free_ids)}")
    for sid in sorted(free_ids):
        new_models[sid] = backfill_buckets(zero_rates(), buckets.get(sid, set()))

    print(f"[build] built {len(new_models)} strict, skipped {len(skipped)} {skipped}, missing {len(missing)} {missing}")

    for fid in FREE_ADDITIONS + sorted(FREE_IDS):
        if fid not in new_models:
            new_models[fid] = zero_rates()
            print(f"[build] added free {fid}")

    final = {
        "$schema": "https://tokscale.ai/custom-pricing.schema.json",
        "models": dict(sorted(new_models.items())),
    }
    print(f"[build] final {len(final['models'])} models, {sum(1 for v in final['models'].values() if 'cache_creation_input_token_cost_per_million_tokens' in v)} with cache_creation")

    if dry_run:
        out = Path("/tmp/custom-pricing.new.json")
        out.write_text(json.dumps(final, indent=2))
        print(f"[dry-run] wrote {out} (not overwriting authoritative)")
        return final

    AUTHORITATIVE.parent.mkdir(parents=True, exist_ok=True)
    AUTHORITATIVE.write_text(json.dumps(final, indent=2))
    print(f"[write] authoritative {AUTHORITATIVE} ({len(final['models'])})")

    # Sync live
    if LIVE != AUTHORITATIVE:
        LIVE.parent.mkdir(parents=True, exist_ok=True)
        LIVE.write_text(json.dumps(final, indent=2))
        print(f"[write] synced live {LIVE}")

    Path("/tmp/custom-pricing.new.json").write_text(json.dumps(final, indent=2))
    print("[write] also /tmp/custom-pricing.new.json")

    # Validate
    for p in (AUTHORITATIVE, LIVE):
        subprocess.run(["jq", ".", str(p)], check=False)
    print("[done] changes left uncommitted for Norman to review/commit — skill runs never commit (see SKILL.md Commit policy)")
    return final

def check():
    """Validate current authoritative file vs full catalog + models.dev map."""
    if not AUTHORITATIVE.exists():
        print(f"Missing {AUTHORITATIVE}")
        sys.exit(1)
    custom = json.loads(AUTHORITATIVE.read_text())
    catalog = json.loads(CATALOG_ALL.read_text())
    full_map = {m["model_id"]: m["pricing"] for m in catalog["data"]}
    dev_costs = load_models_dev_costs()
    buckets = load_session_buckets()
    ok = 0
    bad = []
    for sid, vals in custom["models"].items():
        # Explicit free additions (not in catalog) — Norman requested 0/0/0.
        # Any ":free"-suffixed key follows the same rule via FREE_SUFFIX.
        if sid in FREE_ADDITIONS or sid in FREE_IDS or sid.endswith(FREE_SUFFIX):
            if vals.get("input_cost_per_million_tokens") == 0 and vals.get("output_cost_per_million_tokens") == 0:
                ok += 1
            else:
                bad.append((sid, "expected free 0"))
            continue
        if sid in PINNED_RATES:
            exp = backfill_buckets(models_dev_to_tokscale(PINNED_RATES[sid]), buckets.get(sid, set()))
        elif sid in MODELS_DEV_MAP:
            provider, key = MODELS_DEV_MAP[sid]
            cost = dev_costs.get((provider, key), LITELLM_COSTS.get(key))
            exp = backfill_buckets(models_dev_to_tokscale(cost), buckets.get(sid, set())) if cost else None
        else:
            cid = resolve_catalog_id(sid)
            if cid is None:
                # skipped cheap/crush etc. should not be in file; if present, expect 0
                if vals.get("input_cost_per_million_tokens") == 0:
                    ok += 1
                else:
                    bad.append((sid, "expected free 0"))
                continue
            exp = backfill_buckets(to_tokscale(full_map[cid]), buckets.get(sid, set())) if cid in full_map else None
        if exp is None:
            bad.append((sid, "missing catalog", vals, None))
        elif vals != exp:
            bad.append((sid, "mismatch", vals, exp))
        else:
            ok += 1
    print(f"[check] {ok} OK, {len(bad)} bad out of {len(custom['models'])}")
    for b in bad:
        print(f"  BAD {b}")
    if bad:
        sys.exit(1)
    print("[check] all good")

def main():
    ap = argparse.ArgumentParser(description="Maintain tokscale custom pricing (single script)")
    ap.add_argument("--fetch", action="store_true", help="force re-fetch aihubmix catalog")
    ap.add_argument("--dry-run", action="store_true", help="build to /tmp only, don't overwrite")
    ap.add_argument("--check", action="store_true", help="validate current file only")
    ap.add_argument("--extract", action="store_true", help="force re-extract sessions (otherwise use cached /tmp)")
    args = ap.parse_args()

    if args.check:
        fetch_catalog(force=args.fetch)
        check()
        return

    fetch_catalog(force=args.fetch)
    if args.extract or not UNIQUE_IDS_TMP.exists():
        extract_sessions()
    build(dry_run=args.dry_run)
    if not args.dry_run:
        check()

if __name__ == "__main__":
    main()
