class UserModel {
  final String _ccid;
  final String _username;
  final String _email;
  final String _discipline;
  UserModel(this._ccid, this._username, this._email, this._discipline);

  // Getters
  String get discipline => _discipline;
  String get email => _email;
  String get username => _username;
  String get ccid => _ccid;
}
