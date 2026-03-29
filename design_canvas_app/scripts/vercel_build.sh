#!/bin/bash

# 確実にプロジェクトのルートディレクトリ（pubspec.yamlがある場所）へ移動
cd "$(dirname "$0")/.." || exit 1

echo "Checking Flutter SDK cache..."
# flutter ディレクトリが存在するか確認し、キャッシュがあればダウンロードをスキップ
if [ -d "flutter" ]; then
  echo "Flutter SDK is already cached. Skipping download."
else
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# コマンドのパスを作業環境に直通させる
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter doctor..."
flutter doctor -v

echo "Building Flutter Web..."
# Vercel用の静的Webビルドを実行
flutter build web --release
