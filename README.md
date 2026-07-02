# Proto publish workflow — dry-run demo

Proof-of-concept repo for the approved `@lifestance/protos` collaboration model.

**No packages are published.** Workflows log what *would* happen on CodeArtifact and perform real git operations (PR comments, promote to `staging`, GitHub Releases on `main`).

| Channel | Trigger | Would publish | Dist-tag |
|---------|---------|---------------|----------|
| PR / dev | PR push to `main` | `1.0.0-pr.{N}.{run}` | `@pr-{N}` |
| QA | Label `ready-for-qa` → merge to `staging` | `1.0.0-staging.{run}` | `@staging` |
| Stable | Merge to `main` | `1.0.0` → `1.1.0` … | `@latest` |

---

## Setup (5 min)

```bash
cd publish-workflow-demo
git init
git add .
git commit -m "Add proto workflow dry-run demo"
git remote add origin git@github.com:YOUR_ORG/proto-versioning-demo.git
git push -u origin main
```

1. Create label **`ready-for-qa`** in the repo (Settings → Labels).
2. Enable **Settings → Actions → General → Workflow permissions: Read and write** (needed for promote + PR comments).
3. Done — no AWS, no npm registry, no secrets.

---

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `publish-pr.yml` | PR opened/updated → `main` | Logs + PR comment with `@pr-{N}` version |
| `promote-to-staging.yml` | Label `ready-for-qa` or manual | Squash-merge PR into `staging` |
| `publish-staging.yml` | Push to `staging` | Logs `@staging` version |
| `publish-main.yml` | Push to `main` | Logs stable `@latest` (dry run) + creates GitHub Release with auto-generated notes |
| `reset-staging.yml` | Manual | Resets `staging` to match `main` |

Every workflow supports **Run workflow** for manual demo triggers.

---

## Live demo script (~10 min)

### Scene 1 — PR channel

1. `git checkout -b feature/add-rpc`
2. Edit `contracts/demo.proto`
3. Open PR → `main`
4. Show **Publish PR pre-release** in Actions:
   - Job log banner: `DRY RUN — would publish … @pr-{N}`
   - PR comment with version string

### Scene 2 — QA / staging channel

1. Add label **`ready-for-qa`** on the PR
2. Show **Promote to staging** → new squash commit on `staging`
3. Show **Publish staging** triggered by push:
   - Log: `1.0.0-staging.{run}` / `@staging`

### Scene 3 — Stable release

1. Bump `package.json` version in the PR (`1.0.0` → `1.1.0`)
2. Squash-merge PR to `main`
3. Show **Publish stable release**:
   - Log: would publish `@latest` (dry run — no CodeArtifact)
   - Creates git tag `1.1.0` and a GitHub Release with auto-generated notes (merged PRs)
4. Run **Reset staging from main** (manual)

### Scene 4 — Parallel PRs

1. Open a second PR
2. Both get their own `@pr-{N}` notifications
3. Promote both to `staging` — show merge conflict if they touch the same file

---

## What to look for in logs

Each publish job prints a banner and writes a **Job summary**:

```text
╔══════════════════════════════════════════════════════════════╗
║  DRY RUN — no package published                              ║
╠══════════════════════════════════════════════════════════════╣
║  Channel:   PR
║  Package:   @lifestance/protos-demo
║  Version:   1.0.0-pr.3.7
║  Dist-tag:  pr-3
╚══════════════════════════════════════════════════════════════╝
```
