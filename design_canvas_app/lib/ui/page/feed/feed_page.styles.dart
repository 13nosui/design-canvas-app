import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';

class FeedFabStyle {
  static const color = AppTokens.colorBrandModern;
}

class FeedAppBarStyle {
  static const titleTypography = TextStyle(
    color: Color(0xFF111827), // TODO: New Token Candidate - colorTextPrimarySolid
    fontWeight: FontWeight.w700, 
    fontSize: 20.0,
    letterSpacing: -0.5,
  );
  static const backgroundColor = Colors.white; // TODO: New Token Candidate - colorBackgroundPrimary
}

class FeedTweetStyle {
  static const padding = AppTokens.spaceL;
  static const border = Border(
    bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1.0), // TODO: New Token Candidate - colorBorderSubtle
  );
  
  static const nameTypography = TextStyle(
    fontWeight: FontWeight.w600, // TODO: New Token Candidate - fontWeightSemiBold
    fontSize: AppTokens.fontBodyM, 
    color: Color(0xFF111827), // TODO: New Token Candidate - colorTextPrimarySolid
    letterSpacing: -0.3, // TODO: New Token Candidate - letterSpacingTight
  );
  
  static const handleTypography = TextStyle(
    color: Color(0xFF9CA3AF), // TODO: New Token Candidate - colorTextMuted
    fontSize: AppTokens.fontBodyS,
    letterSpacing: -0.1,
  );
  
  static const contentTypography = TextStyle(
    fontSize: AppTokens.fontBodyM, 
    color: Color(0xFF374151), // TODO: New Token Candidate - colorTextBody
    height: 1.5, // TODO: New Token Candidate - lineHeightRelaxed
    letterSpacing: -0.2,
  );
  
  static const statTypography = TextStyle(
    color: Color(0xFF6B7280), // TODO: New Token Candidate - colorTextSecondarySolid
    fontSize: AppTokens.fontBodyS,
    fontWeight: FontWeight.w500, // TODO: New Token Candidate - fontWeightMedium
  );
}
