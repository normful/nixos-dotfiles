#!/usr/bin/env python3
"""
Query models.dev/api.json for pricing data on specified model IDs.

Outputs min/max/avg/mode pricing per million input tokens across all providers,
with $0 (free) entries excluded from aggregates.

Usage:
    curl -sL https://models.dev/api.json | python3 models_pricing.py
    python3 models_pricing.py < /path/to/api.json
"""

import json
import sys
from collections import Counter

SOURCE_URL = "https://models.dev/api.json"

# Each target maps to a set of model ID strings to match (exact + variant forms)
TARGET_MODEL_IDS: dict[str, list[str]] = {
    "minimax-m2.7": [
        "MiniMax-M2.7", "minimax-m2.7", "MiniMaxAI/MiniMax-M2.7",
        "minimax/minimax-m2.7", "accounts/fireworks/models/minimax-m2p7",
        "minimax.minimax-m2.7", "coding-minimax-m2.7", "minimax-m2-7",
        "minimax-m27", "route/minimax-m2.7", "minimaxai/minimax-m2.7",
        "MiniMax-M2.7-highspeed", "minimax-m2.7-highspeed",
        "minimax/minimax-m2.7-highspeed", "route/minimax-m2.7-highspeed",
        "coding-minimax-m2.7-highspeed", "coding-minimax-m2.7-free",
    ],
    "gpt-5.5": [
        "gpt-5.5", "gpt-5-5", "openai/gpt-5.5", "openai-gpt-5.5",
        "openai/gpt-5.5-pro", "gpt-5.5-pro", "databricks-gpt-5-5",
        "duo-chat-gpt-5-5",
    ],
    "gpt-5.4": [
        "gpt-5.4", "gpt-5-4", "openai/gpt-5.4", "openai-gpt-5.4",
        "openai/gpt-5.4-pro", "gpt-5.4-pro", "openai/gpt-5.4-image-2",
        "databricks-gpt-5-4", "duo-chat-gpt-5-4",
    ],
    "claude-opus-4.7": [
        "claude-opus-4.7", "claude-opus-4-7", "anthropic/claude-opus-4.7",
        "anthropic/claude-opus-4-7", "anthropic/claude-opus-4.7-fast",
        "claude-opus-4-7-fast", "claude-opus-4-7-think",
        "claude-opus-4-7@default", "anthropic-claude-opus-4.7",
        "databricks-claude-opus-4-7", "duo-chat-opus-4-7",
        "eu.anthropic.claude-opus-4-7", "global.anthropic.claude-opus-4-7",
        "us.anthropic.claude-opus-4-7", "jp.anthropic.claude-opus-4-7",
        "stealth/claude-opus-4.7", "anthropic.claude-opus-4-7",
    ],
    "claude-sonnet-4.6": [
        "claude-sonnet-4.6", "claude-sonnet-4-6",
        "anthropic/claude-sonnet-4.6", "anthropic/claude-sonnet-4-6",
        "anthropic/claude-sonnet-4.6:thinking", "claude-sonnet-4-6-think",
        "claude-sonnet-4-6-thinking", "claude-sonnet-4-6@default",
        "anthropic.claude-sonnet-4-6", "databricks-claude-sonnet-4-6",
        "duo-chat-sonnet-4-6", "eu.anthropic.claude-sonnet-4-6",
        "global.anthropic.claude-sonnet-4-6", "us.anthropic.claude-sonnet-4-6",
        "jp.anthropic.claude-sonnet-4-6", "stealth/claude-sonnet-4.6",
        "au.anthropic.claude-sonnet-4-6",
    ],
    "gemini-3.5-flash": [
        "gemini-3.5-flash", "gemini-3-5-flash", "google/gemini-3.5-flash",
    ],
    "claude-opus-4.6": [
        "claude-opus-4.6", "claude-opus-4-6", "anthropic/claude-opus-4.6",
        "anthropic/claude-opus-4-6", "anthropic/claude-opus-4.6-fast",
        "anthropic/claude-opus-4.6:thinking", "claude-opus-4-6-fast",
        "claude-opus-4-6-think", "claude-opus-4-6-thinking",
        "claude-opus-4-6@default", "anthropic-claude-opus-4.6",
        "databricks-claude-opus-4-6", "duo-chat-opus-4-6",
        "eu.anthropic.claude-opus-4-6-v1", "global.anthropic.claude-opus-4-6-v1",
        "us.anthropic.claude-opus-4-6-v1", "stealth/claude-opus-4.6",
        "anthropic.claude-opus-4-6-v1", "au.anthropic.claude-opus-4-6-v1",
    ],
    "gpt-5.4-mini": [
        "gpt-5.4-mini", "gpt-5-4-mini", "openai/gpt-5.4-mini",
        "openai-gpt-5.4-mini", "gpt-5.4-mini-2026-03-17",
        "databricks-gpt-5-4-mini", "duo-chat-gpt-5-4-mini",
    ],
    "kimi-k2.6": [
        "kimi-k2.6", "kimi-k2-6", "moonshotai/Kimi-K2.6", "Kimi-K2.6",
        "kimi/kimi-k2.6", "moonshotai/kimi-k2.6", "novita/kimi-k2.6",
        "route/kimi-k2.6", "umans-kimi-k2.6",
        "accounts/fireworks/models/kimi-k2p6",
        "accounts/fireworks/routers/kimi-k2p6-turbo",
        "workers-ai/@cf/moonshotai/kimi-k2.6", "@cf/moonshotai/kimi-k2.6",
        "moonshotai/Kimi-K2.6-TEE", "kimi-k2.6-fast", "kimi-k2.6-precision",
        "moonshotai/chat-completion/models/Kimi-K2_6",
        "moonshotai/kimi-k2.6:thinking", "route/kimi-k2.6-6bit",
        "hf:moonshotai/Kimi-K2.6",
    ],
    "mimo-v2.5-pro": [
        "mimo-v2.5-pro", "xiaomi-mimo-v2.5-pro", "xiaomi/mimo-v2.5-pro",
        "xiaomimimo/mimo-v2.5-pro", "coding-xiaomi-mimo-v2.5-pro",
        "route/mimo-v2.5-pro", "route/mimo-v2.5-pro-6bit",
        "xiaomi-mimo-v2.5-pro-free", "mimo-v2.5-pro-precision", "mimo-v2.5",
        "xiaomi-mimo-v2.5", "xiaomi/mimo-v2.5", "route/mimo-v2.5",
        "mimo-v2.5-free", "xiaomi-mimo-v2.5-free", "mimo-v2-pro",
        "mimo-v2-pro-free", "xiaomi/mimo-v2-pro",
    ],
    "deepseek-v4-flash": [
        "deepseek-v4-flash", "deepseek/deepseek-v4-flash",
        "deepseek-ai/deepseek-v4-flash", "deepseek-v4-flash-free",
        "deepseek/deepseek-v4-flash:free", "deepseek-ai/DeepSeek-V4-Flash",
        "alicloud-deepseek-v4-flash", "deep-deepseek-v4-flash",
        "accounts/fireworks/models/deepseek-v4-flash",
        "empiriolabs/deepseek-v4-flash-el", "route/deepseek-v4-flash",
        "route/deepseek-v4-flash-6bit",
    ],
    "glm-5.1": [
        "glm-5.1", "GLM-5.1", "zai-org/GLM-5.1", "zai/glm-5.1",
        "zai-org/glm-5.1", "zai-org/GLM-5.1-FP8", "zai-org/GLM-5.1-TEE",
        "zai-org/glm-5.1:thinking", "zai-glm-5.1", "zai-glm-5-1",
        "alicloud-glm-5.1", "coding-glm-5.1", "coding-glm-5.1-free",
        "glm-5.1-fast", "glm-5.1-precision", "route/glm-5.1",
        "route/glm-5.1-6bit", "umans-glm-5.1", "zai-org-glm-5-1",
        "hf:zai-org/GLM-5.1", "Pro/zai-org/GLM-5.1",
    ],
}


