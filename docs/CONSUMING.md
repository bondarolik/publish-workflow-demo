# Consuming `@lifestance/protos`

How downstream apps (e.g. `web-bff`) install the package from CodeArtifact using dist-tags vs semver pins.

**Mental model** (dist-tags vs pins): see [README](../README.md#mental-model).

## Channel reference

| Channel | Install | Use when |
|---------|---------|----------|
| PR preview | `pnpm add @lifestance/protos@pr-42` | Local dev / trying a specific proto PR |
| QA | `pnpm add @lifestance/protos@testing` | QA or pre-prod services validating integrated protos |
| Stable | `pnpm add @lifestance/protos@latest` | After release — or pin exact version in prod (below) |

## Production

On production `main` (e.g. `web-bff`), prefer an **exact semver pin**, not a moving tag:

```json
"@lifestance/protos": "1.30.9"
```

Bump that number after proto QA passes and a stable release ships. Do not leave `"testing"` on production `main`.

## `package.json` overrides (dist-tags)

You can set the dependency version to a **dist-tag name**. The registry resolves it at install time (see `pnpm-lock.yaml` for the resolved version).

### PR preview — test proto PR #42 before merge

```json
"dependencies": {
  "@lifestance/protos": "pr-42"
}
```

```bash
pnpm add @lifestance/protos@pr-42
```

### QA / testing channel — follow integrated protos on `testing`

```json
"dependencies": {
  "@lifestance/protos": "testing"
}
```

```bash
pnpm add @lifestance/protos@testing
```

Re-run `pnpm update @lifestance/protos` (or `@testing`) in QA deploys when a new testing publish lands.

### Stable / latest — newest production release

```json
"dependencies": {
  "@lifestance/protos": "latest"
}
```

```bash
pnpm add @lifestance/protos@latest
```

For reproducible production builds, resolve `latest` once, then **pin the semver** (e.g. `"1.31.0"`) in `package.json` and commit the lockfile.
