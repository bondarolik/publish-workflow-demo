# How to open and ship a PR

End-to-end flow for a proto change targeting `main`. The PR branch stays the canonical proposal for `main` — integration happens on `testing` only.

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

## 1. Create the branch and change

```bash
git fetch origin main
git checkout -b CM-123-add-match-rpc origin/main
# edit contracts/*.proto (or docs-only files)
git add .
git commit -m "feat(proto): add Match RPC (CM-123)"
git push -u origin CM-123-add-match-rpc
```

Open a PR → `main`. The template pre-fills the description.

## 2. Declare version impact

In the PR description, check **exactly one** box under **Version Impact**:

| Impact | When to use |
|--------|-------------|
| `patch` | Backward-compatible bug fix |
| `minor` | New backward-compatible capability |
| `major` | Breaking change — also needs guardian label (step 2b) |
| `none` | Docs / `.github` / `*.md` only — no release |

**Do not edit `package.json`** — version is computed from git tags and synced after stable release.

Wait for **`version-impact`** to pass. On success, **Publish PR pre-release** runs and comments with a preview version and `@pr-{N}`.

Full rules: [VERSIONING_POLICY.md](VERSIONING_POLICY.md).

### 2b. Major releases only

If **major** is selected:

1. Tech meeting agrees on the breaking change
2. Git guardian adds label **`version:major-approved`**
3. `version-impact` passes → pre-release preview updates
4. Merge only when green

## 3. QA — promote to testing

When the PR is ready for QA, add label **`ready-for-qa`**.

This triggers **Promote to testing** (squash-merge of the PR branch into `testing`). On success:

- A new commit lands on `testing`
- **Publish testing** runs → logs `{tag}-testing.{run}` / `@testing`
- A PR comment documents the testing version

QA consumers install: `pnpm add @lifestance/protos@testing` (see [CONSUMING.md](CONSUMING.md)).

For merge conflicts, parallel PRs, and recreating `testing`, see [TESTING_BRANCH.md](TESTING_BRANCH.md).

## 4. Stable release — merge to main

After QA passes, **squash-merge the PR to `main`** (PR branch unchanged up to this point).

On merge:

- **Publish stable release** computes the next semver from the latest tag + PR version impact
- Creates a git tag and GitHub Release (auto-generated notes)
- Syncs `package.json` on `main` via bot commit `[skip ci]`
- Comments on the merged PR

| Version impact | Result on merge |
|----------------|-----------------|
| `patch` / `minor` / `major` | Tag + release + `@latest` dry-run log |
| `none` | No tag, no release, no publish |

Then **recreate `testing` from `main`** in the GitHub branches UI and re-promote any remaining WIP PRs — see [TESTING_BRANCH.md](TESTING_BRANCH.md).

## 5. Docs-only PRs (`none`)

1. Change only allowlisted paths (`*.md`, `docs/**`, `.github/**`, etc.)
2. Check **none** under Version Impact
3. `version-impact` passes → pre-release skipped (PR comment explains)
4. Merge to `main` → stable release skipped (PR comment explains)
5. No `ready-for-qa` needed
