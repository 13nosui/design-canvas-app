// ImportPage の視覚定数 (.dart からは直接の値ハードコードを禁止)
import 'package:flutter/material.dart';
import '../../core/design_system/tokens.dart';

class ImportPageStyles {
  ImportPageStyles._();

  // 全体
  static const backgroundColor = Color(0xFFF8FAFC); // TODO: New Token Candidate - colorSurfaceMuted
  static const maxContentWidth = 720.0; // TODO: New Token Candidate - sizeContentMaxWidth
  static const contentPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 32);

  // ヘッダー
  static const heroIconSize = 56.0; // TODO: New Token Candidate - sizeHeroIcon
  static const heroSpacing = AppTokens.spaceM;
  static const titleStyle = TextStyle(
    fontSize: 28, // TODO: New Token Candidate - fontHeadingXL
    fontWeight: FontWeight.w700,
    color: Color(0xFF0F172A), // TODO: New Token Candidate - colorTextStrong
    height: 1.25,
  );
  static const summaryStyle = TextStyle(
    fontSize: 15,
    color: Color(0xFF475569), // TODO: New Token Candidate - colorTextMuted
    height: 1.6,
  );
  static const promptHintStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF94A3B8), // TODO: New Token Candidate - colorTextSubtle
    fontStyle: FontStyle.italic,
  );

  // セクションラベル (eyebrow)
  static const sectionLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: Color(0xFF94A3B8), // TODO: New Token Candidate - colorTextSubtle
  );

  // セクションタイトル (本文ラベル)
  static const itemTitleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A), // TODO: New Token Candidate - colorTextStrong
  );
  static const itemBodyStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF475569),
    height: 1.55,
  );

  // カード
  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12), // TODO: New Token Candidate - radiusCard
    border: Border.all(color: const Color(0xFFE2E8F0)), // TODO: New Token Candidate - colorBorderSubtle
  );
  static const cardPadding = EdgeInsets.all(16);

  // チップ (技術スタック)
  static const chipBackground = Color(0xFFF1F5F9); // TODO: New Token Candidate - colorSurfaceChip
  static const chipForeground = Color(0xFF334155);
  static final chipShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(6),
  );

  // API コードバッジ
  static const apiCodeBackground = Color(0xFFEFF6FF); // TODO: New Token Candidate - colorSurfaceCode
  static const apiCodeForeground = Color(0xFF1D4ED8);
  static const apiCodeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    color: Color(0xFF1D4ED8),
    fontWeight: FontWeight.w600,
  );

  // リスク
  static const riskIconColor = Color(0xFFF59E0B); // TODO: New Token Candidate - colorWarningIcon

  // セクション間の余白
  static const sectionGap = 32.0; // TODO: New Token Candidate - spaceSection
  static const itemGap = 12.0;

  // Import 実行ボタン / 生成プレビュー
  static const importButtonColor = Color(0xFF0F172A); // TODO: New Token Candidate - colorActionPrimary
  static const importButtonForeground = Color(0xFFFFFFFF);
  static const importSheetBackground = Color(0xFFFFFFFF);
  static const generatedFileBackground = Color(0xFF0F172A);
  static const generatedFileForeground = Color(0xFFE2E8F0);
  static const generatedFileLabelStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF60A5FA),
  );
  static const generatedFileCodeStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 11,
    height: 1.5,
    color: Color(0xFFE2E8F0),
  );

  // ステータスバッジ
  static const Map<String, Color> statusBackgrounds = {
    'green': Color(0xFFD1FAE5),
    'blue': Color(0xFFDBEAFE),
    'yellow': Color(0xFFFEF3C7),
    'slate': Color(0xFFF1F5F9),
  };
  static const Map<String, Color> statusForegrounds = {
    'green': Color(0xFF047857),
    'blue': Color(0xFF1D4ED8),
    'yellow': Color(0xFF92400E),
    'slate': Color(0xFF475569),
  };
}
