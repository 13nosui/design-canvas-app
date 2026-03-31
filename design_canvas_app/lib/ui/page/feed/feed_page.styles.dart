import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';

class FeedPageStyles {
  // ✅ AIによる自動最適化完了:
  // キャンバストークンに存在しない色(Purple)を検出し、
  // .cursorrules に従って統一感のある AppTokens.colorBrandPrimary へ修正しました。
  static const fabColor = AppTokens.colorBrandPrimary;

  static const tweetPadding = EdgeInsets.all(AppTokens.spaceS);
  static const tweetBorder = Border(bottom: BorderSide(color: Colors.black12, width: 1)); // TODO: New Token Candidate - borderSubtle
  
  static const nameStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: AppTokens.fontBodyM, color: AppTokens.colorTextPrimary);
  static const handleStyle = TextStyle(color: AppTokens.colorTextSecondary, fontSize: AppTokens.fontBodyS);
  static const contentStyle = TextStyle(fontSize: AppTokens.fontBodyM, color: AppTokens.colorTextPrimary);
  static const statStyle = TextStyle(color: AppTokens.colorTextSecondary, fontSize: AppTokens.fontBodyS);
}
