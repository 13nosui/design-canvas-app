import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_canvas_app/main.dart'; // MyApp をインポート
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    // Golden Testのお作法: 
    // HTTP経由でのフォントダウンロード（GoogleFontsなど）がテスト中に発生すると
    // 非同期処理や環境差異でテストが不安定（Flaky）になるため無効化します。
    GoogleFonts.config.allowRuntimeFetching = false;
    
    // （※Flutter Test はデフォルトでシステムフォントを Ahem フォント等の矩形（四角い豆腐）
    // に置き換えるため、OSによるタイポグラフィの描画差異が生まれずVRTが安定します。）
  });

  testWidgets('Design Canvas VRT (Visual Regression Test)', (WidgetTester tester) async {
    // 物理サイズ（ウィンドウサイズ）をデスクトップ（ブラウザ）向けに広げる
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;

    // MyApp（Design Canvas 全体）をPump
    // GoogleFontsによる自動フェッチとエラーを回避するため、Ahemフォントを渡してFallbackさせます。
    await tester.pumpWidget(const MyApp(initialFontFamily: 'Ahem'));
    
    // すべてのアニメーションや非同期描画が終わるまで待機
    await tester.pumpAndSettle(); 

    // `matchesGoldenFile` でスナップショットをテスト
    // 初回は `flutter test --update-goldens` を実行して正解画像を生成します。
    await expectLater(
      find.byType(MyApp),
      matchesGoldenFile('goldens/design_canvas.png'),
    );

    // テスト後のお作法: サイズの変更をリセットして他のテストに影響させない
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
