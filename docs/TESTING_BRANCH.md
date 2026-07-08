# Testing branch — conflicts, parallel PRs, recreate

The `testing` branch is the QA integration line. **Never merge `testing` into a PR branch.** The PR must remain a clean proposal for `main`. Conflicts are resolved **on `testing` only**.

## Merge conflicts (PR stays as-is)

Conflicts are resolved on `testing` — either by the bot or manually when automated promote fails.

### When automated promote fails

The PR may show a **Promote to testing — merge conflict** comment. The PR branch does not need to change.

**Recommended procedure (git guardian or developer with push access to `testing`):**

```bash
git fetch origin testing CM-123-add-match-rpc
git checkout testing
git pull origin testing

# bring PR changes into testing (same intent as the bot)
git merge --squash origin/CM-123-add-match-rpc

# resolve conflicts in contracts/*.proto ON TESTING — not on the PR branch
git add .
git commit -m "Promote PR #42 to testing: Add Match RPC (CM-123)"
git push origin testing
```

Use the real PR number and title in the commit message so **Publish testing** can comment on the PR.

After push:

- **Publish testing** runs automatically → new `@testing` version
- The open PR toward `main` is unchanged

## Parallel PRs on testing

Multiple PRs can be promoted to `testing`. The second promote may conflict if protos overlap — use the manual procedure above.

**Recommended for small teams:** promote and release **one PR at a time**, then recreate `testing` (below). This avoids stacking conflicts and keeps QA scope clear.

## Recreate `testing` and re-promote WIP PRs

Use this after a stable release to `main`, when abandoning the current QA batch, or when `testing` history is too messy to fix with a simple merge.

**Important:** deleting and recreating `testing` wipes all integrated QA commits. Open PR branches are **not** modified. Any PR that still needs QA must be promoted onto the new `testing` again — the `ready-for-qa` label alone does **not** re-run promotion.

### Step 1 — Recreate `testing` in the GitHub branches UI

Do this in the repository on GitHub (**Code → branches**), not by merging `testing` into PRs.

1. Open **Branches** (or **Code** → branch dropdown → **View all branches**).
2. Find **`testing`** → **Delete branch** (confirm).
3. Create a new branch:
   - Name: `testing`
   - Source: **`main`** (latest)
4. Push/create the branch so `origin/testing` exists and matches `main`.

A push to the new `testing` triggers **Publish testing** → `@testing` reflects the current `main` baseline until WIP PRs are re-promoted.

> The **Reset testing from main** workflow is an alternative git reset of the existing branch. For this documented procedure, prefer **delete + recreate from `main`** in the GitHub UI.

### Step 2 — Identify WIP PRs still in QA

In GitHub, filter open PRs targeting `main` with label **`ready-for-qa`**.

These are the PRs that should go back onto `testing`. Re-promote them **one at a time** in a sensible order (e.g. oldest first, or by team agreement).

The `ready-for-qa` label does not need to be removed and re-added if you promote manually (step 3). Optionally re-add the label later if you want the bot to retry for a single PR.

### Step 3 — Manually promote each WIP PR onto `testing` (local)

**Never merge `testing` into the PR branch.** Repeat the following for each open PR that still needs QA, without changing the PR branch itself.

Replace `42`, `CM-123-add-match-rpc`, and the title with the real PR number, branch name, and title.

```bash
git fetch origin testing CM-123-add-match-rpc
git checkout testing
git pull origin testing

git merge --squash origin/CM-123-add-match-rpc

# If conflicts: resolve in contracts/*.proto ON TESTING only
git add .
git commit -m "Promote PR #42 to testing: Add Match RPC (CM-123)"
git push origin testing
```

After each push:

- **Publish testing** runs → new `{tag}-testing.{run}` / `@testing`
- Use the `Promote PR #N to testing: …` commit message so the workflow can comment on the correct PR

If the next WIP PR conflicts with what is already on `testing`, resolve on **`testing`** again — do not update the PR branch to absorb `testing`.

### Step 4 — Continue normal flow

When QA passes for a PR, squash-merge that PR to `main` ([Ship a PR](SHIPPING_A_PR.md#4-stable-release--merge-to-main)). After all relevant releases, recreate `testing` from `main` again to start the next QA cycle.
