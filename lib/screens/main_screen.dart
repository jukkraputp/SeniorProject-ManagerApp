import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/manager/user.dart' as app_user;
import 'package:manager/interfaces/shop_info.dart';
import 'package:manager/screens/home.dart';
import 'package:manager/screens/join.dart';

import 'package:manager/screens/profile.dart';
import 'package:manager/screens/search.dart';
import 'package:manager/util/const.dart';
import 'package:manager/widgets/badge.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.userInfo});

  final app_user.User userInfo;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  late app_user.User userInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setState(() {
      userInfo = widget.userInfo;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      API().clearToken(
          secret: 'my_secret_1234',
          username: FirebaseAuth.instance.currentUser!.displayName!);
    }
    setState(() {
      _lastLifecycleState = state;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> afterAddShop(String shopName) async {
    User user = FirebaseAuth.instance.currentUser!;
    String uid = user.uid;
    String phoneNumber = user.phoneNumber ?? '';
    ShopInfo shopInfo =
        ShopInfo(uid: uid, name: shopName, phoneNumber: phoneNumber);
    updateShopList(shopInfo);
  }

  void afterDeleteShop(ShopInfo shopInfo) {
    updateShopList(shopInfo, mode: '-');
  }

  void updateShopList(ShopInfo shopInfo, {String mode = '+'}) {
    setState(() {
      if (mode == '+') {
        userInfo.shopList.add(shopInfo);
      } else if (mode == '-') {
        userInfo.shopList.remove(shopInfo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Size screenSize = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          /* leading: Builder(builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.menu)),
            );
          }), */
          centerTitle: true,
          title: Text(
            Constants.appName,
          ),
          elevation: 0.0,
          /* actions: <Widget>[
            IconButton(
              icon: const IconBadge(
                icon: Icons.notifications,
                size: 22.0,
              ),
              onPressed: () {},
              tooltip: "Notifications",
            ),
          ], */
        ),
        body: Home(
          shopList: widget.userInfo.shopList,
          afterAddShop: afterAddShop,
          afterDeleteShop: afterDeleteShop,
        ),
        bottomNavigationBar: BottomAppBar(
          color: Theme.of(context).primaryColor,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const SizedBox(width: 7),
              IconButton(
                icon: const Icon(
                  Icons.home,
                  size: 24.0,
                ),
                color: Theme.of(context).colorScheme.secondary,
                onPressed: () {},
              ),
              IconButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Logging out'),
                          content: const Text('Are you sure?'),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  logout();
                                },
                                child: const Text('Logout')),
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'))
                          ],
                        );
                      }),
                  icon: const Icon(Icons.logout)),
              const SizedBox(width: 7),
            ],
          ),
        ),
      ),
    );
  }
}
