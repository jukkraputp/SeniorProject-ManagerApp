import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:manager/interfaces/omise.dart';
import 'package:manager/interfaces/order.dart' as food_order;
import 'package:manager/interfaces/register.dart';
import 'package:manager/interfaces/shop_info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:manager/interfaces/history.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:http/http.dart' as http;
import 'package:manager/interfaces/manager/user.dart' as manager_user;

const String backendUrl = 'http://jukkraputp.sytes.net';

class API {
  final FirebaseFirestore _firestoreDB = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Firestore Database

  Future<MenuList> getShopMenu(
      {required String uid, required String shopName}) async {
    List<String> types = await getShopTypes(uid, shopName);
    MenuList menuList = MenuList(typesList: types);
    for (var type in types) {
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestoreDB
          .collection('Menu')
          .doc('$uid-$shopName')
          .collection(type)
          .get();
      for (var doc in querySnapshot.docs) {
        menuList.menu[type]!.add(Item(
            name: doc['name'],
            price: doc['price'],
            time: doc['time'],
            image: doc['image'],
            id: doc['id'],
            available: doc['available']));
      }
    }
    return menuList;
  }

  Future<List<String>> getShopTypes(String uid, String shopName) async {
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await _firestoreDB.collection('Menu').doc('$uid-$shopName').get();
    List<String> types = [];
    if (documentSnapshot.exists) {
      var data = documentSnapshot.data();
      List<String> typeList = [];
      for (var type in data?['types'] ?? []) {
        typeList.add(type.toString());
      }
      types = typeList;
    }
    return types;
  }

