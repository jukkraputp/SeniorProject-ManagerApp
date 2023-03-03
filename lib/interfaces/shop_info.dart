import 'package:jwt_decoder/jwt_decoder.dart';

class ShopInfo {
  String uid;
  String name;
  String? reception;
  String? chef;

  ShopInfo({required this.uid, required this.name, this.reception, this.chef});
}
