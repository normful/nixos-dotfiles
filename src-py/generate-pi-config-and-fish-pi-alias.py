#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# ///

# pyright: strict, reportExplicitAny=false, reportUnknownVariableType=false, reportUnknownMemberType=false, reportUnknownArgumentType=false, reportUnknownParameterType=false, reportAny=false, reportUnusedCallResult=false

"""
Input:
  - models-config.toml
  - https://models.dev/api.json
Output:
  - pi coding agent models.json config file (ultimately saved at ~/.pi/agent/models.json, after running chezmoi)
  - pi fish shell abbreviation

Docs for models.json file: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/custom-provider.md

Run with:
    uv run src-py/generate-pi-config-and-fish-pi-alias.py
"""

import json
import ssl
import sys
import tomllib
import urllib.request
from pathlib import Path
from typing import Any, TypedDict

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

MODELS_DEV_API = "https://models.dev/api.json"
MAX_LEVENSHTEIN_DISTANCE = 3

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# ========================
# Types
# ========================


class ProviderMeta(TypedDict):
    baseUrl: str
    api: str
    apiKey: str
    authHeader: bool


class ProviderConfig(TypedDict):
    """Represents a provider config from models-config.toml."""

    include: bool
    authHeader: bool | None
    models: list[str]
    model: dict[str, dict[str, Any]]


LowerModelMap = dict[str, tuple[dict[str, Any], str]]
FlatModel = tuple[str, dict[str, Any], str, str]

# Model override keys that can be specified in TOML
MODEL_OVERRIDE_KEYS: set[str] = {
    "name",
    "reasoning",
    "input",
    "cost",
    "contextWindow",
    "maxTokens",
}

