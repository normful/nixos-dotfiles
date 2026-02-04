#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///

"""
Generate models.json and pi.fish from a single models-config.toml using
live metadata from https://models.dev/api.json.

TOML Format:

    [providers.openrouter]
    models = ["stepfun/step-3.5-flash:free", "deepseek/deepseek-v3.2-speciale"]

    # Optional: Override specific model attributes using [providers.openrouter.model."model-id"]
    [providers.openrouter.model."deepseek/deepseek-v3.2-speciale"]
    name = "DeepSeek V3.2"
    reasoning = true
    contextWindow = 500000
    cost = { input = 0.5, output = 2.0 }
    compat = { thinkingFormat = "qwen" }

Run with:
    uv run src-py/generate-pi-config-and-fish-pi-alias.py
"""

import json
import ssl
import sys
import tomllib
import urllib.request
from pathlib import Path
from typing import Dict, List, Tuple, Any, TypedDict, Optional

# ========================
# Configuration
# ========================

SCRIPT_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPT_DIR / "models-config.toml"
PI_CODING_AGENT_MODELS_JSON_PATH = (
    Path(__file__).resolve().parents[1] / "chezmoi" / "dot_pi" / "agent" / "models.json"
)
PI_FISH_PATH = (
    Path(__file__).resolve().parents[1]
    / "chezmoi"
    / "dot_config"
    / "fish"
    / "abbreviations"
    / "pi.fish"
)

MODELS_DOT_DEV_API = "https://models.dev/api.json"
MAX_LEVENSHTEIN_DISTANCE = 3

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# ONLY these providers will be added to models.json and pi.fish
PROVIDERS_TO_ADD_TO_PI_CODING_AGENT_MODELS_JSON = ["aihubmix"]

# Fallback base URLs for providers where the API returns empty
DEFAULT_BASE_URLS = {
    "cerebras": "https://api.cerebras.ai/v1",
    "google": "https://generativelanguage.googleapis.com/v1beta",
}

# ========================
# Types
# ========================


class ProviderMeta(TypedDict):
    baseUrl: str
    api: str
    apiKey: str
    authHeader: bool


LowerModelMap = Dict[str, Tuple[Dict[str, Any], str]]
FlatModel = Tuple[
    str, Dict[str, Any], str, str
]  # (provider, model_data, original_id, lower_id)

# Model override keys that can be specified in TOML
MODEL_OVERRIDE_KEYS = {
    "name",
    "reasoning",
    "input",
    "cost",
    "contextWindow",
    "maxTokens",
}

# OpenAI compat keys that can be specified in TOML
COMPAT_OVERRIDE_KEYS = {
    "supportsStore",
    "supportsDeveloperRole",
    "supportsReasoningEffort",
    "supportsUsageInStreaming",
    "maxTokensField",
    "requiresToolResultName",
    "requiresAssistantAfterToolResult",
    "requiresThinkingAsText",
    "requiresMistralToolIds",
    "thinkingFormat",
}

# ========================
# Helpers
# ========================


def infer_api_type(npm_package: str) -> str:
    """Map npm package name to one of the supported API types."""
    npm = npm_package.lower()
    if "anthropic" in npm:
        return "anthropic-messages"
    if "google" in npm or "genai" in npm:
        return "google-generative-ai"
    if "openai" in npm:
        return "openai-completions"
    return "openai-completions"


