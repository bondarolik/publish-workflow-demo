# Release candidate review — proto publishing workflow

## Purpose

This document is the review summary for adopting this workflow in `cm_protos`. The demo repository currently runs the full process in **dry-run mode**: it performs real GitHub operations, but does not publish a package to CodeArtifact.

## Problem to solve

Today, proto package releases need a repeatable way to:

- preview a proposed contract change before it merges;
- test one or more approved changes together without making the testing branch part of each PR;
- publish stable versions predictably, with an auditable version decision;
- let downstream services choose between a specific PR preview, the QA integration build, and a stable release; and
- prevent accidental releases for documentation-only changes or breaking changes that lack approval.

Without this workflow, version selection, QA promotion, and consumer installation are manual and can drift between teams.

## One-line solution

Use GitHub Actions to validate PR-declared SemVer impact, publish tagged PR and QA previews, and release an immutable stable package from `main`.

## Brief versioning policy

- **Git tags on `main` are the stable-version source of truth**; `package.json` is synced after a stable release.
- Every PR to `main` selects exactly one impact:
  - `patch` — backward-compatible fix
  - `minor` — backward-compatible capability
  - `major` — breaking change; requires the `version:major-approved` guardian label
  - `none` — docs, CI, or repository metadata only; no publish or release
- The `version-impact` required check validates the selection, the major approval, and that `none` changes only allowed paths.
- Releases use three channels:
  - PR preview: `{next}-pr.{PR number}.{run}` at `@pr-{PR number}`
  - QA integration: `{latest}-testing.{run}` at `@testing`
  - Stable: `bump(latest tag, impact)` at `@latest`
- Downstream production services should pin an exact SemVer version (for example, `"@lifestance/protos": "1.30.9"`), rather than a moving dist-tag.

Full policy: [VERSIONING_POLICY.md](VERSIONING_POLICY.md). Consumer examples: [CONSUMING.md](CONSUMING.md).

## Brief GitHub Actions flow

```text
Open/update PR to main
  → version-impact validates Version Impact
  → publish-pr exposes @pr-{PR number} preview

Add ready-for-qa label
  → promote-to-testing squash-merges PR changes into testing
  → publish-testing updates @testing for integrated QA

Squash-merge approved PR to main
  → publish-main computes SemVer from latest tag + PR impact
  → creates git tag and GitHub Release
  → publishes @latest (CodeArtifact integration replaces the current dry run)
  → syncs package.json with the stable version
```

The `testing` branch is an integration environment, not an upstream branch for PRs. Resolve conflicts on `testing`; do not merge `testing` into a PR branch. After a stable release, recreate `testing` from `main` and re-promote any remaining QA PRs one at a time.

Workflow reference: [WORKFLOWS.md](WORKFLOWS.md). Contributor and testing-branch procedures: [SHIPPING_A_PR.md](SHIPPING_A_PR.md) and [TESTING_BRANCH.md](TESTING_BRANCH.md).

## Troubleshooting

| Symptom | Expected response |
|---|---|
| `version-impact` fails | Select exactly one version impact; for `major`, have the guardian add `version:major-approved`; for `none`, restrict changes to allowed docs/CI paths. |
| PR preview does not run | Ensure `version-impact` passed; preview publishing is deliberately skipped for `none`. |
| Promote to testing conflicts | Resolve the squash merge locally on `testing`, push it, and leave the PR branch unchanged. |
| `ready-for-qa` does not promote after recreating `testing` | Re-promote the PR manually; existing labels do not retrigger promotion. |
| `package.json` is invalid | Remove JSON comments and do not manually edit the package `version`. |
| Stable release cannot create a tag | Verify whether that release tag already exists and confirm the latest tag and PR impact. |

Complete troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Rollout plan — `cm_protos`

1. Copy the approved workflows, scripts, PR template, and policy documentation into the existing `cm_protos` repository.
2. DevOps configures the GitHub Actions prerequisites:
   - CodeArtifact authentication, repository/registry configuration, and required secrets or AWS role access;
   - GitHub Actions write permissions for PR comments, branch promotion, tags, and GitHub Releases;
   - the `ready-for-qa` and `version:major-approved` labels; and
   - `main` branch protection requiring the `version-impact` status check.
3. Replace the dry-run path in the publish workflows by implementing `scripts/publish-codeartifact.sh` to publish to CodeArtifact.
4. Validate the full workflow in the target repository with controlled PRs covering `patch`, `minor`, approved `major`, and `none`, plus PR preview, testing promotion, and stable release.
5. Enable the real publish steps only after the validation succeeds and DevOps confirms CodeArtifact access and package visibility for consumer services.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| A breaking change is released without enough review | `major` requires both the PR declaration and the `version:major-approved` guardian label; `version-impact` blocks merge otherwise. |
| A docs-only PR accidentally publishes a package | The `none` path allowlist rejects consumer-impacting files, and stable publishing skips `none`. |
| Multiple QA PRs conflict or create unclear testing scope | Resolve conflicts only on `testing`; for small teams, promote and release one PR at a time, then recreate `testing` from `main`. |
| A downstream production service unexpectedly changes package version | Production consumers pin an exact SemVer version; `pr-*`, `testing`, and `latest` are intended for preview or controlled update use. |
| GitHub workflow permissions or CodeArtifact access fail during rollout | DevOps configures and validates Actions permissions and CodeArtifact authentication before real publishing is enabled. |
| A bad stable release reaches `@latest` | Stable versions are immutable and identifiable by git tag; consumers can revert to their last known-good exact version while a corrective release is prepared. |

## Rollback plan

### Before real CodeArtifact publishing is enabled

Disable or revert the workflow changes in `cm_protos`; no registry state needs to be repaired because the demo uses dry-run publishing.

### After a release workflow issue

1. Disable the affected GitHub Actions workflow or remove its ability to publish until the issue is understood.
2. Do **not** delete or retag a published stable version. Git tags and released package versions are immutable audit records.
3. Revert consumer services to their last known-good **exact** `@lifestance/protos` version and commit the lockfile.
4. Fix the issue in a new PR, select the appropriate version impact, and publish a new corrective stable version.
5. If only the `testing` integration branch is affected, recreate `testing` from `main` and re-promote the QA PRs that still need validation.

## Approval requested

Approve adoption of this workflow in `cm_protos`, with CodeArtifact publishing enabled by implementing `scripts/publish-codeartifact.sh` in place of the existing dry-run publisher.
