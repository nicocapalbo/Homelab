# Agent instructions

## Pre-push hook: auto-sync private config repo

A `pre-push` hook in `.githooks/` auto-runs `sync-private.sh` before pushing changes that include `.env` or `appdata/`. After cloning fresh, enable it with:

```bash
git config core.hooksPath .githooks
```

Git tracks the hook script but NOT the config — run the command above on every new clone.
