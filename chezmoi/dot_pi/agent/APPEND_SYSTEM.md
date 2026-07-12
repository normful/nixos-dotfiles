# User interaction tools

- When asking questions, always use the `socrates` tool, not the `ask_user_question` tool.
- If multiple options exist for accomplishing something, present options with `socrates` tool with clear descriptions, pros/cons, and your recommendation.

# Blocked shell commands

When `ctx_shell` returns a "blocked" error (e.g. `'opensrc' is not in the shell allowlist`),
immediately allow the command and retry — do not ask the user for permission:

1. **Allow** — `lean-ctx allow <cmd>`
2. **Retry** — re-run the original `ctx_shell` call

Exception: if the command is dangerous, do NOT allow it — ask the user instead.

What makes a command dangerous: anything that can destroy data, change system state,
execute untrusted code, escalate privileges, interfere with other processes, or
make irreversible changes.

Examples (non-exhaustive): rm -rf, dd, shred, mkfs, fdisk, parted, mkswap, mount,
reboot, shutdown, halt, poweroff, init, systemctl (start/stop/restart/enable/disable),
kill -9, pkill, killall, chown -R, chmod -R 777, mv overwriting existing paths,
`> file` (truncating redirect), tee (overwriting), curl | bash, wget -O, eval,
source (untrusted file), sudo, doas, pkexec, passwd, chsh, usermod, groupmod,
visudo, iptables, ufw, firewall-cmd, ip link (set up/down), ifconfig (down),
tcpdump, nmap --script, docker run --privileged, docker exec (as root),
docker compose (destructive), kubectl delete (non-dry-run), kubectl drain,
helm delete --purge, npm publish, npm unpublish, git push --force, git reset --hard,
git clean -fd, git branch -D, gh repo delete, gh issue close, aws (write ops),
gcloud (write ops), terraform apply, terraform destroy, ansible-playbook,
puppet apply, chef-client, salt, flyctl launch, flyctl destroy, vercel --prod,
netlify deploy --prod, supabase db push, prisma db push, prisma migrate reset,
npx prisma migrate deploy, pg_dump (with --clean), dropdb, createdb, psql -c "DROP",
mysql -e "DROP", redis-cli FLUSHALL, mongosh (dropDatabase), curl -X DELETE,
http DELETE, wrk, hey, siege, ab (load testing hitting production).
