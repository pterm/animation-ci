#!/bin/bash

set -e

REPO_FULLNAME=$(jq -r ".repository.full_name" "$GITHUB_EVENT_PATH")

echo "## Initializing git repo..."
git init
echo "### Adding git remote..."
git remote add origin https://x-access-token:$ACCESS_TOKEN@github.com/$REPO_FULLNAME.git
echo "### Getting branch"
BRANCH=${GITHUB_REF#*refs/heads/}

if [[ $BRANCH == refs/tags* ]]; then
  echo "## The push was a tag, aborting!"
  exit
fi

echo "### git fetch $BRANCH ..."
git fetch origin $BRANCH
echo "### Branch: $BRANCH (ref: $GITHUB_REF )"
git checkout $BRANCH

echo "## Login into git..."
git config --global user.email "git@marvinjwendt.com"
git config --global user.name "MarvinJWendt"

echo "## Ignore workflow files (we may not touch them)"
git update-index --assume-unchanged .github/workflows/*

echo "## Getting git tags..."
git fetch --tags

echo "## Go env"
go env

echo "## Downloading go modules..."
go get

echo "## Installing svg-term..."
npm install -g svg-term-cli

echo "# Running CI System"
go run ./ci

echo "## Generating changelog..."
go install github.com/git-chglog/git-chglog/cmd/git-chglog@latest || true
/root/go/bin/git-chglog -o CHANGELOG.md || true

echo "## Go mod tidy..."
go mod tidy

echo "## Go fmt..."
go fmt ./...

echo "## Staging changes..."
git add .
echo "## Commiting files..."
git commit -m "docs: autoupdate" || exit 0
echo "## Pushing to $BRANCH"
git push -u origin $BRANCH || exit 0
