# Setup

Initial repository configuration for the dry-run demo (~5 min).

```bash
cd publish-workflow-demo
git init
git add .
git commit -m "Add proto publish workflow dry-run demo"
git remote add origin git@github.com:YOUR_ORG/proto-versioning-demo.git
git push -u origin main
```

## GitHub settings

1. Create labels in **Settings → Labels**:
   - **`ready-for-qa`** — promotes PR to testing
   - **`version:major-approved`** — git guardian approval for major bumps (see [VERSIONING_POLICY.md](VERSIONING_POLICY.md))
2. Enable **Settings → Actions → General → Workflow permissions: Read and write** (needed for promote, PR comments, and releases).
3. Enable branch protection on `main`:
   - Require status check **`version-impact`** before merge
4. Create branch **`testing`** from `main` (if it does not exist yet).

No AWS, no npm registry, and no secrets are required for the demo.

## Next steps

- [Ship a PR](SHIPPING_A_PR.md) — end-to-end contributor flow
- [Workflows](WORKFLOWS.md) — what each GitHub Action does
- [Troubleshooting](TROUBLESHOOTING.md) — common failures