def levenshtein(s1: str, s2: str) -> int:
    """Compute Levenshtein distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein(s2, s1)
    if len(s2) == 0:
        return len(s1)
    previous_row = list(range(len(s2) + 1))
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    return previous_row[-1]


def warning(msg: str) -> None:
    """Print a warning to stderr (yellow if supported)."""
    if sys.stderr.isatty():
        print(f"\033[33mWarning: {msg}\033[0m", file=sys.stderr)
    else:
        print(f"Warning: {msg}", file=sys.stderr)


def success(msg: str) -> None:
    """Print a success message (green if supported)."""
    if sys.stdout.isatty():
        print(f"\033[32m{msg}\033[0m")
    else:
        print(msg)


# ========================
# Core Functions
# ========================


def load_config() -> dict:
    """Load and return the TOML configuration."""
    try:
        with open(CONFIG_PATH, "rb") as f:
            return tomllib.load(f)
    except FileNotFoundError:
        print(f"Error: Config file not found at {CONFIG_PATH}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error loading config: {e}", file=sys.stderr)
        sys.exit(1)


def fetch_models_api() -> dict:
    """Fetch the models.dev API JSON."""
    try:
        context = ssl._create_unverified_context()
        req = urllib.request.Request(
            MODELS_DOT_DEV_API, headers={"User-Agent": USER_AGENT}
        )
        with urllib.request.urlopen(req, context=context) as response:
            return json.load(response)
    except Exception as e:
        print(f"Error fetching API: {e}", file=sys.stderr)
        sys.exit(1)


def index_providers(
    api_data: dict,
) -> Tuple[Dict[str, ProviderMeta], Dict[str, LowerModelMap], List[FlatModel]]:
    """Build indexes for provider metadata and model lookup."""
    provider_meta: Dict[str, ProviderMeta] = {}
    provider_lower_models: Dict[str, LowerModelMap] = {}
    all_models_flat: List[FlatModel] = []

    for prov_key, prov_data in api_data.items():
        base_url = prov_data.get("api", "")
        # Use fallback if base_url is empty and we have a default
        if not base_url and prov_key in DEFAULT_BASE_URLS:
            base_url = DEFAULT_BASE_URLS[prov_key]
        npm = prov_data.get("npm", "")
        api_type = infer_api_type(npm)
        env_list = prov_data.get("env", [])
        api_key = env_list[0] if env_list else f"{prov_key.upper()}_API_KEY"

        provider_meta[prov_key] = {
            "baseUrl": base_url,
            "api": api_type,
            "apiKey": api_key,
            "authHeader": True,
        }

        models_dict = prov_data.get("models", {})
        lower_map: LowerModelMap = {}
        for mid, mdata in models_dict.items():
            mid_lower = mid.lower()
            lower_map[mid_lower] = (mdata, mid)
            all_models_flat.append((prov_key, mdata, mid, mid_lower))
        provider_lower_models[prov_key] = lower_map

    return provider_meta, provider_lower_models, all_models_flat


def match_model(
    model_id: str,
    target_provider: str,
    provider_lower_models: Dict[str, LowerModelMap],
    all_models_flat: List[FlatModel],
    all_provider_keys_sorted: List[str],
    max_distance: int,
) -> Optional[Tuple[str, Dict[str, Any], str]]:
    """
    Find the best match for model_id across providers.
    Returns (matched_provider, matched_model_data, original_model_id) or None.
    Search order:
      1. Exact case-insensitive in target_provider
      2. Exact case-insensitive in any other provider
      3. Fuzzy match (Levenshtein) across all providers
    """
    model_id_lower = model_id.lower()
    # 1. Own provider exact match
    own_map = provider_lower_models[target_provider]
    if model_id_lower in own_map:
        return (target_provider, *own_map[model_id_lower])

    # 2. Other providers exact match
    for other_prov in all_provider_keys_sorted:
        if other_prov == target_provider:
            continue
        other_map = provider_lower_models[other_prov]
        if model_id_lower in other_map:
            return (other_prov, *other_map[model_id_lower])

    # 3. Fuzzy match
    best_dist: int | None = None
    best_match: Optional[Tuple[str, Dict[str, Any], str]] = None
    for prov, mdata, orig_id, mid_lower in all_models_flat:
        dist = levenshtein(model_id_lower, mid_lower)
        if best_dist is None or dist < best_dist:
            best_dist = dist
            best_match = (prov, mdata, orig_id)
    if best_dist is not None and best_dist <= max_distance:
        return best_match

    return None


def transform_model(
    model_id: str, api_model: dict, overrides: dict | None = None
) -> dict:
    """Convert raw API model into the models.json entry format.

    Args:
        model_id: The model ID from config
        api_model: Raw model data from models.dev API
        overrides: Optional dict of override values from TOML config
    """
    overrides = overrides or {}

    # Apply overrides (they take precedence over API data)
    name = overrides.get("name") or api_model.get("name", model_id)
    reasoning = overrides.get("reasoning", api_model.get("reasoning", True))

    # Handle input modalities - prefer override, fall back to API, then default
    if "input" in overrides:
        input_types = overrides["input"]
    else:
        modalities = api_model.get("modalities", {})
        input_types = modalities.get("input", [])
    filtered_input = [t for t in input_types if t in ("text", "image")]
    if not filtered_input:
        filtered_input = ["text"]

    # Handle cost - override cost object or individual fields
    if "cost" in overrides:
        cost_dict = overrides["cost"]
    else:
        cost_dict = api_model.get("cost", {})
    cost_input = cost_dict.get("input", 0) if isinstance(cost_dict, dict) else 0
    cost_output = cost_dict.get("output", 0) if isinstance(cost_dict, dict) else 0
    cost_cache_read = (
        cost_dict.get("cacheRead", 0) if isinstance(cost_dict, dict) else 0
    )
    cost_cache_write = (
        cost_dict.get("cacheWrite", 0) if isinstance(cost_dict, dict) else 0
    )

    # Handle limits - prefer override, fall back to API
    if "contextWindow" in overrides:
        context_window = overrides["contextWindow"]
    elif "limit" in api_model:
        context_window = api_model["limit"].get("context", 0)
    else:
        context_window = 0

    if "maxTokens" in overrides:
        max_tokens = overrides["maxTokens"]
    elif "limit" in api_model:
        max_tokens = api_model["limit"].get("output", 0)
    else:
        max_tokens = 0

    # Build output dict
    output: Dict[str, Any] = {
        "id": model_id,
        "name": name,
        "reasoning": reasoning,
        "input": filtered_input,
        "cost": {
            "input": cost_input,
            "output": cost_output,
            "cacheRead": cost_cache_read,
            "cacheWrite": cost_cache_write,
        },
        "contextWindow": context_window,
        "maxTokens": max_tokens,
    }

    # Handle compat object - check for compat keys in overrides
    # compat keys: supportsStore, supportsDeveloperRole, supportsReasoningEffort,
    # supportsUsageInStreaming, maxTokensField, requiresToolResultName,
    # requiresAssistantAfterToolResult, requiresThinkingAsText,
    # requiresMistralToolIds, thinkingFormat
    compat: Dict[str, Any] = {}

    # Check for direct compat keys (e.g., supportsDeveloperRole = true)
    direct_compat_keys = overrides.keys() & COMPAT_OVERRIDE_KEYS
    for key in direct_compat_keys:
        compat[key] = overrides[key]

    # Also check for nested compat = { ... } dict in overrides
    if "compat" in overrides and isinstance(overrides["compat"], dict):
        nested_compat = overrides["compat"]
        for key in COMPAT_OVERRIDE_KEYS:
            if key in nested_compat and key not in compat:
                compat[key] = nested_compat[key]

    # Fall back to API data if not in overrides
    if compat:
        api_compat = api_model.get("compat", {})
        for key in COMPAT_OVERRIDE_KEYS:
            if key not in compat and key in api_compat:
                compat[key] = api_compat[key]
        output["compat"] = compat

    return output


def generate_outputs(
    config_providers: dict,
    provider_meta: Dict[str, ProviderMeta],
    provider_lower_models: Dict[str, LowerModelMap],
    all_models_flat: List[FlatModel],
    all_provider_keys_sorted: List[str],
    max_distance: int,
) -> Tuple[Dict[str, Any], List[Tuple[str, str]]]:
    """
    Process config providers and models.
    Returns (output_providers dict, pi_models_order list).
    Prints warnings for any models that cannot be matched.

    TOML format:
      [providers.x]
      models = ["model-a", "model-b"]

      [providers.x.model."model-a"]
      name = "Custom Name"
      cost = { input = 0.5 }

      [providers.x.model."model-b"]
      compat = { thinkingFormat = "qwen" }
    """
    output_providers: Dict[str, Any] = {}
    pi_models_order: List[Tuple[str, str]] = []

    for prov_name in config_providers.keys():
        if prov_name not in provider_meta:
            print(
                f"Error: Provider '{prov_name}' not found in API response.",
                file=sys.stderr,
            )
            sys.exit(1)

        meta = provider_meta[prov_name]
        prov_config = config_providers[prov_name]

        # Get model list (must be an array)
        model_list_raw = prov_config.get("models")
        if isinstance(model_list_raw, list):
            model_list_config = model_list_raw
        else:
            warning(f"Provider '{prov_name}' has non-array models field, skipping")
            continue

        # Get model overrides from separate [providers.x.model."y"] sections
        model_overrides = prov_config.get("model", {})

        output_models: List[Dict[str, Any]] = []

        for model_id in model_list_config:
            # Get any overrides for this specific model
            overrides = model_overrides.get(model_id, {})

            match = match_model(
                model_id=model_id,
                target_provider=prov_name,
                provider_lower_models=provider_lower_models,
                all_models_flat=all_models_flat,
                all_provider_keys_sorted=all_provider_keys_sorted,
                max_distance=max_distance,
            )
            if match is None:
                warning(
                    f"Could not find model '{model_id}' for provider '{prov_name}' in API (exact or fuzzy within distance {max_distance}). Skipping."
                )
                continue

            matched_prov, matched_mdata, matched_original_id = match
            final_model = transform_model(model_id, matched_mdata, overrides)

            # Only add to output_providers if it's in the allowed list
            if prov_name in PROVIDERS_TO_ADD_TO_PI_CODING_AGENT_MODELS_JSON:
                output_models.append(final_model)

            # Always add to pi_models_order for pi.fish
            pi_models_order.append((prov_name, model_id))

        if prov_name in PROVIDERS_TO_ADD_TO_PI_CODING_AGENT_MODELS_JSON:
            output_providers[prov_name] = {**meta, "models": output_models}

    return output_providers, pi_models_order


def write_json(data: Any, path: Path) -> None:
    """Write data as pretty JSON (2-space indent)."""
    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Error writing {path.name}: {e}", file=sys.stderr)
        sys.exit(1)


def write_pi_fish(models: List[Tuple[str, str]], path: Path) -> None:
    """Write fish abbreviation file with one model per line."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write(
                'abbr --add pi "bunx @mariozechner/pi-coding-agent --models \'"\\\n'
            )
            total = len(models)
            for idx, (prov, model_id) in enumerate(models):
                is_last = idx == total - 1
                if is_last:
                    f.write(f'"{prov}/{model_id}\'" \\\n')
                else:
                    f.write(f'"{prov}/{model_id}," \\\n')
    except Exception as e:
        print(f"Error writing {path.name}: {e}", file=sys.stderr)
        sys.exit(1)


