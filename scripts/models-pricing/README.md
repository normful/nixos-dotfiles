# Models.dev Pricing Query

Query [models.dev/api.json](https://models.dev/api.json) for per-provider pricing on specified model IDs.

Shows min/max/avg/mode input pricing (USD per million tokens) across all providers, **excluding free ($0) tiers** from aggregates. Also shows output pricing and a full price-point breakdown by provider.

## Usage

```bash
curl -sL https://models.dev/api.json | python3 models_pricing.py
```

Or from a local copy:

```bash
python3 models_pricing.py < /tmp/api.json
```

## How it works

1. Fetches the models.dev API JSON via stdin.
2. Matches each target model ID against all provider model entries (handles dot/dash/no-sep variants, `hf:`, `route/`, provider-namespaced forms).
3. Deduplicates by (provider name, model ID) to avoid double-counting.
4. Computes statistics on non-zero input prices (free tiers excluded from min/max/avg/mode).
5. Outputs a price-point breakdown showing which providers charge each rate.

## Supported models

| Target ID | Variants matched |
|---|---|
| `minimax-m2.7` | MiniMax-M2.7, minimax/m2.7, fireworks, route/, coding- variants |
| `gpt-5.5` | openai/gpt-5.5, gpt-5.5-pro, databricks-, duo-chat- |
| `gpt-5.4` | openai/gpt-5.4, gpt-5.4-pro, openai/gpt-5.4-image-2, databricks- |
| `claude-opus-4.7` | anthropic/claude-opus-4.7, aws bedrock, databricks, stealth, fast/think variants |
| `claude-sonnet-4.6` | anthropic/claude-sonnet-4.6, aws bedrock, thinking variants |
| `gemini-3.5-flash` | google/gemini-3.5-flash |
| `claude-opus-4.6` | anthropic/claude-opus-4.6, aws bedrock, thinking variants |
| `gpt-5.4-mini` | openai/gpt-5.4-mini, databricks-, duo-chat- |
| `kimi-k2.6` | moonshotai/Kimi-K2.6, kimi/kimi-k2.6, fireworks, cf workers, thinking variants |
| `mimo-v2.5-pro` | xiaomi/mimo-v2.5-pro, coding variants, route/, free tiers |
| `deepseek-v4-flash` | deepseek/deepseek-v4-flash, deepseek-ai, fireworks, alicloud, elite, route/ |
| `glm-5.1` | zai-org/GLM-5.1, zai/glm-5.1, alicloud-, coding variants, FP8/TEE variants |

## Adding models

Edit `TARGET_MODEL_IDS` in `models_pricing.py` with the canonical model ID plus all known variant forms.

## Data source

https://models.dev/api.json — aggregated model pricing from 40+ providers including OpenAI, Anthropic, Google, DeepSeek, Amazon Bedrock, Azure, and many resellers.
