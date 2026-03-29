#!/bin/bash
echo "Downloading Flutter SDK..."
# Flutterのエコシステムを動的にダウンロード（Vercel用コンテナ初期化）
git clone https://github.com/flutter/flutter.git -b stable

# コマンドのパスを作業環境に直通させる
export PATH="$PATH:`pwd`/flutter/bin"

echo "Running flutter doctor..."
flutter doctor -v

echo "Building Flutter Web..."
# Vercel用の静的Webビルドを実行
flutter build web --release
