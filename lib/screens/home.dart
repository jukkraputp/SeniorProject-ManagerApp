import 'dart:io';

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
      {super.key, required this.shopList, this.receptionToken, this.chefToken});

  final List<String> shopList;
  final String? receptionToken;
  final String? chefToken;

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
  bool widgetReady = false;
  late String shopName;

  @override
  void initState() {
    super.initState();
    int counter = 0;
    for (var shopKey in widget.shopList) {
      api.getShopName(shopKey).then((name) {
        if (name != null) {
          api.getMenuList(name).then((value) {
            setState(() {
              shopName = name;
              menuListObj[shopKey] = value;
              menuTypeListObj[shopKey] = value.menu.keys.toList();
            });
            counter += 1;
            if (counter == widget.shopList.length) {
              setState(() {
                widgetReady = true;
              });
            }
          });
        }
      });
    }
  }

  void updateMenuTypeList(String shopKey, String typeName) {
    if (menuTypeListObj.containsKey(shopKey)) {
      setState(() {
        menuTypeListObj[shopKey]!.add(typeName);
        menuListObj[shopKey]!.menu[typeName] = [];
      });
    } else {
      print('"$shopKey" not found');
    }
  }

  void deleteMenuType(String shopKey, String typeName) {
    setState(() {
      menuTypeListObj[shopKey]!.remove(typeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;
    return widgetReady
        ? Scaffold(
            body: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
                child: ListView.builder(
                  itemCount: widget.shopList.length,
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
                                          return ShopManager(
                                            shopName: shopName,
                                            menuList: menuListObj[
                                                widget.shopList[index]]!,
                                            menuTypeList: menuTypeListObj[
                                                widget.shopList[index]]!,
                                            shopKey: widget.shopList[index],
                                            updateMenuType: updateMenuTypeList,
                                            deleteMenuType: deleteMenuType,
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
                                  color: Colors.green.shade400),
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) {
                                          return const AddShop();
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
