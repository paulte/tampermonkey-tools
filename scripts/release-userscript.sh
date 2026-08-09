#!/usr/bin/env bash
set -euo pipefail

PROJECT_TYPE="generic"

show_help() {
  cat <<EOF
Usage:
  $0 [option]

Create and push a new release tag.

Options:
  --major     Increment major version (v1.2.3 -> v2.0.0)
  --minor     Increment minor version (v1.2.3 -> v1.3.0)
  --patch     Increment patch version (v1.2.3 -> v1.2.4)

Recommended:
  $0 --patch
EOF
}

checkargs() {
  if [[ $# -ne 1 ]]; then
    show_help
    exit 1
  fi

  case "$1" in
  --major | --minor | --patch)
    BUMP="$1"
    ;;
  *)
    show_help
    exit 1
    ;;
  esac
}

detectprojecttype() {
  if git ls-files | grep -qE '^src/.*\.user\.js$'; then
    PROJECT_TYPE="userscript"
  fi

  echo "Project type: ${PROJECT_TYPE}"
}

gitmustbecleanordie() {
  if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "ERROR: Not on main"
    exit 1
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: Working tree is not clean"
    git status --short
    exit 1
  fi
}

refreshgit() {
  git pull --ff-only
  git fetch --tags --prune
}

performtests() {
  if command -v pre-commit &>/dev/null; then
    pre-commit run --all-files --show-diff-on-failure
  else
    echo "pre-commit not installed - skipping"
  fi

  if [[ -f package.json ]]; then
    if command -v npm &>/dev/null; then
      npm test
    else
      echo "npm not installed - skipping npm test"
    fi
  fi
}

findlatesttag() {
  LATEST=$(git tag --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1 || true)

  if [[ -z "$LATEST" ]]; then
    echo "No valid release tags found. Defaulting to v1.0.0"
    LATEST="v1.0.0"
  fi

  if [[ ! "$LATEST" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "ERROR: Invalid latest release tag: $LATEST"
    exit 1
  fi

  MAJOR="${BASH_REMATCH[1]}"
  MINOR="${BASH_REMATCH[2]}"
  PATCH="${BASH_REMATCH[3]}"
}

evaluatenextversion() {
  case "$BUMP" in
  --major)
    ((MAJOR++))
    MINOR=0
    PATCH=0
    ;;
  --minor)
    ((MINOR++))
    PATCH=0
    ;;
  --patch)
    ((PATCH++))
    ;;
  esac

  RELEASE="v${MAJOR}.${MINOR}.${PATCH}"

  echo
  echo "Latest release: $LATEST"
  echo "New release:    $RELEASE"
  echo

  read -r -p "Create this release? [y/N] " CONFIRM

  if [[ "$CONFIRM" != "y" ]]; then
    echo "Cancelled"
    exit 0
  fi

  if git rev-parse "$RELEASE" >/dev/null 2>&1; then
    echo "ERROR: Tag already exists locally"
    exit 1
  fi

  if git ls-remote --exit-code --tags origin "refs/tags/$RELEASE" >/dev/null 2>&1; then
    echo "ERROR: Tag already exists remotely"
    exit 1
  fi
}

finduserscript() {
  local files

  files=$(git ls-files | grep -E '^src/.*\.user\.js$' || true)

  if [[ -z "$files" ]]; then
    echo "ERROR: No userscript found under src/"
    exit 1
  fi

  if [[ $(echo "$files" | wc -l | tr -d ' ') -ne 1 ]]; then
    echo "ERROR: Multiple userscripts found:"
    echo "$files"
    exit 1
  fi

  SRCFILENAME="$files"
  SHORTSRCFILENAME=$(basename "$SRCFILENAME")

  grep -q '^// ==UserScript==' "${SRCFILENAME}" || {
    echo "ERROR: ${SRCFILENAME} does not look like a userscript"
    exit 1
  }

  echo "Using userscript: ${SRCFILENAME}"
}

createdistversion() {
  DSTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z")
  RELEASENUMBER="${RELEASE#v}"

  grep -Ev '^//.*@(version|released)' "${SRCFILENAME}" |
    awk -v release="$RELEASENUMBER" -v dstamp="$DSTAMP" '
    /\/\/ @name[[:space:]]/ {
      print
      print "// @version      " release
      print "// @released     " dstamp
      next
    }
    { print }
    ' > "${SHORTSRCFILENAME}"
}

updatepackagejson() {
  if [[ -f package.json ]]; then
    npm version "${RELEASE#v}" --no-git-tag-version
  fi
}

prepare_release() {
  if [[ "$PROJECT_TYPE" == "userscript" ]]; then
    finduserscript
    createdistversion
    updatepackagejson
  fi
}

createtagandpush() {
  git add -A

  git commit -m "Release ${RELEASE}"

  git push origin main

  git tag -a "$RELEASE" -m "Release $RELEASE"

  git push origin "$RELEASE"

  if [[ "$PROJECT_TYPE" == "userscript" ]]; then
    gh release create "$RELEASE" \
      "${SHORTSRCFILENAME}" \
      --title "$RELEASE" \
      --notes "Release $RELEASE"
  else
    gh release create "$RELEASE" \
      --title "$RELEASE" \
      --notes "Release $RELEASE"
  fi

  echo "Released $RELEASE"
}


REPOROOT=$(git rev-parse --show-toplevel)
cd "$REPOROOT"

checkargs "$@"
detectprojecttype
gitmustbecleanordie
refreshgit
performtests
gitmustbecleanordie
findlatesttag
evaluatenextversion
prepare_release
createtagandpush
