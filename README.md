# Proto publish workflow — dry-run demo

Proof-of-concept repo for the approved `@lifestance/protos` collaboration model.

**No packages are published.** Workflows log what *would* happen on CodeArtifact and perform real git operations (PR comments, promote to `staging`, GitHub Releases on `main`).

**Versioning policy:** see [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md).

| Channel | Trigger | Would publish | Dist-tag |
|---------|---------|---------------|----------|
| PR / dev | PR push to `main` | `{next}-pr.{N}.{run}` (preview from PR version impact) | `@pr-{N}` |
| QA | Label `ready-for-qa` → merge to `staging` | `{latest}-staging.{run}` | `@staging` |
| Stable | Merge to `main` | `bump(latest tag, version impact)` | `@latest` |
| Docs / CI | Merge to `main` with impact `none` | skipped | — |

---

## Setup (5 min)

```bash
cd publish-workflow-demo
git init
git add .
git commit -m "Add proto publish workflow dry-run demo"
git remote add origin git@github.com:YOUR_ORG/proto-versioning-demo.git
git push -u origin main
```

1. Create labels in **Settings → Labels**:
   - **`ready-for-qa`** — promotes PR to staging
   - **`version:major-approved`** — git guardian approval for major bumps (see policy doc)
2. Enable **Settings → Actions → General → Workflow permissions: Read and write** (needed for promote, PR comments, and releases).
3. Enable branch protection on `main`:
   - Require status check **`version-impact`** before merge
4. Done — no AWS, no npm registry, no secrets.

---

## Versioning (summary)

Every PR targeting `main` must use the PR template and check **exactly one** box under **Version Impact**:

| Impact | Bump | Notes |
|--------|------|-------|
| `patch` | `x.y.Z+1` | Bug fixes |
| `minor` | `x.Y+1.0` | New backward-compatible features |
| `major` | `X+1.0.0` | Requires `version:major-approved` label |
| `none` | skip | Docs / `.github` / `*.md` only |

**Source of truth for bumps:** latest semver git tag on `main`. `package.json` is synced to match after each stable release.

Full rules: [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md).

---

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `version-impact.yml` | PR opened/updated → `main` | Required check — validates version impact; then chains **Publish PR pre-release** on success |
| `publish-pr.yml` | Called by `version-impact` (or manual dispatch) | Logs preview version + PR comment with `@pr-{N}` |
| `promote-to-staging.yml` | Label `ready-for-qa` or manual | Squash-merge PR into `staging` |
| `publish-staging.yml` | Push to `staging` | Logs `@staging` version + comments on the promoted PR |
| `publish-main.yml` | Push to `main` | Logs stable `@latest` (dry run) + creates GitHub Release (skipped when impact is `none`) |
| `reset-staging.yml` | Manual | Resets `staging` to match `main` |

Every workflow supports **Run workflow** for manual demo triggers.

---

## How to open and ship a PR

End-to-end flow for a proto change targeting `main`. The PR branch stays the canonical proposal for `main` — integration happens on `staging` only.

### 1. Create the branch and change

```bash
git fetch origin main
git checkout -b CM-123-add-match-rpc origin/main
# edit contracts/*.proto (or docs-only files)
git add .
git commit -m "feat(proto): add Match RPC (CM-123)"
git push -u origin CM-123-add-match-rpc
```

Open a PR → `main`. The template pre-fills the description.

### 2. Declare version impact

In the PR description, check **exactly one** box under **Version Impact**:

| Impact | When to use |
|--------|-------------|
| `patch` | Backward-compatible bug fix |
| `minor` | New backward-compatible capability |
| `major` | Breaking change — also needs guardian label (step 2b) |
| `none` | Docs / `.github` / `*.md` only — no release |

**Do not edit `package.json`** — version is computed from git tags and synced after stable release.

Wait for **`version-impact`** to pass. On success, **Publish PR pre-release** runs and comments with a preview version and `@pr-{N}`.

### 2b. Major releases only

If **major** is selected:

1. Tech meeting agrees on the breaking change
2. Git guardian adds label **`version:major-approved`**
3. `version-impact` passes → pre-release preview updates
4. Merge only when green

### 3. QA — promote to staging

When the PR is ready for QA, add label **`ready-for-qa`**.

This triggers **Promote to staging** (squash-merge of the PR branch into `staging`). On success:

- A new commit lands on `staging`
- **Publish staging** runs → logs `{tag}-staging.{run}` / `@staging`
- A PR comment documents the staging version

QA consumers install: `pnpm add @lifestance/protos-demo@staging`

### 4. Staging merge conflicts (PR stays as-is)

**Never merge `staging` into the PR branch.** The PR must remain a clean proposal for `main`.

Conflicts are resolved **on `staging` only** — either by the bot or manually when automated promote fails.

#### When automated promote fails

The PR may show a **Promote to staging — merge conflict** comment. The PR branch does not need to change.

**Recommended procedure (git guardian or developer with push access to `staging`):**

```bash
git fetch origin staging CM-123-add-match-rpc
git checkout staging
git pull origin staging

# bring PR changes into staging (same intent as the bot)
git merge --squash origin/CM-123-add-match-rpc

# resolve conflicts in contracts/*.proto ON STAGING — not on the PR branch
git add .
git commit -m "Promote PR #42 to staging: Add Match RPC (CM-123)"
git push origin staging
```

Use the real PR number and title in the commit message so **Publish staging** can comment on the PR.

After push:

- **Publish staging** runs automatically → new `@staging` version
- The open PR toward `main` is unchanged

#### Parallel PRs on staging

Multiple PRs can be promoted to `staging`. The second promote may conflict if protos overlap — use the manual procedure above. For simpler operations, promote and release **one PR at a time**, then recreate `staging` (see below).

