import 'package:flutter/material.dart';
import '../../../core/design_system/tokens.dart';

/// キャンバス等からUIの見た目だけを直接変更するためのスタイル隔離ファイル
class SidebarStyles {
  // Login State
  static const loginConstraints = BoxConstraints(minWidth: 200, minHeight: 100);
  static const loginTextStyle = TextStyle(
      color: AppTokens.colorTextPrimary, fontSize: AppTokens.fontBodyL);

  // Profile Header
  static const profileImageMargin =
      EdgeInsets.only(left: AppTokens.spaceM, top: AppTokens.spaceS);
  static const profileImageSize = AppTokens.sizeAvatarBase;

  // Profile Image Decoration (Not const because of BorderRadius)
  static final profileImageDecoration = BoxDecoration(
    border: Border.all(
        color: AppTokens.colorBorderInverse, width: AppTokens.borderWidthThick),
    borderRadius: BorderRadius.circular(profileImageSize / 2),
  );

  // Typography
  static const displayNameStyle = TextStyle(
      color: AppTokens.colorTextPrimary,
      fontSize: AppTokens.fontHeadingL,
      fontWeight: FontWeight.bold);
  static const userNameStyle = TextStyle(
      color: AppTokens.colorTextSecondary, fontSize: AppTokens.fontBodyS);
  static const statCountStyle =
      TextStyle(fontWeight: FontWeight.bold, fontSize: AppTokens.fontBodyM);
  static const statLabelStyle = TextStyle(
      color: AppTokens.colorTextSecondary, fontSize: AppTokens.fontBodyM);

  // Icons
  static const verifiedIconColor = AppTokens.colorBrandPrimary;
  static const verifiedIconSize = AppTokens.sizeIconSmall;
  static const arrowDownIconColor = AppTokens.colorBrandPrimary;

  // Layout spacing
  static const displayVerifiedSpacing = AppTokens.spaceXXS;
  static const statPrefixWidth = AppTokens.spaceM;
  static const statSpacing = AppTokens.spaceS;

  // Menu Items
  static const menuIconSize = AppTokens.sizeIconMedium;
  static const menuIconMargin = EdgeInsets.only(top: AppTokens.spaceXS);

  static Color menuColor(bool isEnable) =>
      isEnable ? AppTokens.colorIconActive : AppTokens.colorIconInactive;

  static TextStyle menuTextStyle(bool isEnable) => TextStyle(
        fontSize: AppTokens.fontHeadingL,
        color: menuColor(isEnable),
      );
}
