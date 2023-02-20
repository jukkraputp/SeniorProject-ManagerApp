class RegisterResult {
  bool success;
  String? uid;
  String? message;

  RegisterResult({this.success = false, this.uid, this.message});
}

class getEmailResult {
  bool success;
  String? message;
  Map<String, dynamic>? data;

  getEmailResult({this.success = false, this.message, this.data});
}
