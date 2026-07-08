# Troubleshooting

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
| Promote failed / conflict | Resolve on **`testing`** locally — see [Testing branch — merge conflicts](TESTING_BRANCH.md#merge-conflicts-pr-stays-as-is). Do **not** merge `testing` into the PR. |
| Promote does nothing | Label must be exactly `ready-for-qa`; PR must target `main` |
| Release failed: tag exists | A release with that version already exists — check latest tag |
| Testing out of date / after release | Recreate `testing` from `main` in GitHub branches UI — see [Recreate testing](TESTING_BRANCH.md#recreate-testing-and-re-promote-wip-prs) |
| `ready-for-qa` but not on testing after recreate | Re-promote manually onto `testing` (label does not auto-retrigger) |

## Related docs

- [Workflows](WORKFLOWS.md) — trigger and behavior reference
- [Ship a PR](SHIPPING_A_PR.md) — expected contributor flow
- [VERSIONING_POLICY.md](VERSIONING_POLICY.md) — version impact rules
