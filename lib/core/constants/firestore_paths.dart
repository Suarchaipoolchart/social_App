class FirestorePaths {
  static const users = 'users';
  static const posts = 'posts';
  static const comments = 'comments';
  static const follows = 'follows';
  static const chats = 'chats';
  static const messages = 'messages';
  static const groups = 'groups';
  static const reports = 'reports';

  static String user(String uid) => '$users/$uid';
}
