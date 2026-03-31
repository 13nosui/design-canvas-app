import 'package:flutter/material.dart';

/// ----------------------------------------------------
/// AppTokens
/// ----------------------------------------------------
/// プロジェクト全体で一意の「デザイントークン（定点）」を管理するクラスです。
/// キャンバスからコンポーネントの .styles.dart を更新する際は、
/// 可能な限りこのクラスのトークンを参照して下さい。
class AppTokens {
  // --- Colors ---
  static const colorTextPrimary = Colors.black;
  static const colorTextSecondary = Colors.black54;
  static const colorBrandPrimary = Colors.blue;
  static const colorBorderInverse = Colors.white;
  static const colorIconActive = Colors.black87;
  static const colorIconInactive = Colors.black45;

  // --- Typography (FontSize) ---
  static const fontHeadingL = 20.0;
  static const fontBodyL = 18.0;
  static const fontBodyM = 17.0; // 例: Followerカウントなど
  static const fontBodyS = 15.0; // 例: ユーザー名(@ユーザー)など

  // --- Spacing ---
  // 小さい単位から体系化した間隔トークン
  static const spaceXXS = 3.0; // アイコンとテキストの間など
  static const spaceXS = 5.0;  // メニューアイコンの上余白など
  static const spaceS = 10.0;  // リストのギャップなど
  static const spaceM = 17.0;  // プレフィックスのパディングなど

  // --- Sizing (Heights/Widths) ---
  static const sizeAvatarBase = 56.0;
  static const sizeIconSmall = 18.0;
  static const sizeIconMedium = 25.0;

  // --- Borders ---
  static const borderWidthThick = 2.0;
  // 以下のようにRadius自体を保持することも可能です
  // static const radiusCircularMax = 999.0;

  static const colorBrandModern = Color(0xFF5E6AD2); // promoted from fabColor

  static const spaceL = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0); // promoted from tweetPadding
}
