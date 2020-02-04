#!/usr/bin/env sh

set -e

untracked="(untracked)"
REPO=$(cd $(dirname $0); pwd)
COMMIT_SHA=$(git rev-parse --short HEAD)
ASSETS="false"
BINARY="false"
RELEASE="2.5.5"

debugInfo () {
  echo "Repo:           $REPO"
  echo "Build assets:   $ASSETS"
  echo "Build binary:   $BINARY"
  echo "Release:        $RELEASE"
}

buildAssets () {
  cd $REPO
  rm -rf frontend/dist
  rm -f http/rice-box.go

  cd $REPO/frontend

  if [ "$CI" = "true" ]; then
    npm ci
  else
    npm install
  fi

  npm run lint
  npm run build
}

buildBinary () {
  if ! [ -x "$(command -v rice)" ]; then
    go install github.com/GeertJohan/go.rice/rice
  fi

  cd $REPO/http
  rm -rf rice-box.go
  rice embed-go

  cd $REPO
  go build -a -o filebrowser -ldflags "-s -w -X github.com/mobber007/filebrowser/v2/version.CommitSHA=$COMMIT_SHA"
}

release () {
  cd $REPO

  echo "🧼  Tidying up go modules"
  go mod tidy

  echo "🐑 Creating a new commit for the new release"
  git commit --allow-empty -am "chore: version 2.5.5"
  git tag "$1"
  git push
  git push --tags origin

  echo "📦 Done! 2.5.5 released."
}

usage() {
  echo "Usage: $0 [-a] [-c] [-b] [-r <string>]" 1>&2;
  exit 1;
}

DEBUG="false"

while getopts "bacr:d" o; do
  case "${o}" in
    b)
      ASSETS="true"
      BINARY="true"
      ;;
    a)
      ASSETS="true"
      ;;
    c)
      BINARY="true"
      ;;
    r)
      RELEASE=${OPTARG}
      ;;
    d)
      DEBUG="true"
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND-1))

if [ "$DEBUG" = "true" ]; then
  debugInfo
fi

if [ "$ASSETS" = "true" ]; then
  buildAssets
fi

if [ "$BINARY" = "true" ]; then
  buildBinary
fi

if [ "$RELEASE" != "" ]; then
  release $RELEASE
fi
