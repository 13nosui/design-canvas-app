import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/sandbox/mockable_states.dart';
import 'sidebar.styles.dart';

/// TheAlphamerc/flutter_twitter_clone の sidebar.dart をベースに、
/// 依存（Firebase, Auth等）を Canvas Sandbox の Provider 経由に切り離したモック版。
class SidebarMenu extends StatefulWidget {
  const SidebarMenu({super.key});

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  Widget _menuHeader() {
    // 依存インターフェース AuthState を読み取る
    final state = context.watch<AuthState>();
    if (state.userModel == null) {
      return ConstrainedBox(
        constraints: SidebarStyles.loginConstraints,
        child: const Center(
          child: Text(
            'Login to continue',
            style: SidebarStyles.loginTextStyle,
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: SidebarStyles.profileImageSize,
              width: SidebarStyles.profileImageSize,
              margin: SidebarStyles.profileImageMargin,
              decoration: SidebarStyles.profileImageDecoration.copyWith(
                image: DecorationImage(
                  // 外部画像の依存を排除し、ネットワークからフェッチ
                  image: NetworkImage(state.userModel!.profilePic ?? 'https://via.placeholder.com/150'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            ListTile(
              onTap: () {},
              title: Row(
                children: <Widget>[
                  Text(
                    state.userModel!.displayName ?? "",
                    style: SidebarStyles.displayNameStyle,
                  ),
                  const SizedBox(width: SidebarStyles.displayVerifiedSpacing),
                  if (state.userModel!.isVerified ?? false)
                    const Icon(Icons.verified, color: SidebarStyles.verifiedIconColor, size: SidebarStyles.verifiedIconSize),
                ],
              ),
              subtitle: Text(
                state.userModel!.userName,
                style: SidebarStyles.userNameStyle,
              ),
              trailing: const Icon(Icons.keyboard_arrow_down, color: SidebarStyles.arrowDownIconColor),
            ),
            Container(
              alignment: Alignment.center,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: SidebarStyles.statPrefixWidth),
                  _textButton(context, state.userModel!.getFollower, ' Followers'),
                  const SizedBox(width: SidebarStyles.statSpacing),
                  _textButton(context, state.userModel!.getFollowing, ' Following'),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _textButton(BuildContext context, String count, String text) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: <Widget>[
          Text(
            '$count ',
            style: SidebarStyles.statCountStyle,
          ),
          Text(
            text,
            style: SidebarStyles.statLabelStyle,
          ),
        ],
      ),
    );
  }

  ListTile _menuListRowButton(String title, {IconData? icon, bool isEnable = false}) {
    return ListTile(
      onTap: () {},
      leading: icon == null
          ? null
          : Padding(
              padding: SidebarStyles.menuIconMargin,
              child: Icon(
                icon,
                size: SidebarStyles.menuIconSize,
                color: SidebarStyles.menuColor(isEnable),
              ),
            ),
      title: Text(
        title,
        style: SidebarStyles.menuTextStyle(isEnable),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffoldの子としてDrawerが描画されると想定
    return Drawer(
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            _menuHeader(),
            const Divider(),
            _menuListRowButton('Profile', icon: Icons.person_outline, isEnable: true),
            _menuListRowButton('Bookmark', icon: Icons.bookmark_border, isEnable: true),
            _menuListRowButton('Lists', icon: Icons.list_alt),
            _menuListRowButton('Moments', icon: Icons.bolt),
            const Divider(),
            _menuListRowButton('Settings and privacy', isEnable: true),
            _menuListRowButton('Help Center'),
            const Divider(),
            _menuListRowButton('Logout', isEnable: true),
          ],
        ),
      ),
    );
  }
}