def _build_match_set(model_ids: list[str]) -> set[str]:
    """Build a set of normalized model ID strings for fast lookup."""
    matches: set[str] = set()
    for tid in model_ids:
        norm = tid.lower().replace("_", "-")
        matches.add(norm)
        for sep in (".", "-", ""):
            alt = tid.replace(".", sep).replace("-", sep).lower()
            matches.add(alt)
    return matches


def collect_pricing(data: dict) -> dict[str, list[tuple[str, str, float, float | None]]]:
    """Collect (provider_name, model_id, input_cost, output_cost) for each target."""
    results: dict[str, list[tuple[str, str, float, float | None]]] = {}

    for target_name, target_ids in TARGET_MODEL_IDS.items():
        target_results: list[tuple[str, str, float, float | None]] = []
        seen: set[tuple[str, str]] = set()
        match_set = _build_match_set(target_ids)

        for provider_key, provider_val in data.items():
            models_dict = provider_val.get("models", {})
            provider_name = provider_val.get("name", provider_key)
            for model_id, model_info in models_dict.items():
                norm = model_id.lower().replace("_", "-")
                if norm not in match_set:
                    continue
                dedup_key = (provider_name, model_id)
                if dedup_key in seen:
                    continue
                seen.add(dedup_key)
                cost = model_info.get("cost", {})
                input_cost = cost.get("input")
                output_cost = cost.get("output")
                if input_cost is not None:
                    target_results.append((provider_name, model_id, input_cost, output_cost))

        results[target_name] = target_results

    return results


