import type { HunkExtensionAPI } from "hunkdiff/extension";
import { compileRules, shouldExclude } from "./matches";

// Hunk labels every extension toast with a bare "ext" badge, so messages have to
// name their own extension.
const EXTENSION_ID = "hunk-exclude-files";

export default function (hunk: HunkExtensionAPI) {
  const problems: string[] = [];
  const rules = compileRules(hunk.config.patterns, (message) => {
    problems.push(message);
    hunk.log(message);
  });

  if (rules.length === 0 && problems.length === 0) return;

  let reported = false;

  hunk.transformChangeset((changeset, ctx) => {
    if (!reported) {
      reported = true;
      for (const problem of problems) ctx.notify(`${EXTENSION_ID}: ${problem}`, "warning");
    }

    const files = changeset.files.filter((file) => !shouldExclude(file.path, rules));
    const hidden = changeset.files.length - files.length;

    if (hidden > 0) {
      ctx.notify(`${EXTENSION_ID}: hid ${hidden} ${hidden === 1 ? "file" : "files"}`);
    }

    return { ...changeset, files };
  });
}
