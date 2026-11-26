# DAZREVO Telegram Operations Bot

The Telegram bot is an operational read-only interface to the existing DAZREVO backend. It does not accept commands from groups, does not change customer/order data, and does not trigger builds or releases.

## Render environment

After the feature is merged and the Render service has deployed, add these environment variables to the existing `darb-api` service:

| Variable | Value |
| --- | --- |
| `TELEGRAM_BOT_TOKEN` | The token of the existing DAZREVO bot. Keep it secret. |
| `TELEGRAM_ADMIN_IDS` | Comma-separated numeric Telegram user IDs allowed to run admin commands. |
| `TELEGRAM_WEBHOOK_SECRET` | A random secret with at least 32 characters. Use only letters, numbers, underscores, and hyphens. |
| `TELEGRAM_WEBHOOK_URL` | `https://darb-api-yapv.onrender.com/api/v1/internal/telegram/webhook` |
| `GITHUB_TOKEN` | Fine-grained GitHub token limited to this repository with **Contents: Read-only** permission; used to avoid GitHub's unauthenticated API rate limit. |

Use the same bot token already stored as the GitHub Actions `TELEGRAM_BOT_TOKEN` secret. Do not put the token in Git, source files, screenshots, or chat messages. Generate a fresh webhook secret in a password manager; do not reuse the bot token.

Create a fine-grained personal access token restricted to `anasgdxj/darb-delivery-platform`, grant **Contents: Read-only**, and store it in Render as `GITHUB_TOKEN`. Never send it in chat or commit it to Git. The token is used only for read-only release metadata requests.

The backend registers the webhook with Telegram on startup after the bot token, webhook URL, and webhook secret are configured. No manual `setWebhook` request is required. A successful Render deploy and a startup log entry saying the webhook was registered are required before testing commands.

## Find the numeric Telegram user ID

1. Open a private chat with the DAZREVO bot.
2. Send `/id`.
3. Copy the numeric ID returned by the bot.
4. Set `TELEGRAM_ADMIN_IDS` to that number in Render and save the environment change.

The `/id` command only returns the sender's own numeric ID. It does not grant administrative access. Operational commands remain denied until the ID is explicitly allowlisted.

## Commands

- `/status` — liveness and readiness summary for API, PostgreSQL, and Redis.
- `/api` — detailed HTTP checks for `/api/v1/healthz` and `/api/v1/readyz`.
- `/version` or `/apk` — downloads the latest published APK and sends it as a Telegram document attachment (ARM64 build, under Telegram's 50 MiB limit).
- `/releases` — latest five published GitHub releases.
- `/help` — command list.

Commands are accepted only in private chats from IDs in `TELEGRAM_ADMIN_IDS`. The webhook checks Telegram's `X-Telegram-Bot-Api-Secret-Token` header using a constant-time comparison. Command audit logs include the sender ID, command, outcome, and timestamp; message contents and secrets are not logged.


The `/version` and `/apk` commands attach the signed `app-arm64-v8a-release.apk` file. This build targets 64-bit ARM Android devices; the universal `app-release.apk` remains the in-app updater's download. The bot verifies the GitHub asset size and SHA-256 digest before sending it. If the ARM64 asset is absent or exceeds Telegram's upload limit, the command reports the failure instead of pretending a link is an attached APK.

## Current safety boundary

This is phase one: read-only monitoring. No order lookup, customer data, financial operation, deployment, build trigger, write, or delete command is exposed. Those capabilities require separate authorization, audit, confirmation, and review work before implementation.