  Future<getEmailResult> getEmail(String username, String password) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestoreDB
        .collection('Manager')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();
    if (querySnapshot.size < 1) {
      return getEmailResult(success: false, message: 'not found');
    } else {
      var data = querySnapshot.docs.first.data();
      return getEmailResult(success: true, data: data);
    }
  }

  Future<String?> getShopName(String key) async {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await _firestoreDB.collection('ShopList').doc(key).get();
    if (docSnapshot.exists) {
      return docSnapshot['name'];
    }
    return null;
  }

  Future<List<Object?>> getShopList(String? uid) async {
    late QuerySnapshot querySnapshot;
    if (uid != null) {
      querySnapshot = await _firestoreDB
          .collection('ShopList')
          .where('uid', isEqualTo: uid)
          .get();
    } else {
      querySnapshot = await _firestoreDB.collection('ShopList').get();
    }

    var shopList = querySnapshot.docs.map((doc) => doc.data()).toList();
    return shopList;
  }

  Future<String?> getshopName(String token) async {
    try {
      var doc = await _firestoreDB.collection('TokenList').doc(token).get();
      return doc.data()?['key'];
    } on Exception catch (_) {
      return null;
    }
  }

  Future<String?> getMode(String token) async {
    try {
      var doc = await _firestoreDB.collection('TokenList').doc(token).get();
      return doc.data()?['mode'];
    } on Exception catch (_) {
      return null;
    }
  }

  /// Set Name and Price of MenuList object.
  Future<MenuList> setProductDetails(
      String uid, String shopName, MenuList menuList, ListResult types) async {
    var ref = _firestoreDB.collection('Menu').doc('$uid-$shopName');
    for (var typeRef in types.prefixes) {
      var type = typeRef.name;
      var querySnapshot = await ref.collection(type).get();
      Map<String, Map<String, dynamic>> infoMap = {};
      for (var doc in querySnapshot.docs) {
        infoMap[doc.id] = doc.data();
      }
      menuList.menu[type]?.forEach((element) {
        var id = element.id;
        if (infoMap.containsKey(id)) {
          element.name = infoMap[id]?['name'];
          element.price = infoMap[id]?['price'];
          element.time = infoMap[id]?['time'];
        }
      });
    }
    return menuList;
  }

  Future<History> getHistory(
      String shopName, String phoneNumber, String orderDocId) async {
    DateTime today = DateTime.now();
    String id = '${today.year}${today.month}${today.day}';
    var ref = _firestoreDB
        .collection('History')
        .doc('$shopName-$phoneNumber')
        .collection(id)
        .doc(orderDocId);
    var doc = await ref.get();
    var data = doc.data();
    var history = History(
        orderId: data?['orderId'],
        totalAmount: data?['totalAmount'],
        date: data?['date'],
        foods: data?['foods']);
    return history;
  }

  Future<List<History>> getHistoryList(
      String shopName, String phoneNumber) async {
    final List<History> historyList = [];
    DateTime today = DateTime.now();
    String id = '${today.year}${today.month}${today.day}';
    var ref = _firestoreDB
        .collection('History')
        .doc('$shopName-$phoneNumber')
        .collection(id);
    var datas = await ref.get();
    for (var doc in datas.docs) {
      var data = doc.data();
      var history = History(
          orderId: data['orderId'],
          totalAmount: data['totalAmount'],
          date: data['date'],
          foods: data['foods']);
      historyList.add(history);
    }
    return historyList;
  }

  // Storage

  Future<http.Response> deleteType(
      String uid, String shopName, String typeName) async {
    try {
      await _storage
          .ref()
          .child('$uid-$shopName/$typeName/not-in-use.txt')
          .putString('this folder is unused');
    } catch (e) {
      print('firebase storage error: $e');
    }
    http.Response res = await http.post(
        Uri.parse('$backendUrl:7777/delete-type'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body:
            json.encode({'uid': uid, 'shopName': shopName, 'type': typeName}));
    return res;
  }

  Future<http.Response> setNewType(
      String uid, String shopName, String typeName) async {
    try {
      await _storage
          .ref()
          .child('$uid-$shopName/$typeName/foo.txt')
          .putString('foo file');
      await _storage
          .ref()
          .child('$uid-$shopName/$typeName/not-in-use.txt')
          .putString('not in use');
      await _storage
          .ref()
          .child('$uid-$shopName/$typeName/not-in-use.txt')
          .delete();
    } catch (e) {
      print('API setNewType: $e');
    }
    http.Response res = await http.post(Uri.parse('$backendUrl:7777/add-type'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body:
            json.encode({'uid': uid, 'shopName': shopName, 'type': typeName}));
    return res;
  }

  // Through backend server

  // add shop
  Future<http.Response> addShop(
      {required String uid,
      required String shopName,
      required String phoneNumber,
      required LatLng latLng}) async {
    print('API: addShop');
    http.Response res = await http.post(Uri.parse('$backendUrl:7777/add-shop'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({
          'uid': uid,
          'shopName': shopName,
          'phoneNumber': phoneNumber,
          'latitude': latLng.latitude,
          'longitude': latLng.longitude
        }));
    return res;
  }

  // delete shop
  Future<http.Response> deleteShop(
      {required String uid, required String shopName}) async {
    print('API: deleteShop');
    http.Response res = await http.post(
        Uri.parse('$backendUrl:7777/delete-shop'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({'uid': uid, 'shopName': shopName}));
    return res;
  }

  // register
  Future<http.Response?> register(
      {required String username,
      required String email,
      required String password,
      required String phoneNumber,
      String countryCode = '66',
      String mode = 'Manager'}) async {
    if (password.length < 6) {
      print('register: password.length < 6');
      return null;
    }
    http.Response res = await http.post(Uri.parse('$backendUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'phoneNumber': '+$countryCode$phoneNumber',
          'mode': mode
        }));
    return res;
  }

  // delete everything relate to pos tokens
  Future<http.Response> clearToken(
      {required String secret, required String username}) async {
    return await http.post(
        Uri.parse('http://jukkraputp.sytes.net:7777/clear-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({'secret': secret, 'username': username}));
  }

  // generate otp for pos
  Future<String> generateToken(
      {required String shopName,
      required String uid,
      String mode = "Reception"}) async {
    http.Response res = await http.post(
        Uri.parse('http://jukkraputp.sytes.net:7777/generate-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({'key': shopName, 'mode': mode, 'uid': uid}));
    print(res.body);
    return jsonDecode(res.body)['OTP'];
  }

  // Write data to database through backend server api
  Future<http.Response> addOrder(food_order.Order order) async {
    String jsonEncoded = order.toJsonEncoded();

    print('api - addOrder: $jsonEncoded');
    http.Response httpRes =
        await http.post(Uri.parse('http://jukkraputp.sytes.net:7777/add'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncoded);
    return httpRes;
  }

  // Change isFinished to True
  Future<http.Response> finishOrder(
      String shopName, String uid, String orderId) async {
    return http.post(Uri.parse('http://jukkraputp.sytes.net:7777/finish'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'shopName': shopName,
          'uid': uid,
          'orderId': orderId
        }));
  }

  // Move order from realtime database to firestore
  Future<http.Response> completeOrder(
      String shopName, String uid, String orderId) async {
    return http.post(Uri.parse('http://jukkraputp.sytes.net:7777/complete'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'shopName': shopName,
          'uid': uid,
          'orderId': orderId
        }));
  }

  // update new picture in firebase storage
  Future<bool> updateStorageData(
      String shopName, String uid, Map<String, List<Item>> obj) async {
    print('updating: $obj');
    print('updating firebase');
    final shopRef = _storage.ref().child('$uid-$shopName');
    final types = obj.keys;
    for (var type in types) {
      final typeRef = shopRef.child(type);
      final updateList = obj[type]!;
      for (var item in updateList) {
        print('${item.id}, ${item.delete}');
        final itemRef = typeRef.child('${item.id}.jpg');
        print(itemRef);
        var imageList = await typeRef.listAll();
        for (var image in imageList.items) {
          print(await image.getDownloadURL());
        }
        try {
          if (item.delete) {
            itemRef.delete();
          } else {
            if (item.bytes != null) {
              var task = await itemRef.putData(item.bytes!);
              item.image = await task.ref.getDownloadURL();
            }
          }
        } on FirebaseException catch (e) {
          print(e);
          return false;
        }
      }
      await updateProductInfo(uid, shopName, type, updateList);
    }
    return true;
  }

  // update product info on firebase firestore
  Future<http.Response> updateProductInfo(
      String uid, String shopName, String type, List<Item> itemList) async {
    List<Map<String, dynamic>> productList = [];
    for (Item item in itemList) {
      Map<String, dynamic> product = {};
      product['id'] = item.id;
      product['name'] = item.name;
      product['price'] = item.price;
      product['delete'] = item.delete;
      product['type'] = type;
      product['time'] = item.time;
      product['imageUrl'] = item.image;
      product['available'] = item.available;
      productList.add(product);
    }

    var jsonBody = jsonEncode(<String, dynamic>{
      'uid': uid,
      'shopName': shopName,
      'productList': productList
    });
    print('update-product: $jsonBody');

    return http.post(Uri.parse('$backendUrl:7777/update-product'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonBody);
  }

  // ------------------- Manager --------------------//

  Stream<DocumentSnapshot<Map<String, dynamic>>> listenFirestore(
      {required String collection, required String documentId}) {
    return _firestoreDB.collection(collection).doc(documentId).snapshots();
  }

  Future<manager_user.User?> getManagerInfo(User user) async {
    DocumentSnapshot<Object> res =
        await _firestoreDB.collection('Manager').doc(user.uid).get();
    var data = res.data();
    if (data != null) {
      var obj = jsonDecode(jsonEncode(data));
      List<String> shopList = [];
      String? receptionToken;
      String? chefToken;
      DocumentSnapshot<Object> reception =
          await _firestoreDB.collection('OTP').doc(obj['Reception']).get();
      if (reception.data() != null) {
        var receptionData = jsonDecode(jsonEncode(reception.data()));
        String jwt = receptionData['token'];
        bool isExpired = JwtDecoder.isExpired(jwt);
        if (!isExpired) {
          receptionToken = obj['Reception'];
        }
      }
      DocumentSnapshot<Object> chef =
          await _firestoreDB.collection('OTP').doc(obj['Chef']).get();
      if (chef.data() != null) {
        var chefData = jsonDecode(jsonEncode(chef.data()));
        String jwt = chefData['token'];
        bool isExpired = JwtDecoder.isExpired(jwt);
        if (!isExpired) {
          chefToken = obj['Chef'];
        }
      }
      for (var shopName in obj['shopList']) {
        shopList.add(shopName.toString());
      }

      manager_user.User userInfo = manager_user.User(shopList,
          receptionToken: receptionToken, chefToken: chefToken);
      return userInfo;
    }
    return null;
  }

  //-------------------- Omise ----------------------//

  // create token
  /* Future<OmiseResponse.Token> createToken(
      String publicKey,
      String name,
      String number,
      String expirationMonth,
      String expirationYear,
      String securityCode,
      {OmiseTokenInfo? info}) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    if (info != null) {
      final response = await omise.token.create(
          name, number, expirationMonth, expirationYear, securityCode,
          city: info.city,
          country: info.country,
          postalCode: info.postalCode,
          state: info.state,
          street1: info.street1,
          street2: info.street2,
          phoneNumber: info.phoneNumber);
      return response;
    } else {
      final response = await omise.token
          .create(name, number, expirationMonth, expirationYear, securityCode);
      return response;
    }
  }

  // create source
  Future<OmiseResponse.Source> createSource(
      String publicKey, int amount, String currency, String type,
      {OmiseSourceInfo? info}) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    final response = await omise.source.create(amount, currency, type);
    return response;
  }

  // retrieve a capability
  Future<OmiseResponse.Capability> retrieveCap(String publicKey) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    final response = await omise.capability.retrieve();
    return response;
  } */

  // start transaction
  Future<http.Response> createTrans(
      String sourceId, int amount, String currency) async {
    print(sourceId);
    print(amount);
    print(currency);
    var response = await http.post(
        Uri.parse('http://jukkraputp.sytes.net:8888/api/v1/start-trans'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'source_id': sourceId,
          'amount': amount * 100,
          'currency': currency
        }));
    print(response.statusCode);
    return response;
  }
}
