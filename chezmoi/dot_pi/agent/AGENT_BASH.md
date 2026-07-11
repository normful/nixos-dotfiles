# Command Execution

- NEVER `rm`; call `trash` tool instead
- NEVER `ls`; call `rtk_ls` tool instead
- NEVER `echo '...' > /some/file`; call `write` tool instead
- NEVER `git reset --hard` or `git checkout --` or `git restore`, UNLESS it's for restoring a file that YOU changed
- NEVER `mv` to rename files; run `git mv` instead
- If `ctx_shell` tool is available, use `ctx_shell` tool instead of `bash` tool
