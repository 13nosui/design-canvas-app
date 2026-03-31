import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';

class FeedPageStyles {
  // ==========================================
  // Linear / Raycast風のモダンなSaaSスタイル
  // ==========================================

  // Floating Action Button (Primary Action)
  static const fabColor = AppTokens.colorBrandModern;

  // Layout & Spacing
  // モダン設計: ゆったりとした上下余白と、左右にしっかりとしたパディング
  static const tweetPadding = AppTokens.spaceL;

  // Borders
  // モダン設計: 極めて薄く繊細なさかい目線
  static const tweetBorder = Border(
    bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.0), // TODO: New Token Candidate - colorBorderSubtle
  );
  
  // Typography: Name
  // モダン設計: 重すぎないセミボールド。黒に近いが完全な黒ではない色
  static const nameStyle = TextStyle(
    fontWeight: FontWeight.w600, // TODO: New Token Candidate - fontWeightSemiBold
    fontSize: AppTokens.fontBodyM, 
    color: Color(0xFF111827), // TODO: New Token Candidate - colorTextPrimarySolid
    letterSpacing: -0.3, // TODO: New Token Candidate - letterSpacingTight
  );
  
  // Typography: Handle (Username & Time)
  // モダン設計: 存在感を抑えたシルバーグレー
  static const handleStyle = TextStyle(
    color: Color(0xFF9CA3AF), // TODO: New Token Candidate - colorTextMuted
    fontSize: AppTokens.fontBodyS,
    letterSpacing: -0.1,
  );
  
  // Typography: Content
  // モダン設計: 高い視認性を持たせるため、少し強めのテキストカラーとゆとりある行間 (1.5)
  static const contentStyle = TextStyle(
    fontSize: AppTokens.fontBodyM, 
    color: Color(0xFF374151), // TODO: New Token Candidate - colorTextBody
    height: 1.5, // TODO: New Token Candidate - lineHeightRelaxed
    letterSpacing: -0.2,
  );
  
  // Typography: Stats (Likes, Retweets)
  // モダン設計: クリーンで邪魔にならない控えめなテキスト
  static const statStyle = TextStyle(
    color: Color(0xFF6B7280), // TODO: New Token Candidate - colorTextSecondarySolid
    fontSize: AppTokens.fontBodyS,
    fontWeight: FontWeight.w500, // TODO: New Token Candidate - fontWeightMedium
  );
}
