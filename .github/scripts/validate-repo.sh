#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

required_files=(
  "FreeYT Extension/Resources/manifest.json"
  "FreeYT Extension/Resources/rules.json"
  "FreeYT Extension/Resources/background.js"
  "FreeYT Extension/Resources/banner.js"
  "FreeYT Extension/Resources/popup.html"
  "FreeYT Extension/Resources/popup.js"
  "FreeYT Extension/Resources/popup.css"
  "FreeYT Extension/Resources/_locales/en/messages.json"
  "FreeYT/SharedState.swift"
  "PRIVACY.md"
  "README.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

jq empty "FreeYT Extension/Resources/manifest.json"
jq empty "FreeYT Extension/Resources/rules.json"
jq empty "FreeYT Extension/Resources/_locales/en/messages.json"

manifest_version="$(jq -r '.manifest_version' "FreeYT Extension/Resources/manifest.json")"
if [[ "$manifest_version" != "3" ]]; then
  echo "Expected Manifest V3 but found: $manifest_version" >&2
  exit 1
fi

if ! jq -e 'all(.content_scripts[].matches[]; contains("youtube-nocookie.com"))' \
  "FreeYT Extension/Resources/manifest.json" >/dev/null; then
  echo "Content scripts must remain scoped to youtube-nocookie.com" >&2
  exit 1
fi

rule_count="$(jq 'length' "FreeYT Extension/Resources/rules.json")"
if [[ "$rule_count" -lt 6 ]]; then
  echo "Unexpectedly low redirect rule count: $rule_count" >&2
  exit 1
fi

if ! jq -e 'all(.[]; .condition.resourceTypes == ["main_frame"])' \
  "FreeYT Extension/Resources/rules.json" >/dev/null; then
  echo "Every redirect rule must remain main_frame only" >&2
  exit 1
fi

if ! jq -e 'all(.[]; .action.redirect.regexSubstitution | test("youtube-nocookie"))' \
  "FreeYT Extension/Resources/rules.json" >/dev/null; then
  echo "Every redirect rule must target youtube-nocookie.com" >&2
  exit 1
fi

bundle_patterns=(
  "PRODUCT_BUNDLE_IDENTIFIER = com.freeyt.app;"
  "PRODUCT_BUNDLE_IDENTIFIER = com.freeyt.app.extension;"
  "PRODUCT_BUNDLE_IDENTIFIER = com.freeyt.app.widget;"
  "PRODUCT_BUNDLE_IDENTIFIER = com.freeyt.app.tests;"
  "PRODUCT_BUNDLE_IDENTIFIER = com.freeyt.app.uitests;"
)

for pattern in "${bundle_patterns[@]}"; do
  if ! rg -F -q "$pattern" FreeYT.xcodeproj/project.pbxproj; then
    echo "Missing expected project setting: $pattern" >&2
    exit 1
  fi
done

app_group_files=(
  "FreeYT/SharedState.swift"
  "FreeYT/FreeYT.entitlements"
  "FreeYT Extension/FreeYT_Extension.entitlements"
  "FreeYTWidget/FreeYTWidget.entitlements"
)

for file in "${app_group_files[@]}"; do
  if ! rg -F -q "group.com.freeyt.app" "$file"; then
    echo "Missing expected app group in: $file" >&2
    exit 1
  fi
done

if git ls-files | rg -q '\.xcarchive'; then
  echo "Tracked .xcarchive artifacts must not remain in the repository" >&2
  exit 1
fi

echo "Repository validation passed."
