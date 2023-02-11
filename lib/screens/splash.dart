import 'dart:async';
import 'package:manager/screens/join.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager/util/const.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key, required this.debug});

  bool debug;

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTimeout() {
    return Timer(const Duration(seconds: 2), changeScreen);
  }

  changeScreen() async {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (BuildContext context) {
            return const JoinApp();
          },
          settings: const RouteSettings(name: 'JoinApp')),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    startTimeout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
}