def print_results(results: dict[str, list[tuple[str, str, float, float | None]]]) -> None:
    """Print formatted pricing summary."""
    for target in sorted(results.keys()):
        entries = results[target]
        print("")
        print("=== %s ===" % target)

        if not entries:
            print("  NO PRICING DATA FOUND")
            continue

        costs = [e[2] for e in entries]
        nonzero = [c for c in costs if c > 0]

        # Mode of rounded price points
        rounded = [round(c, 2) for c in costs]
        mode_counts = Counter(rounded)
        mode_val, mode_count = mode_counts.most_common(1)[0]

        print("  Providers (total): %d" % len(entries))
        if nonzero:
            avg = sum(nonzero) / len(nonzero)
            print("  Input $/M tok (excl. $0):  Min=$%.2f  Max=$%.2f  Avg=$%.2f  Mode=$%.2f (x%d)" % (
                min(nonzero), max(nonzero), avg, mode_val, mode_count))
        else:
            print("  Input $/M tok: All free ($0.00)")

        # Price point breakdown
        price_points: dict[float, list[str]] = {}
        for pname, mid, inp, out in entries:
            price_points.setdefault(round(inp, 2), []).append(pname)

        print("  Price points: %d" % len(price_points))
        for price in sorted(price_points):
            provs = sorted(set(price_points[price]))
            extra = ""
            if len(provs) > 5:
                extra = " ... (+%d more)" % (len(provs) - 5)
            tags = []
            if abs(price - mode_val) < 0.001:
                tags.append("MODE")
            if price == 0:
                tags.append("FREE")
            tag_str = " [%s]" % ", ".join(tags) if tags else ""
            print("    $%.2f%s: %s%s" % (price, tag_str, ", ".join(provs[:5]), extra))

        # Output pricing
        out_costs_ = [e[3] for e in entries if e[3] is not None]
        if out_costs_:
            nonzero_out = [c for c in out_costs_ if c > 0]
            if nonzero_out:
                avg_out = sum(nonzero_out) / len(nonzero_out)
                print("  Output $/M tok (excl. $0):  Min=$%.2f  Max=$%.2f  Avg=$%.2f" % (
                    min(nonzero_out), max(nonzero_out), avg_out))


def main() -> None:
    data = json.load(sys.stdin)
    results = collect_pricing(data)
    print_results(results)


if __name__ == "__main__":
    main()
