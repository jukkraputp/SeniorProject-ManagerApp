import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:lottie/lottie.dart';
import 'package:manager/apis/api.dart';
import 'package:flutter/material.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:manager/interfaces/order.dart';
import 'package:manager/interfaces/shop_info.dart';
import 'package:manager/screens/add_shop.dart';
import 'package:manager/screens/shop_manager.dart';
import 'package:manager/util/foods.dart';
import 'package:manager/util/categories.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/src/response.dart' as http;

class Home extends StatefulWidget {
  const Home(
      {super.key,
      required this.shopList,
      required this.afterAddShop,
      required this.afterDeleteShop});

  final List<ShopInfo> shopList;
  final Future<void> Function(String) afterAddShop;
  final void Function(ShopInfo) afterDeleteShop;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home> {
  final API api = API();
  late Position _position;
  late google_map.LatLng _center;
  late google_map.Marker _marker;

  bool _googleMapReady = false;
  Map<String, MenuList> allMenuList = {};
  Map<String, List<String>> allMenuTypeList = {};
  Map<String, List<Order>> allHistoryList = {};
  bool _widgetReady = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    int counter = 0;
    if (widget.shopList.isEmpty) {
      setState(() {
        _widgetReady = true;
      });
    }
    for (var shopInfo in widget.shopList) {
      String shopName = shopInfo.name;
      api
          .getShopMenu(
              uid: FirebaseAuth.instance.currentUser!.uid, shopName: shopName)
          .then((value) {
        setState(() {
          allMenuList[shopName] = value;
          allMenuTypeList[shopName] = value.menu.keys.toList();
        });
        counter += 1;
        if (counter == widget.shopList.length) {
          setState(() {
            _widgetReady = true;
          });
        }
      });
    }

    // Test if location services are enabled.
    Geolocator.isLocationServiceEnabled().then((value) {
      if (!value) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
      } else {
        getPermission().then((isGranted) {
          if (isGranted) {
            setState(() {
              _ready = true;
            });
          } else {
            FirebaseAuth.instance.signOut();
          }
        });
      }
    });
  }

  Future<List<Order>> updateHistoryData(
      ShopInfo shopInfo, List<Order> historyList,
      {String mode = 'new'}) async {
    if (mode == 'new') {
      setState(() {
        allHistoryList[shopInfo.name] = historyList;
      });
    } else if ((mode == 'add') & (allHistoryList[shopInfo.name] != null)) {
      setState(() {
        allHistoryList[shopInfo.name]!.addAll(historyList);
      });
    } else {
      return [];
    }
    return allHistoryList[shopInfo.name]!;
  }

  Future<bool> getPermission() async {
    bool isGranted = false;
    var permission = await Geolocator.checkPermission();

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      } else {
        isGranted = true;
      }
    } else {
      isGranted = true;
    }
    if (isGranted) {
      var pos = await Geolocator.getCurrentPosition();
      setState(() {
        _position = pos;
        _center = google_map.LatLng(pos.latitude, pos.longitude);
        _marker = google_map.Marker(
            markerId: const google_map.MarkerId('MainMarker'),
            icon: google_map.BitmapDescriptor.defaultMarker,
            position: _center);
        _googleMapReady = true;
      });
    }
    return isGranted;
  }

  Future<void> updateMenuList(String shopName) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    MenuList menuList = await api.getShopMenu(uid: uid, shopName: shopName);
    setState(() {
      allMenuList[shopName] = menuList;
      allMenuTypeList[shopName] = menuList.menu.keys.toList();
    });
  }

  void updateMenuTypeList(String shopName, String typeName) {
    if (allMenuTypeList.containsKey(shopName)) {
      setState(() {
        allMenuTypeList[shopName]!.add(typeName);
        allMenuList[shopName]!.menu[typeName] = [];
      });
    } else {
      print('"$shopName" not found');
    }
  }

  void deleteMenuType(String shopName, String typeName) {
    setState(() {
      allMenuTypeList[shopName]!.remove(typeName);
    });
  }

  Future<void> afterAddShop(String shopName) async {
    widget.afterAddShop(shopName);
    setState(() {
      allMenuList[shopName] = MenuList();
      allMenuTypeList[shopName] = [];
    });
  }

  void afterDeleteShop(ShopInfo shopInfo) {
    widget.afterDeleteShop(shopInfo);
    String shopName = shopInfo.name;
    setState(() {
      allMenuList.remove(shopName);
      allMenuTypeList.remove(shopName);
    });
  }

  Future<void> deleteShop(String shopName) async {
    var res = await api.deleteShop(
        uid: FirebaseAuth.instance.currentUser!.uid, shopName: shopName);
  }

  void addShop() {
    Size screenSize = MediaQuery.of(context).size;
    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: SizedBox(
                height: screenSize.height * 0.75,
                child: _googleMapReady
                    ? AddShop(
                        afterAddShop: afterAddShop,
                        position: _position,
                        center: _center,
                        marker: _marker,
                      )
                    : Center(
                        child: Lottie.asset(
                            'assets/animations/colors-circle-loader.json'),
                      )),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;
    return _ready
        ? Scaffold(
            resizeToAvoidBottomInset: false,
            body: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                child: ListView.builder(
                  itemCount: widget.shopList.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (widget.shopList.isEmpty) {
                      return SizedBox(
                        height: screenSize.height * 0.8,
                        child: Center(
                          child: TextButton(
                            onPressed: () => addShop(),
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.green.shade400),
                            child: const Text(
                              'เพิ่มร้านค้าของคุณ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    }
                    if (index < widget.shopList.length) {
                      return SizedBox(
                        height: screenSize.height / 4,
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: (screenSize.height / 4 -
                                      screenSize.height / 5) /
                                  2,
                            ),
                            SizedBox(
                              height: screenSize.height / 5,
                              width: screenSize.width * 0.8,
                              child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) {
                                          late MenuList menuList;
                                          List<String> menuTypeList = [];
                                          List<Order> historyList = [];
                                          if (allMenuList[widget
                                                  .shopList[index].name] !=
                                              null) {
                                            menuList = allMenuList[
                                                widget.shopList[index].name]!;
                                          } else {
                                            menuList = MenuList();
                                          }
                                          if (allMenuTypeList[widget
                                                  .shopList[index].name] !=
                                              null) {
                                            menuTypeList = allMenuTypeList[
                                                widget.shopList[index].name]!;
                                          }
                                          if (allHistoryList[widget
                                                  .shopList[index].name] !=
                                              null) {
                                            historyList = allHistoryList[
                                                widget.shopList[index].name]!;
                                          }
                                          return ShopManager(
                                            shopInfo: widget.shopList[index],
                                            menuList: menuList,
                                            menuTypeList: menuTypeList,
                                            historyList: historyList,
                                            updateMenuType: updateMenuTypeList,
                                            deleteMenuType: deleteMenuType,
                                            afterUpdate: updateMenuList,
                                            deleteShop: deleteShop,
                                            afterDeleteShop: afterDeleteShop,
                                            updateHistory: updateHistoryData,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0))),
                                  ),
                                  child: Text(widget.shopList[index].name)),
                            ),
                            SizedBox(
                              height: (screenSize.height / 4 -
                                      screenSize.height / 5) /
                                  2,
                            )
                          ],
                        ),
                      );
                    } else {
                      return SizedBox(
                        height: screenSize.height / 4,
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: (screenSize.height / 4 -
                                      screenSize.height / 5) /
                                  2,
                            ),
                            Container(
                              height: screenSize.width / 7.5,
                              width: screenSize.width / 7.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                color: Colors.green.shade400,
                              ),
                              child: IconButton(
                                  onPressed: () => addShop(),
                                  style: ButtonStyle(
                                    shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30.0))),
                                  ),
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  )),
                            ),
                            SizedBox(
                              height: (screenSize.height / 4 -
                                      screenSize.height / 5) /
                                  2,
                            )
                          ],
                        ),
                      );
                    }
                  },
                )),
          )
        : Center(
            child: Lottie.asset('assets/animations/colors-circle-loader.json'),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
