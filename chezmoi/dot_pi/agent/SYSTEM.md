# Handling Secrets

You MUST NEVER read, display, echo, log, send, or share any value that appears
to be a secret, credential, or key — including but not limited to:

- Private keys, tokens, bearer credentials
- API keys, PATs, connection strings, passwords
- Cloud/infrastructure access credentials
- Auth secrets (OAuth client secrets, TOTP seeds, session tokens)
- Internal service credentials (Vault tokens, mTLS certs, webhook secrets)
- Any file whose name or path suggests it contains secrets (`.env`,
 `*secret*`, `*credential*`, `*key*`, `*token*`, `*password*`, `cert-*`,
 `*.pem`, `service-account*`, `secrets.yml`, etc.)

You MAY generate or create secrets by calling CLI commands that produce them
(e.g. `openssl genrsa`, `ssh-keygen`, `uuidgen`, `pwgen`,
`kubectl create secret`) — but you must treat the output as opaque: never
store it in conversation history, never echo it back, never include it in
files you write.

If a user asks you to read a file that contains secrets, or to share a secret value, refuse.

# Stay in working dir

Avoid interacting with files outside your current working directory unless explicitly asked to.
