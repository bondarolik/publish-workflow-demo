# Versioning policy

This document defines how stable, staging, and PR pre-release versions are chosen in the **publish-workflow-demo** repository and the production `@lifestance/protos` model it proves.

## Principles

- Follow [Semantic Versioning 2.0.0](https://semver.org/): `MAJOR.MINOR.PATCH`.
- **Git tags on `main` are the source of truth** for the current stable version.
- Engineers declare version impact in every pull request — branch names are **not** used for versioning.
- **Major bumps are gated** by a git guardian after tech meeting approval.
- **Docs / CI / markdown-only changes** do not produce a release.

## Version impact (required on every PR)

Each pull request targeting `main` must check **exactly one** box under **Version Impact** in the PR template (`.github/pull_request_template.md`).

GitHub markdown does not support true radio buttons. The template uses a checkbox list; the **`version-impact`** CI check enforces that exactly one box is checked (radio behavior).

| Selection | Semver bump | Example |
|-----------|-------------|---------|
| `patch` | `x.y.Z + 1` | `1.2.0` → `1.2.1` |
| `minor` | `x.Y + 1.0` | `1.2.0` → `1.3.0` |
| `major` | `X + 1.0.0` | `1.2.0` → `2.0.0` |
| `none` | no bump | no tag, no release, no publish |

### What each level means

| Level | Use when |
|-------|----------|
| **patch** | Backward-compatible bug fix |
| **minor** | New backward-compatible capability (new RPC, new optional field) |
| **major** | Breaking change (removed RPC, renamed field, incompatible wire change) |
| **none** | Documentation, markdown, GitHub Actions, or repo metadata only |

## Major releases — guardian gate

Major bumps require **both**:

1. Developer checks **major** under Version Impact in the PR description.
2. Git guardian adds the **`version:major-approved`** label after tech meeting agreement.

The required **`version-impact`** check blocks merge until the label is present.

### Git guardian responsibilities

- Attend or review tech meeting decision for breaking proto changes.
- Apply the label: `gh pr edit <number> --add-label "version:major-approved"`.
- Ensure consumers are informed before the major release merges.

### Label specification

| Label | Color (suggested) | Purpose |
|-------|-------------------|---------|
| `version:major-approved` | `#B60205` (red) | Guardian approval for a major semver bump |

Create this label in **Settings → Labels** before the first major PR.

## Version impact `none` — allowed paths only

`none` is valid only when **every changed file** in the PR matches the allowlist:

| Pattern | Examples |
|---------|----------|
| `**/*.md` | `README.md`, `docs/guide.md` |
| `docs/**` | `docs/VERSIONING_POLICY.md` |
| `.github/**` | workflows, PR template, label config |
| `README*` | `README.md` |
| `.gitignore` | root ignore file |
| `LICENSE*` | `LICENSE`, `LICENSE.md` |

**Not allowed for `none`:** `contracts/**`, `**/*.proto`, `package.json`, application code, generated artifacts, or any file that affects package consumers.

The **`version-impact`** workflow enforces this automatically.

## Enforcement

| Layer | Mechanism |
|-------|-----------|
| PR template | Required markdown checklist — exactly one Version Impact box checked |
| `version-impact` workflow | Required status check before merge |
| `version:major-approved` | Guardian label for major only |
| Path guardrail | Blocks `none` when proto or consumer files change |
| `publish-main` | Computes next version from latest tag + PR impact; skips release when `none` |

### Branch protection (manual GitHub setting)

On `main`, require status check:

- **`version-impact`**

## Channel versioning

Latest stable tag = `T`. Version impact on the PR = `I`. Next stable = `bump(T, I)`.

| Channel | Trigger | Version format | Dist-tag |
|---------|---------|----------------|----------|
| PR | PR updated → `main` | `{bump(T, I)}-pr.{N}.{run}` | `@pr-{N}` |
| Staging | Push to `staging` | `{T}-staging.{run}` | `@staging` |
| Stable | Merge to `main` | `bump(T, I)` | `@latest` |

### PR preview version

PR pre-releases use the **computed next stable version** as a preview, not the current tag alone.

Example: latest tag `1.2.0`, PR selects `minor` → PR package version `1.3.0-pr.4.2`.

When impact is `none`, the PR publish workflow is skipped and the PR comment explains why.

### Staging version

Staging uses the **current latest tag** as base (no semver bump on the staging channel). Example: `1.2.0-staging.5`.

### Stable release

On merge to `main`:

1. Read version impact from the merged PR body.
2. If `none` → skip tag, GitHub Release, and package publish.
3. Otherwise → `VERSION = bump(latest tag, impact)`.
4. Create git tag `VERSION` and GitHub Release with auto-generated notes.

`package.json` is **not** the release source of truth. It may be updated separately for documentation; tags govern automation.

## Initial version

If no semver tag exists yet, automation starts from **`0.0.0`**.

For the first production release, the team may manually tag `1.0.0` on `main` or let the first merged PR compute the next version from `0.0.0`.

## What is not used

- Branch name prefixes (`feature/`, `fix/`, …) for versioning
- Commit message conventions for automation (unreliable after squash merge)
- Local git hooks as enforcement (optional DX only)

## Workflows reference

| Workflow | Role |
|----------|------|
| `version-impact.yml` | Validates PR version declaration |
| `publish-pr.yml` | PR pre-release dry run + PR comment |
| `promote-to-staging.yml` | Promotes PR to `staging` |
| `publish-staging.yml` | Staging channel dry run |
| `publish-main.yml` | Stable release + GitHub Release |
| `reset-staging.yml` | Reset `staging` to `main` |

## Adoption in `cm_protos`

After this demo is approved:

1. Copy workflows and scripts into `cm_protos`.
2. Replace `scripts/publish.sh` dry-run logging with real CodeArtifact publish in production.
3. Keep this policy document as the team reference.
