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

# Start release

echo "## Getting git tags..."
git fetch --tags

echo "## Downloading go modules..."
go get

echo "## Installing dops..."
go install

echo "## Installing svg-term..."
npm install -g svg-term-cli

echo "## Generating animations..."
echo "Working in directoy $(pwd)"

echo "Changing directory to '_examples'"
cd _examples || exit
echo "Now in: $(pwd)"
echo ""
echo "Processing all examples..."
for D in `find .  -mindepth 1 -maxdepth 1 -type d -printf "%f\n"`
do
    echo "Switching to direcory $D"
    cd "$D" || exit

    echo "  Processing $(pwd)..."

    rm ./animation_data.json || true
    rm ./animation.svg || true

    asciinema rec ./animation_data.json -c "go run ."
    echo '[5, "o", "\r\nrestarting...\r\n"]' >> ./animation_data.json
    svg-term --in ./animation_data.json --out ./animation.svg

    echo "# $D" > README.md
    echo "" >> README.md
    echo "![Animation](animation.svg)" >> README.md
    rm ./animation_data.json
    cd .. || exit
done

cd .. || exit

echo "## Generating changelog..."
go run github.com/git-chglog/git-chglog/cmd/git-chglog -o CHANGELOG.md

echo "## Go mod tidy..."
go mod tidy

echo "## Go fmt..."
go fmt ./...

echo "## Staging changes..."
git add .
echo "## Commiting files..."
git commit -m "docs: autoupdate" || true
echo "## Pushing to $BRANCH"
git push -u origin $BRANCH
