import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/manager/user.dart' as AppUser;
import 'package:manager/screens/home.dart';
import 'package:manager/screens/join.dart';

import 'package:manager/screens/profile.dart';
import 'package:manager/screens/search.dart';
import 'package:manager/util/const.dart';
import 'package:manager/widgets/badge.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.userInfo});

  final AppUser.User userInfo;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
          secret: 'my_secret_1234', username: widget.userInfo.username);
    }
    setState(() {
      _lastLifecycleState = state;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
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
          receptionToken: widget.userInfo.receptionToken,
          chefToken: widget.userInfo.chefToken,
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
                  onPressed: () => logout()
                  /* .then((value) => Navigator.of(context).popUntil((route) {
                            if (route.settings.name == 'JoinApp') {
                              return true;
                            } else {
                              return false;
                            }
                          })) */
                  ,
                  icon: const Icon(Icons.logout)),
              const SizedBox(width: 7),
            ],
          ),
        ),
      ),
    );
  }
}
