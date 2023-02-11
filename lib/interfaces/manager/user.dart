class User {
  String username = '';
  List<String> shopList = [];
  String? receptionToken;
  String? chefToken;

  User(this.username, this.shopList, {this.receptionToken, this.chefToken});
}
