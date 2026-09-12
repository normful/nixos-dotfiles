# Hunk Exclude Files

A [Hunk](https://www.hunk.dev/) extension that hides files matching configured
glob rules from a review.

## Install

Requires Hunk 0.19.0 or later.

```sh
hunk extension install astwys/hunk-exclude-files
```

Hunk installs it under `~/.config/hunk/extensions/installed/` and loads it for
every review. Use `hunk extension list`, `update`, and `remove` to manage it.

## Configure

Add patterns to your user config (`~/.config/hunk/config.toml`) or a
repository's `.hunk/config.toml`:

```toml
[extension.hunk-exclude-files]
patterns = [
  "*.lock",
  "*.snap",
  "dist/**",
  "generated/**",
  "vendor/**",
]
```

Patterns match repository-relative paths. `*` matches within one path part, `**`
matches nested paths, and `?` matches a single character. Dotfiles match too.

Rules run in order. Prefix a later rule with `!` to restore files hidden by an
earlier rule:

```toml
[extension.hunk-exclude-files]
patterns = ["generated/**", "!generated/keep.ts"]
```

The extension only changes Hunk's review stream. It does not change the working
tree or Git ignore rules.

## Development

```sh
git clone https://github.com/astwys/hunk-exclude-files.git
cd hunk-exclude-files
pnpm install
pnpm test
pnpm dev  # hunk diff --extension .
```

## License

[MIT](LICENSE)
