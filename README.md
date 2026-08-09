[![CI](https://github.com/paulte/tampermonkey-tools/actions/workflows/test.yml/badge.svg)](https://github.com/paulte/tampermonkey-tools/actions/workflows/test.yml)
[![CodeQL](https://github.com/paulte/tampermonkey-tools/actions/workflows/codeql.yml/badge.svg)](https://github.com/paulte/tampermonkey-tools/actions/workflows/codeql.yml)
[![Dependabot](https://img.shields.io/badge/dependencies-Dependabot-025E8C?logo=dependabot)](https://github.com/paulte/tampermonkey-tools/network/updates)
[![Release](https://img.shields.io/github/v/release/paulte/tampermonkey-tools)](https://github.com/paulte/tampermonkey-tools/releases)

# Purpose

Shared tooling for developing and releasing Tampermonkey userscripts.

This repository is intended to be included as a git submodule by userscript
repositories.

## Usage

From a userscript repository:

```bash
tools/tampermonkey-tools/scripts/create-release.sh  ( --major | --minor | --patch )

will create a new tag and releast at the next available version
```
