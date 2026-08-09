[![CI](https://github.com/paulte/tampermonkey-tools/actions/workflows/test.yml/badge.svg)](https://github.com/paulte/tampermonkey-tools/actions/workflows/test.yml)
[![CodeQL](https://github.com/paulte/tampermonkey-tools/actions/workflows/codeql.yml/badge.svg)](https://github.com/paulte/tampermonkey-tools/actions/workflows/codeql.yml)
[![Dependabot](https://img.shields.io/badge/dependencies-Dependabot-025E8C?logo=dependabot)](https://github.com/paulte/tampermonkey-tools/network/updates)
[![Release](https://img.shields.io/github/v/release/paulte/tampermonkey-tools)](https://github.com/paulte/tampermonkey-tools/releases)

# Purpose

Common tools to be used by all tampermonkey repos

Currently `scripts/createrelease.sh`

# Development and testing

Testing is present in a number of places

- pre-commit will check formatting, linting, and spelling before allowing a commit to be made
- CI will run the same precommit tests on any commit via github actions

In the background, github actions will perform the following:

- codeql will perform automated security analysis of the javascript code
- dependabot will monitor project dependencies and github actions for available updates

# Release process

Run one of the following depending on whether you want to bump he major, minor or patch version

```bash
scripts/create-release.sh  ( --major | --minor | --patch )
```

By default, `scripts/create-release.sh --patch` should be used

This process will perform a few tasks:

- Validate local git is up-to-date, on main and clean
- Run `pre-commit` and `npm run test` to ensure that the code is in a good state
- Create a new git tag
- Create a new release for the tag
- Push the tag to github
