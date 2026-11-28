# DAZREVO Autonomous Engineer (v1)

This is a guarded, task-driven coding agent. It uses the repository secret `GEMINI_API_KEY` with Gemini 2.5 Flash.

## Run it
- Open **Actions → DAZREVO Autonomous Engineer → Run workflow** and enter one bounded engineering task; or
- Create an issue describing one bounded task and apply the `autonomous-task` label.

The agent reads a limited set of tracked source files, asks Gemini for a unified diff, validates every changed path against an allowlist, checks the patch with `git apply --check`, runs whitespace and Python syntax checks, and opens a pull request. It never pushes to `main`, auto-merges, executes model-generated shell commands, edits workflow files, or accesses repository secrets other than the Gemini key supplied to the API process.

## Current guardrails and limits
- Allowed code roots: `mobile-overrides/`, `backend-overrides/`, `admin-web/src/`, `darb-workspace/darb-project/`.
- Excludes likely secret files, binary assets, archives, and lockfiles from context.
- Maximum 24 context files / 90 KB, 500 patch lines, 20-minute workflow timeout.
- Repository content and issue text are treated as untrusted data.
- Every proposal is a PR and requires human review plus normal repository CI.
- This first version does not deploy, modify Render, modify GitHub secrets, or auto-merge.
- GitHub Actions scheduling is intentionally not enabled: unattended autonomous changes without a scoped task are unsafe.

## Operational prerequisites
- Add repository Actions secret `GEMINI_API_KEY`.
- Ensure Actions are enabled and the workflow token has **Read and write permissions** (Settings → Actions → General).
- For issue-triggered tasks, create the `autonomous-task` label.
