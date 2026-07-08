# Workflows

Every workflow supports **Run workflow** for manual demo triggers.

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `version-impact.yml` | PR opened/updated → `main` | Required check — validates version impact; then chains **Publish PR pre-release** on success |
| `publish-pr.yml` | Called by `version-impact` (or manual dispatch) | Logs preview version + PR comment with `@pr-{N}` |
| `promote-to-testing.yml` | Label `ready-for-qa` or manual | Squash-merge PR into `testing` |
| `publish-testing.yml` | Push to `testing` | Logs `@testing` version + comments on the promoted PR |
| `publish-main.yml` | Push to `main` | Logs stable `@latest` (dry run) + creates GitHub Release (skipped when impact is `none`) |
| `reset-testing.yml` | Manual | Resets `testing` to match `main` |

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

## Related docs

- [Ship a PR](SHIPPING_A_PR.md) — when each workflow runs in the contributor flow
- [Testing branch](TESTING_BRANCH.md) — conflicts, parallel PRs, recreate `testing`
- [Troubleshooting](TROUBLESHOOTING.md) — workflow failures
