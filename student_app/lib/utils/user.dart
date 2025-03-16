class UserModel {
  final String _ccid;
  final String _username;
  final String _email;
  final String _discipline;
  final String? _schedule;
  final String _educationLvl;
  final String _degree;
  final String _locationTracking;
  // final String _currentLocation; Not suer what type this is yet
  UserModel(
      this._ccid,
      this._username,
      this._email,
      this._discipline,
      this._schedule,
      this._educationLvl,
      // this._currentLocation,
      this._degree,
      this._locationTracking);

  // Getters
  String get discipline => _discipline;
  String get email => _email;
  String get username => _username;
  String get ccid => _ccid;
  String get schedule => _schedule ?? "Null";
  String get educationLv1 => _educationLvl;
  String get degree => _degree;
  String get locationTracking => _locationTracking;
  // String get currentLocation => _currentLocation;
}
