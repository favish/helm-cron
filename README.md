# helm-cron

Helm chart for a minimal pod that triggers Drupal cron on a schedule by
`wget`-ing a site's public `/cron/<token>` URL from a crontab entry. Used by
favish Drupal projects as a lightweight cron trigger.

Published to `https://favish.github.io/helm-cron` and consumed as a chart
dependency.

> **Superseded for high-traffic projects.** Triggering cron over the public URL
> routes the request to the serving php fleet. Projects where cron is heavy
> (search indexing, feed imports, purges) should instead use the dedicated
> `cron-worker` in [helm-drupal](https://github.com/favish/helm-drupal), which
> runs `drush cron` on its own pod with no impact on the serving HPA. This chart
> remains valid for lightweight cron needs.

## Contents

- [What it deploys](#what-it-deploys)
- [Layout](#layout)
- [Usage](#usage)
- [Key values](#key-values)
- [Releasing](#releasing)
- [Local checks](#local-checks)
- [Conventions (agents & contributors)](#conventions-agents--contributors)
- [Pending improvements](#pending-improvements)

## What it deploys

A single-replica `Deployment` running the `favish/cron-drupal` image, with a
`ConfigMap` that renders one crontab line:

```
<period> date -R && echo 'Running Drupal cron via wget...' && wget -O - -q -t 1 <url>
```

`url` is required when the chart is enabled (a missing `url` now fails the render
fast instead of shipping a silently-broken crontab).

## Layout

```
cron/                            # the chart
├── Chart.yaml                   # metadata (version injected at release time)
├── values.yaml                  # defaults
└── templates/
    ├── deployment.yaml
    └── configmap.yaml           # the crontab line
.github/workflows/release.yml    # tag -> publish chart
CHANGELOG.md
```

## Usage

Declare the dependency in the consuming umbrella chart:

```yaml
dependencies:
  - name: cron
    repository: https://favish.github.io/helm-cron
    version: 1.0.2
    condition: cron.enabled
```

Values:

```yaml
cron:
  enabled: true
  period: "*/10 * * * *"                       # crontab schedule
  url: "https://cms.example.com/cron/<token>"  # required when enabled
```

## Key values

| Value | Default | Meaning |
|-------|---------|---------|
| `url` | — (required) | Drupal cron URL to hit. Render fails if unset while enabled. |
| `period` | `*/10 * * * *` | Crontab schedule. |
| `resources` | requests only | Container resources. |

## Releasing

GitHub Actions (`.github/workflows/release.yml`). Merge to `master`, update
`CHANGELOG.md`, then tag:

```bash
git tag 1.0.3 && git push origin 1.0.3
```

The workflow packages the chart and publishes to the `gh-pages` Helm repo.
`workflow_dispatch` runs a dry-run. Migrated from CircleCI;
`actions/checkout` uses the built-in `GITHUB_TOKEN`, no deploy key.

## Local checks

```bash
helm lint ./cron --set url=https://example.com/cron

cp cron/Chart.yaml /tmp/c.bak
printf '\nversion: 0.0.0-test\n' >> cron/Chart.yaml
helm template t ./cron --set url=https://example.com/cron
helm template t ./cron            # expect: error, url required
cp /tmp/c.bak cron/Chart.yaml
```

## Conventions (agents & contributors)

- Chart `version` is injected from the git tag at release; not in `Chart.yaml`.
- Release = push a git tag. No manual gh-pages step.
- For heavy cron workloads, prefer the helm-drupal `cron-worker` over this chart.

## Pending improvements

- No resource `limits` (only requests) and no liveness/readiness probe — a cron
  target that is failing leaves a Running-but-useless pod with no signal.
- The image tag (`favish/cron-drupal:1.0.0-alpha.1`) is a hardcoded pre-release
  pin in the template; move repo/tag to values and pin a stable release.
- `wget -q -t 1` swallows failures; drop `-q` so failures surface in pod logs for
  log-based alerting.
- No `securityContext`; the pod runs as the image default.
