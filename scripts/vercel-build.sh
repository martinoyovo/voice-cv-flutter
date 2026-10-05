#!/usr/bin/env bash
#
# Vercel build step for the Flutter web front end.
#
# `vercel deploy` from a developer machine uploads the local build/web, so when
# that output is already there we keep it and Vercel only has to build api/.
# A Git-triggered build starts without it, so we fetch the pinned Flutter SDK
# and build from source instead.
set -euo pipefail

FLUTTER_VERSION="3.41.6"
OUTPUT_DIR="build/web"

if [ -f "${OUTPUT_DIR}/index.html" ]; then
  echo "==> Reusing uploaded ${OUTPUT_DIR}"
  exit 0
fi

echo "==> No ${OUTPUT_DIR} found; installing Flutter ${FLUTTER_VERSION}"
flutter_dir="$(mktemp -d)/flutter"
git clone --depth 1 --branch "${FLUTTER_VERSION}" https://github.com/flutter/flutter.git "${flutter_dir}"
export PATH="${flutter_dir}/bin:${PATH}"

flutter --version
flutter pub get
flutter build web --release
