export type PathRule = {
  include: boolean;
  matches: (path: string) => boolean;
};

/** Translate a glob into an anchored RegExp: `**` spans path parts, `*` and `?` stay inside one. */
function toRegExp(pattern: string): RegExp {
  let source = "";

  for (let index = 0; index < pattern.length; index += 1) {
    const char = pattern[index]!;

    if (char === "*") {
      if (pattern[index + 1] !== "*") {
        source += "[^/]*";
        continue;
      }

      if (pattern[index + 2] === "/") {
        source += "(?:.*/)?";
        index += 2;
      } else {
        source += ".*";
        index += 1;
      }
      continue;
    }

    if (char === "?") {
      source += "[^/]";
      continue;
    }

    source += /[A-Za-z0-9_]/.test(char) ? char : `\\${char}`;
  }

  return new RegExp(`^${source}$`);
}

export function compileRules(value: unknown, warn: (message: string) => void): PathRule[] {
  if (value === undefined) return [];

  if (!Array.isArray(value)) {
    warn('ignored "patterns": expected an array of glob strings');
    return [];
  }

  const rules: PathRule[] = [];
  for (const rawPattern of value) {
    if (typeof rawPattern !== "string" || rawPattern.trim() === "") {
      warn("ignored an empty or non-string pattern");
      continue;
    }

    const include = rawPattern.startsWith("!");
    const pattern = (include ? rawPattern.slice(1) : rawPattern).trim();
    if (pattern === "") {
      warn('ignored "!": expected a glob after "!"');
      continue;
    }

    const expression = toRegExp(pattern);
    rules.push({ include, matches: (path) => expression.test(path) });
  }

  return rules;
}

export function shouldExclude(path: string, rules: PathRule[]): boolean {
  let excluded = false;

  for (const rule of rules) {
    if (rule.matches(path)) excluded = !rule.include;
  }

  return excluded;
}
