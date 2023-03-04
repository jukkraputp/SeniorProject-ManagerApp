import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/manager/user.dart' as manager_user;
import 'package:manager/screens/join.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager/screens/main_screen.dart';
import 'package:manager/util/const.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key, required this.debug});

  bool debug;

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late StreamSubscription<User?> authListener;
  bool _init = false;
  bool _auth = false;
  bool _loggedIn = false;
  late manager_user.User userInfo;

  startTimeout() {
    return Timer(const Duration(seconds: 2), changeScreen);
  }

  changeScreen() async {
    setState(() {
      _loggedIn = _auth;
    });
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) {
            return _auth ? MainScreen(userInfo: userInfo) : const JoinApp();
          },
          settings: RouteSettings(name: _auth ? 'MainScreen' : 'JoinApp')),
    );
  }

  @override
  void initState() {
    super.initState();
    authListener =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');

        if (_auth) {
          Navigator.of(context).popUntil((route) {
            if (route.isFirst) {
              setState(() {
                _auth = false;
                if (_loggedIn) {
                  changeScreen();
                }
              });
              return true;
            }
            return false;
          });
        }
      } else {
        print('User is sign in!');
        API().getManagerInfo(FirebaseAuth.instance.currentUser!).then((value) {
          setState(() {
            userInfo = value!;
            _auth = true;
            if (!_loggedIn & !_init) {
              changeScreen();
            }
          });
        });

        // email verification features
        /* if (user.emailVerified) {
          setState(() {
            _auth = true;
          });
        } else {
          FirebaseAuth.instance.signOut();
          setState(() {
            _auth = false;
          });
        } */
      }
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    startTimeout();
    setState(() {
      _init = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        margin: const EdgeInsets.only(left: 40.0, right: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(
                Icons.fastfood,
                size: 150.0,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 40.0),
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.only(
                  top: 15.0,
                ),
                child: Text(
                  Constants.appName,
                  style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    authListener.cancel();
    super.dispose();
  }
}
