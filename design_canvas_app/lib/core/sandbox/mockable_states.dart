import 'package:flutter/foundation.dart';

/// ----------------------------------------------------
/// UserModelの抽象化・共通モデル
/// ----------------------------------------------------
class UserModel {
  final String? profilePic;
  final String? userId;
  final String? displayName;
  final bool? isVerified;
  final String userName;
  final String getFollower;
  final String getFollowing;
  final List<String>? followersList;
  final List<String>? followingList;

  UserModel({
    this.profilePic,
    this.userId,
    this.displayName,
    this.isVerified,
    required this.userName,
    required this.getFollower,
    required this.getFollowing,
    this.followersList,
    this.followingList,
  });
}

/// ----------------------------------------------------
/// AuthState の抽象インターフェース
/// ----------------------------------------------------
/// 既存のProvider(Firebaseに密結合)を、このインターフェースに
/// 取り替えることで、UI側は「ログイン状態」であることだけを知ればよくなる。
abstract class AuthState extends ChangeNotifier {
  UserModel? get userModel;
  String? get userId;
  UserModel? get profileUserModel;
  
  Future<void> getProfileUser();
  void logoutCallback();
}

/// ----------------------------------------------------
/// デザインキャンバス＆テスト用モック状態
/// ----------------------------------------------------
class MockAuthState extends AuthState {
  UserModel? _userModel = UserModel(
    profilePic: 'https://avatars.githubusercontent.com/u/10?v=4', // ダミー画像
    userId: '12345',
    displayName: 'Test User',
    userName: '@test_user_dummy',
    isVerified: true,
    getFollower: '1.2M',
    getFollowing: '42',
    followersList: [],
    followingList: [],
  );

  @override
  UserModel? get userModel => _userModel;

  @override
  String? get userId => _userModel?.userId;

  @override
  UserModel? get profileUserModel => _userModel;

  @override
  Future<void> getProfileUser() async {
    // 擬似的なAPIコールの遅延
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void logoutCallback() {
    _userModel = null;
    notifyListeners();
  }
}

/// ----------------------------------------------------
/// 本番アプリ用状態 (Firebase等の実装例)
/// ----------------------------------------------------
class FirebaseAuthState extends AuthState {
  // 実際はここにFirebaseAuthなどのインスタンスを持ち、本物のユーザー情報を返す。
  @override
  UserModel? get userModel => throw UnimplementedError('Real Firebase Implementation here');

  @override
  String? get userId => throw UnimplementedError('Real Firebase Implementation here');

  @override
  UserModel? get profileUserModel => throw UnimplementedError('Real Firebase Implementation here');

  @override
  Future<void> getProfileUser() async {
    // 本物のAPIを取得
    throw UnimplementedError('Real Firebase Implementation here');
  }

  @override
  void logoutCallback() {
    // FirebaseAuth.instance.signOut();
  }
}