### 5. Recreate `staging` and re-promote WIP PRs

Use this after a stable release to `main`, when abandoning the current QA batch, or when `staging` history is too messy to fix with a simple merge.

**Important:** deleting and recreating `staging` wipes all integrated QA commits. Open PR branches are **not** modified. Any PR that still needs QA must be promoted onto the new `staging` again — the `ready-for-qa` label alone does **not** re-run promotion.

#### Step 1 — Recreate `staging` in the GitHub branches UI

Do this in the repository on GitHub (**Code → branches**), not by merging `staging` into PRs.

1. Open **Branches** (or **Code** → branch dropdown → **View all branches**).
2. Find **`staging`** → **Delete branch** (confirm).
3. Create a new branch:
   - Name: `staging`
   - Source: **`main`** (latest)
4. Push/create the branch so `origin/staging` exists and matches `main`.

A push to the new `staging` triggers **Publish staging** → `@staging` reflects the current `main` baseline until WIP PRs are re-promoted.

> The **Reset staging from main** workflow is an alternative git reset of the existing branch. For this documented procedure, prefer **delete + recreate from `main`** in the GitHub UI.

#### Step 2 — Identify WIP PRs still in QA

In GitHub, filter open PRs targeting `main` with label **`ready-for-qa`**.

These are the PRs that should go back onto `staging`. There are usually only a few on the real protos package — re-promote them **one at a time** in a sensible order (e.g. oldest first, or by team agreement).

The `ready-for-qa` label does not need to be removed and re-added if you promote manually (step 3). Optionally re-add the label later if you want the bot to retry for a single PR.

#### Step 3 — Manually promote each WIP PR onto `staging` (local)

**Never merge `staging` into the PR branch.** Repeat the following for each open PR that still needs QA, without changing the PR branch itself.

Replace `42`, `CM-123-add-match-rpc`, and the title with the real PR number, branch name, and title.

```bash
git fetch origin staging CM-123-add-match-rpc
git checkout staging
git pull origin staging

git merge --squash origin/CM-123-add-match-rpc

# If conflicts: resolve in contracts/*.proto ON STAGING only
git add .
git commit -m "Promote PR #42 to staging: Add Match RPC (CM-123)"
git push origin staging
```

After each push:

- **Publish staging** runs → new `{tag}-staging.{run}` / `@staging`
- Use the `Promote PR #N to staging: …` commit message so the workflow can comment on the correct PR

If the next WIP PR conflicts with what is already on `staging`, resolve on **`staging`** again — do not update the PR branch to absorb `staging`.

#### Step 4 — Continue normal flow

When QA passes for a PR, squash-merge that PR to `main` (section 6). After all relevant releases, recreate `staging` from `main` again to start the next QA cycle.

### 6. Stable release — merge to main

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

Then **recreate `staging` from `main`** in the GitHub branches UI and re-promote any remaining WIP PRs (section 5).

### 7. Docs-only PRs (`none`)

1. Change only allowlisted paths (`*.md`, `docs/**`, `.github/**`, etc.)
2. Check **none** under Version Impact
3. `version-impact` passes → pre-release skipped (PR comment explains)
4. Merge to `main` → stable release skipped (PR comment explains)
5. No `ready-for-qa` needed

### Quick reference

```text
PR opened → version-impact + @pr-{N} preview
    ↓
ready-for-qa → staging (@staging)     ← conflicts fixed on staging, not PR
    ↓
QA pass → squash-merge PR → main (@latest + GitHub Release)
    ↓
delete + recreate staging from main (GitHub UI) → re-promote WIP PRs locally (one by one)
```

---

## What to look for in logs

Each publish job prints a banner and writes a **Job summary**:

```text
╔══════════════════════════════════════════════════════════════╗
║  DRY RUN — no package published                              ║
╠══════════════════════════════════════════════════════════════╣
║  Channel:   PR
║  Package:   @lifestance/protos-demo
║  Version:   1.3.0-pr.3.7
║  Dist-tag:  pr-3
╚══════════════════════════════════════════════════════════════╝
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `publish-pr` not running | Runs only after **`version-impact`** succeeds; label-only events skip publish |
| `publish-pr` fails | `version-impact` passed but PR body could not be parsed — check exactly one **Version Impact** box |
| `version-impact` fails: missing selection | Check exactly one box under **Version Impact** |
| `version-impact` fails: multiple selections | Uncheck extras — only one of patch / minor / major / none |
| `version-impact` fails: major | Git guardian adds `version:major-approved` |
| `version-impact` fails: none + proto file | Change impact to patch/minor/major, or restrict PR to allowlisted paths |
| `Invalid package.json` / `ERR_INVALID_PACKAGE_CONFIG` | Remove `//` comments from `package.json`; never edit `version` manually |
| No PR comment | Check workflow has `pull-requests: write`; bot comments are upserted (one per topic) |
| Promote failed / conflict | Resolve on **`staging`** locally — see [Staging merge conflicts](#4-staging-merge-conflicts-pr-stays-as-is). Do **not** merge `staging` into the PR. |
| Promote does nothing | Label must be exactly `ready-for-qa`; PR must target `main` |
| Release failed: tag exists | A release with that version already exists — check latest tag |
| Staging out of date / after release | Recreate `staging` from `main` in GitHub branches UI — see [Recreate staging](#5-recreate-staging-and-re-promote-wip-prs) |
| `ready-for-qa` but not on staging after recreate | Re-promote manually onto `staging` (label does not auto-retrigger) |

---

## After the demo

If the flow is approved, copy workflows into `cm_protos` and replace `scripts/publish.sh` with real CodeArtifact publish in production only. Keep [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md) as the team reference.
