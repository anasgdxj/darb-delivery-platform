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
| `GITHUB_TOKEN` | Fine-grained GitHub token with read-only Contents access to `anasgdxj/darb-delivery-platform`. Required for reliable `/version` and `/releases` API access when the unauthenticated rate limit is exhausted. Keep it secret. |

Use the same bot token already stored as the GitHub Actions `TELEGRAM_BOT_TOKEN` secret. Create a fine-grained GitHub token limited to this repository with **Contents: Read-only**, then add it to Render as `GITHUB_TOKEN`; never commit or share it. Do not put the token in Git, source files, screenshots, or chat messages. Generate a fresh webhook secret in a password manager; do not reuse the bot token.

The backend registers the webhook with Telegram on startup after all four variables are configured. No manual `setWebhook` request is required. A successful Render deploy and a startup log entry saying the webhook was registered are required before testing commands.

## Find the numeric Telegram user ID

1. Open a private chat with the DAZREVO bot.
2. Send `/id`.
3. Copy the numeric ID returned by the bot.
4. Set `TELEGRAM_ADMIN_IDS` to that number in Render and save the environment change.

The `/id` command only returns the sender's own numeric ID. It does not grant administrative access. Operational commands remain denied until the ID is explicitly allowlisted.

## Commands

- `/status` — liveness and readiness summary for API, PostgreSQL, and Redis.
- `/api` — detailed HTTP checks for `/api/v1/healthz` and `/api/v1/readyz`.
- `/version` — latest published GitHub release and official APK asset.
- `/releases` — latest five published GitHub releases.
- `/help` — command list.

Commands are accepted only in private chats from IDs in `TELEGRAM_ADMIN_IDS`. The webhook checks Telegram's `X-Telegram-Bot-Api-Secret-Token` header using a constant-time comparison. Command audit logs include the sender ID, command, outcome, and timestamp; message contents and secrets are not logged.

## Current safety boundary

This is phase one: read-only monitoring. No order lookup, customer data, financial operation, deployment, build trigger, write, or delete command is exposed. Those capabilities require separate authorization, audit, confirmation, and review work before implementation.
