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

/// ----------------------------------------------------
/// Feed の抽象インターフェースとモック
/// ----------------------------------------------------
class TweetModel {
  final String id;
  final String userName;
  final String displayName;
  final String content;
  final String timeAgo;
  final int likes;
  final int retweets;

  TweetModel({
    required this.id,
    required this.userName,
    required this.displayName,
    required this.content,
    required this.timeAgo,
    this.likes = 0,
    this.retweets = 0,
  });
}

abstract class FeedState extends ChangeNotifier {
  List<TweetModel> get tweets;
  bool get isLoading;
}

class MockFeedState extends FeedState {
  final List<TweetModel> _tweets = [
    TweetModel(
      id: '1',
      userName: '@flutter_dev',
      displayName: 'Flutter',
      content: 'Hello World from the Flutter Design Canvas! 🎨✨ The UI rule decoupling is working perfectly.',
      timeAgo: '5m',
      likes: 420,
      retweets: 56,
    ),
    TweetModel(
      id: '2',
      userName: '@dart_lang',
      displayName: 'Dart',
      content: 'Just deployed the newest automated mapping script. `AppTokens` is awesome.',
      timeAgo: '1h',
      likes: 128,
      retweets: 12,
    ),
    TweetModel(
      id: '3',
      userName: '@test_user_dummy',
      displayName: 'Test User',
      content: 'This is an example tweet mocked via CanvasSandbox without starting any backend servers!!!',
      timeAgo: '2h',
      likes: 999,
      retweets: 485,
    ),
  ];

  @override
  List<TweetModel> get tweets => _tweets;

  @override
  bool get isLoading => false;
}

/// ----------------------------------------------------
/// Chat (Message) の抽象インターフェースとモック
/// ----------------------------------------------------
class MessageModel {
  final String senderId;
  final String text;
  final String timeStamp;
  final bool isMe;

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timeStamp,
    required this.isMe,
  });
}

abstract class ChatState extends ChangeNotifier {
  List<MessageModel> get messages;
  bool get isReceiving;
}

class MockChatState extends ChatState {
  final List<MessageModel> _messages = [
    MessageModel(senderId: 'contact1', text: 'Hey, did you see the new feature?', timeStamp: '10:00 AM', isMe: false),
    MessageModel(senderId: 'me', text: 'Yeah! The Canvas sandbox integration looks incredible.', timeStamp: '10:02 AM', isMe: true),
    MessageModel(senderId: 'contact1', text: 'We don\'t even need Firebase to design these screens anymore.', timeStamp: '10:05 AM', isMe: false),
  ];

  @override
  List<MessageModel> get messages => _messages;

  @override
  bool get isReceiving => false;
}
