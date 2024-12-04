class AppUser {
  final String? uid;  // Make `uid` nullable

  AppUser({this.uid});  // Constructor with nullable `uid`
}

class UserData {
  final String? uid;  // Make `uid` nullable
  final String? name;  // Make `name` nullable
  final String? sugars;  // Make `sugars` nullable
  final int? strength;  // Make `strength` nullable

  UserData({this.uid, this.name, this.sugars, this.strength});  // Constructor with nullable parameters
}