# OpenAI compat keys that can be specified in TOML
COMPAT_OVERRIDE_KEYS: set[str] = {
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
# Model Transform Helpers
# ========================


def extract_input_modalities(
    overrides: dict[str, Any], api_response_model_data: dict[str, Any]
) -> list[str]:
    """Extract and filter supported input modalities from overrides or API data."""
    if "input" in overrides:
        input_modalities = overrides["input"]
    else:
        modalities: dict[str, Any] = api_response_model_data.get("modalities", {})
        input_modalities = modalities.get("input", [])
    supported_types = [t for t in input_modalities if t in ("text", "image")]
    return supported_types if supported_types else ["text"]


def extract_cost_data(
    overrides: dict[str, Any], api_response_model_data: dict[str, Any]
) -> dict[str, float]:
    """Extract cost data from overrides or API, returning standardized cost dict."""
    if "cost" in overrides:
        cost_dict = overrides["cost"]
    else:
        cost_dict = api_response_model_data.get("cost", {})

    return {
        "input": cost_dict.get("input", 0) if isinstance(cost_dict, dict) else 0,
        "output": cost_dict.get("output", 0) if isinstance(cost_dict, dict) else 0,
        "cacheRead": cost_dict.get("cacheRead", 0)
        if isinstance(cost_dict, dict)
        else 0,
        "cacheWrite": cost_dict.get("cacheWrite", 0)
        if isinstance(cost_dict, dict)
        else 0,
    }


def extract_token_limits(
    overrides: dict[str, Any], api_response_model_data: dict[str, Any]
) -> tuple[int, int]:
    """Extract context window and max output tokens from overrides or API."""
    if "contextWindow" in overrides:
        max_context_tokens = overrides["contextWindow"]
    elif "limit" in api_response_model_data:
        max_context_tokens = api_response_model_data["limit"].get("context", 0)
    else:
        max_context_tokens = 0

    if "maxTokens" in overrides:
        max_output_tokens = overrides["maxTokens"]
    elif "limit" in api_response_model_data:
        max_output_tokens = api_response_model_data["limit"].get("output", 0)
    else:
        max_output_tokens = 0

    return max_context_tokens, max_output_tokens


def build_compat_object(
    overrides: dict[str, Any], api_response_model_data: dict[str, Any]
) -> dict[str, Any] | None:
    """Build compat object from overrides and API data with proper precedence."""
    compat: dict[str, Any] = {}

    # Check for direct compat keys (e.g., supportsDeveloperRole = true)
    direct_compat_keys = overrides.keys() & COMPAT_OVERRIDE_KEYS
    for key in direct_compat_keys:
        compat[key] = overrides[key]

    # Also check for nested compat = { ... } dict in overrides
    if "compat" in overrides and isinstance(overrides["compat"], dict):
        nested_compat: dict[str, Any] = overrides["compat"]
        for key in COMPAT_OVERRIDE_KEYS:
            if key in nested_compat and key not in compat:
                compat[key] = nested_compat[key]

    # Fall back to API data if not in overrides
    if compat:
        api_compat: dict[str, Any] = api_response_model_data.get("compat", {})
        for key in COMPAT_OVERRIDE_KEYS:
            if key not in compat and key in api_compat:
                compat[key] = api_compat[key]
        return compat

    return None


# ========================
# Core Functions
# ========================


def load_config() -> dict[str, Any]:
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


def fetch_models_dot_dev_api_res() -> dict[str, Any]:
    """Fetch the models.dev API JSON."""
    try:
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        req = urllib.request.Request(MODELS_DEV_API, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, context=context) as response:
            result: dict[str, Any] = json.load(response)
            return result
    except Exception as e:
        print(f"Error fetching API: {e}", file=sys.stderr)
        sys.exit(1)


def process_provider_entry(
    provider_name: str,
    api_response_provider_data: dict[str, Any],
) -> tuple[ProviderMeta, LowerModelMap, list[FlatModel]]:
    """Process a single provider from API data, returning meta, model map, and flat list.

    Note: authHeader is read from models-config.toml, not from the API response.
    """
    base_url = api_response_provider_data.get("api", "")
    npm = api_response_provider_data.get("npm", "")
    api_type = infer_api_type(npm)
    env_vars_list = api_response_provider_data.get("env", [])
    api_key = env_vars_list[0] if env_vars_list else f"{provider_name.upper()}_API_KEY"

    provider_meta: ProviderMeta = {
        "baseUrl": base_url,
        "api": api_type,
        "apiKey": api_key,
        "authHeader": False,  # Placeholder; overridden by TOML config in generate_outputs()
    }

    provider_models: dict[str, Any] = api_response_provider_data.get("models", {})
    model_id_to_data_map: LowerModelMap = {}
    all_models_flat: list[FlatModel] = []
    for mid, mdata in provider_models.items():
        mid_lower = mid.lower()
        model_id_to_data_map[mid_lower] = (mdata, mid)
        all_models_flat.append((provider_name, mdata, mid, mid_lower))

    return provider_meta, model_id_to_data_map, all_models_flat


def index_providers(
    api_data: dict[str, Any],
) -> tuple[dict[str, ProviderMeta], dict[str, LowerModelMap], list[FlatModel]]:
    """Build indexes for provider metadata and model lookup."""
    provider_meta: dict[str, ProviderMeta] = {}
    provider_lower_models: dict[str, LowerModelMap] = {}
    all_models_flat: list[FlatModel] = []

    for provider_name, provider_data in api_data.items():
        meta, model_map, flat_list = process_provider_entry(
            provider_name, provider_data
        )
        provider_meta[provider_name] = meta
        provider_lower_models[provider_name] = model_map
        all_models_flat.extend(flat_list)

    return provider_meta, provider_lower_models, all_models_flat


def extract_preset_comparison_id(model_id: str) -> str | None:
    """Extract the comparison ID from @preset/model-id format.

    For @preset/kimi25-high-reasoning, extracts 'kimi25' (text before first hyphen).
    Returns None if not a preset model.
    """
    if not model_id.startswith("@preset/"):
        return None

    after_preset = model_id[len("@preset/") :]
    first_hyphen_idx = after_preset.find("-")
    if first_hyphen_idx == -1:
        return after_preset.lower()
    return after_preset[:first_hyphen_idx].lower()


def extract_model_name_from_id(model_id: str) -> str:
    """Extract just the model name from provider/model-id format.

    For 'moonshotai/kimi-k2.5', extracts 'kimi-k2.5'.
    """
    return model_id.split("/")[-1]


def match_model(
    model_id: str,
    target_provider: str,
    provider_lower_models: dict[str, LowerModelMap],
    all_models_flat: list[FlatModel],
    all_provider_keys_sorted: list[str],
    max_distance: int,
) -> tuple[str, dict[str, Any], str] | None:
    """
    Find the best match for model_id across providers.
    Returns (matched_provider, matched_model_data, original_model_id) or None.
    Search order:
      1. Exact case-insensitive in target_provider
      2. Exact case-insensitive in any other provider
      3. Fuzzy match (Levenshtein) across all providers

    Special handling for @preset/model-id on OpenRouter:
      - Extracts text before first hyphen after @preset/
      - Uses extracted text (e.g., 'kimi25') for matching
    """
    # Special handling for @preset/ models on OpenRouter
    preset_comparison_id = (
        extract_preset_comparison_id(model_id)
        if target_provider == "openrouter" and model_id.startswith("@preset/")
        else None
    )
    normalized_model_id = (preset_comparison_id or model_id).lower()

    # 1. Own provider exact match
    target_provider_models_map = provider_lower_models[target_provider]
    if normalized_model_id in target_provider_models_map:
        matched_data, original_id = target_provider_models_map[normalized_model_id]
        return (target_provider, matched_data, original_id)

    # 2. Other providers exact match - find all, pick the one with smallest context window token limit
    other_provider_matches: list[tuple[str, dict[str, Any], str]] = []
    for other_provider_name in all_provider_keys_sorted:
        if other_provider_name == target_provider:
            continue
        other_provider_models_map = provider_lower_models[other_provider_name]
        if normalized_model_id in other_provider_models_map:
            matched_data, original_id = other_provider_models_map[normalized_model_id]
            other_provider_matches.append(
                (other_provider_name, matched_data, original_id)
            )

    if other_provider_matches:
        # If multiple matches, choose the one with lowest .limit.context
        if len(other_provider_matches) > 1:
            other_provider_matches.sort(
                key=lambda m: m[1].get("limit", {}).get("context", float("inf"))
            )
        return other_provider_matches[0]

    # 3. Fuzzy match - also try matching against model name without provider prefix
    best_distance: int | None = None
    best_match_result: tuple[str, dict[str, Any], str] | None = None

    # For preset models, also create a version with stripped provider prefix
    stripped_normalized_model_id = (
        extract_model_name_from_id(normalized_model_id)
        if "/" in normalized_model_id
        else None
    )

    for prov, mdata, orig_id, mid_lower in all_models_flat:
        # Try matching against the normalized ID as-is
        dist = levenshtein(normalized_model_id, mid_lower)
        if best_distance is None or dist < best_distance:
            best_distance = dist
            best_match_result = (prov, mdata, orig_id)

        # For preset models, also try matching against stripped model name
        if stripped_normalized_model_id is not None:
            mid_name_only = extract_model_name_from_id(mid_lower)
            dist_stripped = levenshtein(stripped_normalized_model_id, mid_name_only)
            if dist_stripped < best_distance:
                best_distance = dist_stripped
                best_match_result = (prov, mdata, orig_id)

    if best_distance is not None and best_distance <= max_distance:
        return best_match_result

    return None


def transform_model(
    model_id: str,
    api_response_model_data: dict[str, Any],
    overrides: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Convert raw API model into the models.json entry format.

    Args:
        model_id: The model ID from config
        api_response_model_data: Raw model data from models.dev API
        overrides: Optional dict of override values from TOML config
    """
    if overrides is None:
        overrides = {}

    # Apply overrides (they take precedence over API data)
    name = overrides.get("name") or api_response_model_data.get("name", model_id)
    reasoning = overrides.get(
        "reasoning", api_response_model_data.get("reasoning", True)
    )

    # Extract using helper functions
    supported_input_types = extract_input_modalities(overrides, api_response_model_data)
    cost_data = extract_cost_data(overrides, api_response_model_data)
    max_context_tokens, max_output_tokens = extract_token_limits(
        overrides, api_response_model_data
    )
    compat_object = build_compat_object(overrides, api_response_model_data)

    # Build output dict
    model_entry: dict[str, Any] = {
        "id": model_id,
        "name": name,
        "reasoning": reasoning,
        "input": supported_input_types,
        "cost": cost_data,
        "contextWindow": max_context_tokens,
        "maxTokens": max_output_tokens,
    }

    if compat_object is not None:
        model_entry["compat"] = compat_object

    return model_entry


def process_provider_models(
    current_provider_name: str,
    filtered_model_list: list[str],
    model_override_configs: dict[str, dict[str, Any]],
    provider_lower_models: dict[str, LowerModelMap],
    all_models_flat: list[FlatModel],
    all_provider_keys_sorted: list[str],
    max_distance: int,
) -> tuple[list[dict[str, Any]], list[tuple[str, str]]]:
    """Process all models for a single provider, returning models list and order entries."""
    provider_models_entry_list: list[dict[str, Any]] = []
    pi_models_order: list[tuple[str, str]] = []

    for model_id in filtered_model_list:
        overrides = model_override_configs.get(model_id, {})

        match = match_model(
            model_id=model_id,
            target_provider=current_provider_name,
            provider_lower_models=provider_lower_models,
            all_models_flat=all_models_flat,
            all_provider_keys_sorted=all_provider_keys_sorted,
            max_distance=max_distance,
        )
        if match is None:
            warning(
                f"Could not find model '{model_id}' for provider '{current_provider_name}' in API (exact or fuzzy within distance {max_distance}). Skipping."
            )
            continue

        _matched_prov, matched_mdata, _matched_original_id = match
        final_model = transform_model(model_id, matched_mdata, overrides)

        # Add to provider models list (provider is already confirmed to have include=true)
        provider_models_entry_list.append(final_model)

        # Always add to pi_models_order for pi.fish
        pi_models_order.append((current_provider_name, model_id))

    return provider_models_entry_list, pi_models_order


def generate_outputs(
    toml_config_providers: dict[str, Any],
    provider_meta: dict[str, ProviderMeta],
    provider_lower_models: dict[str, LowerModelMap],
    all_models_flat: list[FlatModel],
    all_provider_keys_sorted: list[str],
    max_distance: int,
) -> tuple[dict[str, Any], list[tuple[str, str]]]:
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
    output_providers: dict[str, Any] = {}
    pi_models_order: list[tuple[str, str]] = []

    for current_provider_name in toml_config_providers.keys():
        if current_provider_name not in provider_meta:
            print(
                f"Error: Provider '{current_provider_name}' not found in API response.",
                file=sys.stderr,
            )
            sys.exit(1)

        meta = provider_meta[current_provider_name]
        current_provider_config: dict[str, Any] = toml_config_providers[
            current_provider_name
        ]

        # Check if provider should be output to models.json
        output_to_pi_models_json = current_provider_config.get(
            "outputToPiModelsJson", False
        )

        # Get authHeader from config (defaults to False)
        auth_header: bool = current_provider_config.get("authHeader", False)

        # Get model list (must be an array)
        raw_model_list = current_provider_config.get("models")
        if isinstance(raw_model_list, list):
            filtered_model_list = raw_model_list
        else:
            warning(
                f"Provider '{current_provider_name}' has non-array models field, skipping"
            )
            continue

        # Get model overrides from separate [providers.x.model."y"] sections
        model_override_configs: dict[str, dict[str, Any]] = current_provider_config.get(
            "model", {}
        )

        provider_models_entry_list, provider_pi_order = process_provider_models(
            current_provider_name=current_provider_name,
            filtered_model_list=filtered_model_list,
            model_override_configs=model_override_configs,
            provider_lower_models=provider_lower_models,
            all_models_flat=all_models_flat,
            all_provider_keys_sorted=all_provider_keys_sorted,
            max_distance=max_distance,
        )

        # Always add to pi_models_order (all providers for CLI completion)
        pi_models_order.extend(provider_pi_order)

        # Only add to output_providers if output_to_pi_models_json = true
        if output_to_pi_models_json:
            output_providers[current_provider_name] = {
                **meta,
                "authHeader": auth_header,
                "models": provider_models_entry_list,
            }

    return output_providers, pi_models_order


def write_json(data: Any, path: Path) -> None:
    """Write data as pretty JSON (2-space indent)."""
    try:
        with open(path, "w") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print(f"Error writing {path.name}: {e}", file=sys.stderr)
        sys.exit(1)


def write_pi_fish(models: list[tuple[str, str]], path: Path) -> None:
    """Write fish abbreviation file with one model per line."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w") as f:
            f.write('abbr --add pi "pi --models \'"\\\n')
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

    toml_config_providers: dict[str, Any] = config.get("providers", {})
    if not toml_config_providers:
        print("Error: No providers defined in config.", file=sys.stderr)
        sys.exit(1)

    api_data = fetch_models_dot_dev_api_res()
    provider_meta, provider_lower_models, all_models_flat = index_providers(api_data)
    all_provider_keys_sorted = sorted(api_data.keys())

    outputs, pi_order = generate_outputs(
        toml_config_providers=toml_config_providers,
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
