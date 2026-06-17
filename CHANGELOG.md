# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-06-17
### Fixed
- Fail fast (`required`) when `url` is unset. Previously a missing `url`
  rendered a valid-but-broken crontab line (`wget` with no URL), so the pod
  looked healthy while cron silently never fired.

## [1.0.0] - 2021-11-19
### Added
- Initial release.
