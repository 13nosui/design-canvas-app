import 'package:flutter/material.dart';

/// キャンバス等からUIの見た目だけを直接変更するためのスタイル隔離ファイル
class SidebarStyles {
  // Login State
  static const loginConstraints = BoxConstraints(minWidth: 200, minHeight: 100);
  static const loginTextStyle = TextStyle(color: Colors.black, fontSize: 18);

  // Profile Header
  static const profileImageMargin = EdgeInsets.only(left: 17, top: 10);
  static const profileImageSize = 56.0;
  
  // Profile Image Decoration (Not const because of BorderRadius)
  static final profileImageDecoration = BoxDecoration(
    border: Border.all(color: Colors.white, width: 2),
    borderRadius: BorderRadius.circular(profileImageSize / 2),
  );

  // Typography
  static const displayNameStyle = TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold);
  static const userNameStyle = TextStyle(color: Colors.black54, fontSize: 15);
  static const statCountStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 17);
  static const statLabelStyle = TextStyle(color: Colors.black54, fontSize: 17);

  // Icons
  static const verifiedIconColor = Colors.blue;
  static const verifiedIconSize = 18.0;
  static const arrowDownIconColor = Colors.blue;
  
  // Layout spacing
  static const displayVerifiedSpacing = 3.0;
  static const statPrefixWidth = 17.0;
  static const statSpacing = 10.0;

  // Menu Items
  static const menuIconSize = 25.0;
  static const menuIconMargin = EdgeInsets.only(top: 5);
  
  static Color menuColor(bool isEnable) => isEnable ? Colors.black87 : Colors.black45;
  
  static TextStyle menuTextStyle(bool isEnable) => TextStyle(
        fontSize: 20,
        color: menuColor(isEnable),
      );
}