# ========================
# Main
# ========================


def main() -> None:
    config = load_config()
    # Print the config file path in blue
    if sys.stdout.isatty():
        print(f"\033[34mUsing config: {CONFIG_PATH.resolve()}\033[0m")
    else:
        print(f"Using config: {CONFIG_PATH.resolve()}")

    # Ensure output directories exist
    PI_FISH_PATH.parent.mkdir(parents=True, exist_ok=True)

    config_providers = config.get("providers", {})
    if not config_providers:
        print("Error: No providers defined in config.", file=sys.stderr)
        sys.exit(1)

    api_data = fetch_models_api()
    provider_meta, provider_lower_models, all_models_flat = index_providers(api_data)
    all_provider_keys_sorted = sorted(api_data.keys())

    outputs, pi_order = generate_outputs(
        config_providers=config_providers,
        provider_meta=provider_meta,
        provider_lower_models=provider_lower_models,
        all_models_flat=all_models_flat,
        all_provider_keys_sorted=all_provider_keys_sorted,
        max_distance=MAX_LEVENSHTEIN_DISTANCE,
    )

    write_json({"providers": outputs}, PI_CODING_AGENT_MODELS_JSON_PATH)
    write_pi_fish(pi_order, PI_FISH_PATH)

    success(
        f"Successfully generated:\n{PI_CODING_AGENT_MODELS_JSON_PATH}\n{PI_FISH_PATH}"
    )


if __name__ == "__main__":
    main()
