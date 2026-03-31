import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';

class ChatScreenStyles {
  // Bubble styles
  static final myBubbleDecoration = BoxDecoration(
    color: AppTokens.colorBrandPrimary,
    borderRadius: BorderRadius.circular(16).copyWith(bottomRight: Radius.zero),
  );
  
  static final otherBubbleDecoration = BoxDecoration(
    color: const Color(0xFFF1F0F0), // TODO: New Token Candidate - bubbleGray
    borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: Radius.zero),
  );

  static const myBubbleTextStyle = TextStyle(color: Colors.white, fontSize: AppTokens.fontBodyM);
  static const otherBubbleTextStyle = TextStyle(color: AppTokens.colorTextPrimary, fontSize: AppTokens.fontBodyM);
  
  static const timeStyle = TextStyle(color: AppTokens.colorTextSecondary, fontSize: 11);
  
  static const inputPadding = EdgeInsets.all(AppTokens.spaceS);
}
