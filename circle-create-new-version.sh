#!/usr/bin/env bash
#
#   Update the chart corresponding to the git tag with a new version number,
#   Package with helm and update the index,
#   Create a git commit containing these actions
#

CHARTNAME="cron"

echo "chartname: $CHARTNAME, version: $CIRCLE_TAG"

# Always add a newline in case the chart author doesn't terminate the file with one.
echo "" >> ./$CHARTNAME/Chart.yaml
echo "version: $CIRCLE_TAG" >> ./$CHARTNAME/Chart.yaml

cat ./$CHARTNAME/Chart.yaml

helm package --destination . ./$CHARTNAME

ls -lah

git checkout .
git fetch origin gh-pages
git checkout gh-pages

helm repo index . --url https://favish.github.io/helm-$CHARTNAME

git config --global user.name "favish-ci"
git config --global user.email "dev@favish.com"

git add .
git commit -m "Create $CHARTNAME version $CIRCLE_TAG [ci skip]"
git push origin gh-pages


