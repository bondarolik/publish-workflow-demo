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

Every PR targeting `main` must select **Version impact** in the PR template dropdown:

| Impact | Bump | Notes |
|--------|------|-------|
| `patch` | `x.y.Z+1` | Bug fixes |
| `minor` | `x.Y+1.0` | New backward-compatible features |
| `major` | `X+1.0.0` | Requires `version:major-approved` label |
| `none` | skip | Docs / `.github` / `*.md` only |

**Source of truth:** latest semver git tag on `main` (not `package.json`).

Full rules: [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md).

---

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `version-impact.yml` | PR opened/updated → `main` | Required check — validates version impact + `none` paths + major label |
| `publish-pr.yml` | PR opened/updated → `main` | Logs preview version + PR comment with `@pr-{N}` |
| `promote-to-staging.yml` | Label `ready-for-qa` or manual | Squash-merge PR into `staging` |
| `publish-staging.yml` | Push to `staging` | Logs `@staging` version |
| `publish-main.yml` | Push to `main` | Logs stable `@latest` (dry run) + creates GitHub Release (skipped when impact is `none`) |
| `reset-staging.yml` | Manual | Resets `staging` to match `main` |

Every workflow supports **Run workflow** for manual demo triggers.

---

## Live demo script (~10 min)

### Scene 1 — PR channel

1. `git checkout -b CM-123-add-rpc`
2. Edit `contracts/demo.proto`
3. Open PR → `main` — select **minor** in Version impact dropdown
4. Show **`version-impact`** check passing
5. Show **Publish PR pre-release** in Actions:
   - Job log banner: `DRY RUN — would publish … @pr-{N}`
   - Preview version e.g. `1.3.0-pr.3.7` (next minor from latest tag)
   - PR comment with version string

### Scene 2 — QA / staging channel

1. Add label **`ready-for-qa`** on the PR
2. Show **Promote to staging** → new squash commit on `staging`
3. Show **Publish staging** triggered by push:
   - Log: `1.2.0-staging.{run}` / `@staging`

### Scene 3 — Stable release

1. Squash-merge PR to `main` (version impact **minor** selected in PR)
2. Show **Publish stable release**:
   - Log: would publish `@latest` (dry run — no CodeArtifact)
   - Creates git tag e.g. `1.3.0` and a GitHub Release with auto-generated notes
3. Run **Reset staging from main** (manual)

### Scene 4 — Docs-only (none)

1. Open PR that only changes `README.md` or `.github/**`
2. Select **none** in Version impact
3. Show **`version-impact`** passes; **Publish PR** comments that pre-release is skipped
4. Merge → **Publish stable release** skips tag and release

### Scene 5 — Major (optional)

1. Open PR with breaking proto change; select **major**
2. Show **`version-impact`** fails until guardian adds **`version:major-approved`**
3. After label + merge → tag `2.0.0`

### Scene 6 — Parallel PRs

1. Open a second PR with different version impact
2. Both get their own `@pr-{N}` preview versions
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
║  Version:   1.3.0-pr.3.7
║  Dist-tag:  pr-3
╚══════════════════════════════════════════════════════════════╝
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `version-impact` fails: missing dropdown | Fill **Version impact** in the PR template |
| `version-impact` fails: major | Git guardian adds `version:major-approved` |
| `version-impact` fails: none + proto file | Change impact to patch/minor/major, or restrict PR to allowlisted paths |
| No PR comment | Check workflow has `pull-requests: write` |
| Promote does nothing | Label must be exactly `ready-for-qa`; PR must target `main` |
| Release failed: tag exists | A release with that version already exists — check latest tag |
| Staging out of date | Run **Reset staging from main** |

---

## After the demo

If the flow is approved, copy workflows into `cm_protos` and replace `scripts/publish.sh` with real CodeArtifact publish in production only. Keep [docs/VERSIONING_POLICY.md](docs/VERSIONING_POLICY.md) as the team reference.
