# DARB Engineering Toolkit

## Purpose

This toolkit adds repeatable quality gates and operational visibility around the existing Darb repository. It is additive: it must not replace the source archive, backend overlays, mobile release pipeline, signing configuration, or existing CI workflows.

## Repository facts

- Repository: `anasgdxj/darb-delivery-platform`
- Default branch: `main`
- Android application ID: `com.darb.darb`
- Backend: NestJS, Prisma, PostgreSQL/PostGIS, Redis
- Mobile: Flutter / Android
- Backend liveness: `GET /api/v1/healthz`
- Backend readiness: `GET /api/v1/readyz`
- Preview API: `https://darb-api-yapv.onrender.com`

The complete application source is currently packaged in `DARB-source.zip`; selected backend changes and migrations are maintained as repository overlays. Automation must respect this layout rather than assume a conventional root-level Flutter or Node project.

## Automation layers

1. **Existing CI preservation** — keep the current backend and Android workflows authoritative for their existing build/test responsibilities. Add new workflows only for distinct checks.
2. **Operational health** — check liveness and readiness independently; readiness is the meaningful signal for database and Redis dependencies.
3. **Security hygiene** — use least-privilege workflow permissions, dependency update PRs, and secret scanning. Never print secret values.
4. **Release governance** — release builds must retain package identity, version progression, and existing signing secrets. A successful build is not a device acceptance test.
5. **Human approval gates** — do not automatically merge pull requests, deploy production, send SMS, spend provider credits, rotate credentials, or modify signing keys.
6. **Evidence** — every automation change must be validated by GitHub Actions and documented with its run or pull-request link.

## Required checks before release

- Backend CI passes, including Prisma migration validation and tests.
- Flutter analysis, tests, and Android release build pass in the established mobile pipeline.
- API liveness and readiness return HTTP 200.
- The release APK uses the configured HTTPS API base URL, not an emulator or placeholder URL.
- The signed APK is installed and smoke-tested on a real Android device.
- Authentication, role authorization, order lifecycle, location permissions, and push behavior are tested against the intended environment.

## Secrets and provider integrations

Keep all credentials in GitHub Actions Secrets or the hosting provider's secret manager. Never commit `.env`, service-account JSON, Google/Firebase private credentials, SMS API keys, database URLs, Redis URLs, or Android keystores/passwords.

Do not send live OTP messages or consume prepaid SMS balance as part of scheduled automation. Firebase push and map-provider checks must remain disabled until their real credentials and production endpoints are configured and explicitly approved.

## Safe change policy

- Work on a feature branch and open a pull request.
- Never force-push or rewrite shared history.
- Never merge or close existing user pull requests as part of toolkit setup.
- Never overwrite an existing workflow until its triggers, jobs, and release behavior have been inspected.
- Keep PR #61 and other in-flight product work independent from toolkit changes.
- Prefer narrow, reversible changes and verify the resulting Actions run before proceeding.

## Current toolkit rollout

- Foundation: repository-specific operating rules, API health monitor, and GitHub Actions dependency update configuration.
- Next: inspect and consolidate existing mobile/backend workflows without duplicating builds.
- Then: add source-aware security and dependency audits, release verification, and operational reporting.
