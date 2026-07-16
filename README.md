# Proto publish workflow — dry-run demo

Proof-of-concept repo for the approved `@lifestance/protos` collaboration model.

**No packages are published.** Workflows log what *would* happen on CodeArtifact and perform real git operations (PR comments, promote to `testing`, GitHub Releases on `main`).

## Channels

| Channel | Trigger | Would publish | Dist-tag |
|---------|---------|---------------|----------|
| PR / dev | PR push to `main` | `{next}-pr.{N}.{run}` (preview from PR version impact) | `@pr-{N}` |
| QA | Label `ready-for-qa` → merge to `testing` | `{latest}-testing.{run}` | `@testing` |
| Stable | Merge to `main` | `bump(latest tag, version impact)` | `@latest` |
| Docs / CI | Merge to `main` with impact `none` | skipped | — |

## Mental model

Dist-tags are **pointers** on the registry. Semver strings like `1.30.9` are **pins**.

```text
@lifestance/protos@pr-42     →  this PR’s preview build
@lifestance/protos@testing   →  whatever is integrated on the testing branch now
@lifestance/protos@latest    →  current stable release on main
@lifestance/protos@1.30.9    →  this exact release (best for production)
```

**Production:** pin an exact version in `package.json` (e.g. `"1.30.9"`), not a moving tag.

Details and `package.json` examples: [docs/CONSUMING.md](docs/CONSUMING.md).

## Versioning (summary)

Every PR targeting `main` must check **exactly one** box under **Version Impact** in the PR template:

| Impact | Bump | Notes |
|--------|------|-------|
| `patch` | `x.y.Z+1` | Bug fixes |
| `minor` | `x.Y+1.0` | New backward-compatible features |
| `major` | `X+1.0.0` | Requires `version:major-approved` label |
| `none` | skip | Docs / `.github` / `*.md` only |

**Source of truth for bumps:** latest semver git tag on `main`. `package.json` is synced to match after each stable release.

Full rules: [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md).

## Documentation

| Doc | Contents |
|-----|----------|
| [docs/RELEASE_CANDIDATE_REVIEW.md](docs/RELEASE_CANDIDATE_REVIEW.md) | Approval summary: problem, solution, policy, flows, troubleshooting |
| [docs/SETUP.md](docs/SETUP.md) | Labels, branch protection, first push |
| [docs/SHIPPING_A_PR.md](docs/SHIPPING_A_PR.md) | End-to-end contributor flow |
| [docs/TESTING_BRANCH.md](docs/TESTING_BRANCH.md) | Merge conflicts, parallel PRs, recreate `testing` |
| [docs/CONSUMING.md](docs/CONSUMING.md) | Downstream `package.json` overrides and dist-tags |
| [docs/WORKFLOWS.md](docs/WORKFLOWS.md) | GitHub Actions reference and log output |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common failures and fixes |
| [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md) | Semver rules, major gate, allowlists |

## Quick reference

```text
PR opened → version-impact + @pr-{N} preview
    ↓
ready-for-qa → testing (@testing)     ← conflicts fixed on testing, not PR
    ↓
QA pass → squash-merge PR → main (@latest + GitHub Release)
    ↓
delete + recreate testing from main (GitHub UI) → re-promote WIP PRs locally (one by one)
```

Step-by-step: [docs/SHIPPING_A_PR.md](docs/SHIPPING_A_PR.md).

## After the demo

If the flow is approved, copy workflows into `cm_protos`, implement `scripts/publish-codeartifact.sh` (see stub + workflow comments), and keep [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md) as the team reference.
