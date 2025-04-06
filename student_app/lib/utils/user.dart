class UserModel {
  final String _ccid;
  final String _username;
  final String _email;
  final String _discipline;
  final String? _schedule;
  final String _educationLvl;
  final String _degree;
  final String _locationTracking;
  final String? _photoURL;
  final String? _phoneNumber;
  final String? _instagram;
  final Map<String, dynamic>? _currentLocation; 

  UserModel(
    this._ccid,
    this._username,
    this._email,
    this._discipline,
    this._schedule,
    this._educationLvl,
    this._degree,
    this._locationTracking,
    this._photoURL,
    this._currentLocation, 
    this._phoneNumber,
    this._instagram,
  );

  // Getters
  String get ccid => _ccid;
  String get username => _username;
  String get email => _email;
  String get discipline => _discipline;
  String get schedule => _schedule ?? "Null";
  String get educationLv1 => _educationLvl;
  String get degree => _degree;
  String get locationTracking => _locationTracking;
  String? get phoneNumber => _phoneNumber;
  String? get photoURL => _photoURL;
  String? get insagram => _instagram;
  Map<String, dynamic>? get currentLocation => _currentLocation; 
}
