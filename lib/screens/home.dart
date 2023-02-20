import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:lottie/lottie.dart';
import 'package:manager/apis/api.dart';
import 'package:flutter/material.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:manager/screens/add_shop.dart';
import 'package:manager/screens/shop_manager.dart';
import 'package:manager/widgets/grid_product.dart';
import 'package:manager/widgets/home_category.dart';
import 'package:manager/widgets/slider_item.dart';
import 'package:manager/util/foods.dart';
import 'package:manager/util/categories.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/src/response.dart' as http;

class Home extends StatefulWidget {
  const Home(
      {super.key,
      required this.shopList,
      this.receptionToken,
      this.chefToken,
      required this.afterAddShop,
      required this.afterDeleteShop});

  final List<String> shopList;
  final String? receptionToken;
  final String? chefToken;
  final void Function(String) afterAddShop;
  final void Function(String) afterDeleteShop;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home> {
  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  final API api = API();
  Map<String, MenuList> menuListObj = {};
  Map<String, List<String>> menuTypeListObj = {};
  bool _widgetReady = false;
  late Position _position;
  late google_map.LatLng _center;
  late google_map.Marker _marker;
  bool _googleMapReady = false;
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
    for (var shopName in widget.shopList) {
      api
          .getShopMenu(
              uid: FirebaseAuth.instance.currentUser!.uid, shopName: shopName)
          .then((value) {
        setState(() {
          menuListObj[shopName] = value;
          menuTypeListObj[shopName] = value.menu.keys.toList();
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
      print('location service: $value');
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

  Future<bool> getPermission() async {
    bool isGranted = false;
    var permission = await Geolocator.checkPermission();

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
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
    MenuList menuList = await api.getShopMenu(
        uid: FirebaseAuth.instance.currentUser!.uid, shopName: shopName);
    print(menuList.menu.keys);
    setState(() {
      menuListObj[shopName] = menuList;
      menuTypeListObj[shopName] = menuList.menu.keys.toList();
    });
  }

  void updateMenuTypeList(String shopName, String typeName) {
    if (menuTypeListObj.containsKey(shopName)) {
      setState(() {
        menuTypeListObj[shopName]!.add(typeName);
        menuListObj[shopName]!.menu[typeName] = [];
      });
    } else {
      print('"$shopName" not found');
    }
  }

  void deleteMenuType(String shopName, String typeName) {
    setState(() {
      menuTypeListObj[shopName]!.remove(typeName);
    });
  }

  void afterAddShop(String shopName) {
    widget.afterAddShop(shopName);
    setState(() {
      menuListObj[shopName] = MenuList();
      menuTypeListObj[shopName] = [];
    });
  }

  void afterDeleteShop(String shopName) {
    widget.afterDeleteShop(shopName);
    setState(() {
      menuListObj.remove(shopName);
      menuTypeListObj.remove(shopName);
    });
  }

  Future<void> deleteShop(String shopName) async {
    var res = await api.deleteShop(
        uid: FirebaseAuth.instance.currentUser!.uid, shopName: shopName);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;
    print('Home - _widgetReady: $_widgetReady');
    return _ready
        ? Scaffold(
            body: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                child: ListView.builder(
                  itemCount: widget.shopList.length + 1,
                  itemBuilder: (BuildContext context, int index) {
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
                                          if (menuListObj[
                                                  widget.shopList[index]] !=
                                              null) {
                                            menuList = menuListObj[
                                                widget.shopList[index]]!;
                                          } else {
                                            menuList = MenuList();
                                          }
                                          if (menuTypeListObj[
                                                  widget.shopList[index]] !=
                                              null) {
                                            menuTypeList = menuTypeListObj[
                                                widget.shopList[index]]!;
                                          }
                                          return ShopManager(
                                            shopName: widget.shopList[index],
                                            menuList: menuList,
                                            menuTypeList: menuTypeList,
                                            updateMenuType: updateMenuTypeList,
                                            deleteMenuType: deleteMenuType,
                                            afterUpdate: updateMenuList,
                                            deleteShop: deleteShop,
                                            afterDeleteShop: afterDeleteShop,
                                            receptionToken:
                                                widget.receptionToken,
                                            chefToken: widget.chefToken,
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
                                  child: Text(
                                      widget.shopList[index].split('_').first)),
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
                                  onPressed: () {
                                    Size screenSize =
                                        MediaQuery.of(context).size;
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return Dialog(
                                            child: SizedBox(
                                                height:
                                                    screenSize.height * 0.75,
                                                child: _googleMapReady
                                                    ? AddShop(
                                                        afterAddShop:
                                                            afterAddShop,
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
                                  },
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
