import 'package:flutter/foundation.dart';

class Item {
  String name;
  String price;
  String image;
  String id;
  Uint8List? bytes;
  bool delete = false;

  int? idIn(List<Item> itemList) {
    for (var i = 0; i < itemList.length; i++) {
      Item item = itemList[i];
      if (id == item.id) {
        return i;
      }
    }
    return null;
  }

  Item(this.name, this.price, this.image, this.id, {this.bytes});
}
