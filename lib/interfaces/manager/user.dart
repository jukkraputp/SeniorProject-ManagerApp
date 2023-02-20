import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class User {
  List<String> shopList = [];
  String? receptionToken;
  String? chefToken;

  User(this.shopList, {this.receptionToken, this.chefToken});
}
