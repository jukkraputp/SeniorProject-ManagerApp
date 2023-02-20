import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/network.dart';
import 'package:manager/interfaces/register.dart';
import 'package:manager/screens/login.dart';
import 'package:manager/screens/main_screen.dart';
import 'package:manager/screens/register.dart';
import 'package:flutter/services.dart';
import 'package:manager/interfaces/manager/user.dart' as app_user;
import 'package:manager/util/const.dart';
import 'package:manager/widgets/alerts.dart';

class JoinApp extends StatefulWidget {
  const JoinApp({super.key});

  @override
  _JoinAppState createState() => _JoinAppState();
}

class _JoinAppState extends State<JoinApp> with SingleTickerProviderStateMixin {
  final API api = API();

  late TabController _tabController;
  bool _auth = false;
  bool navigated = false;
  // late StreamSubscription<User?> authListener;

  /* Map _source = {ConnectivityResult.none: false};
  final NetworkConnectivity _networkConnectivity = NetworkConnectivity.instance;
  String string = ''; */

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  Future<User?> login({String username = '', String password = ''}) async {
    User? user;
    try {
      getEmailResult getEmail = await api.getEmail(username, password);
      String? email;
      if (getEmail.success) {
        var data = getEmail.data;
        email = data!['email'];
      }
      print('logging in as $email');
      final UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: '$email', password: password);
      print('logged in');
      if (credential.user != null) {
        if (credential.user!.emailVerified) {
          setState(() {
            _auth = true;
          });
        }
        return user;
      } else {
        print('sign in error');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
        // return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        // return 'Wrong password provided for that user.';
      }
    } catch (e) {
      print('login');
      print(e);
    }
    return user;
  }

  Future<RegisterResult> register(
      {String? username,
      String? email,
      String? password,
      String? phoneNumber}) async {
    if (username == null ||
        email == null ||
        password == null ||
        phoneNumber == null) return RegisterResult();
    print('registering');
    try {
      var res = await api.register(
          username: username,
          email: email,
          password: password,
          phoneNumber: phoneNumber);
      print(res);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
      return RegisterResult(success: false, message: e.code);
    } catch (e) {
      print(e);
      return RegisterResult(success: false, message: e.toString());
    }
    User? user = await login(username: username, password: password);
    if (user != null && !user.emailVerified) {
      // await user.sendEmailVerification();
      /* showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Email Verification has been sent.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'))
            ],
          );
        },
      ); */
    }
    return RegisterResult(success: true);
  }

  @override
  Widget build(BuildContext context) {
    print('currentUser: ${FirebaseAuth.instance.currentUser}');
    print('auth: $_auth');
    if (FirebaseAuth.instance.currentUser != null) {
      api.getEmail('jukkraputp', 'jukkraputp').then((value) {
        print('getEmail: ${value.success}');
        if (value.success) {
          var data = value.data;
          print('data: ${data!["email"]}');
        }
      });
    }

    if (_auth & !navigated) {
      api.getManagerInfo(FirebaseAuth.instance.currentUser!).then((value) {
        setState(() {
          navigated = true;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
              builder: (BuildContext context) {
                return MainScreen(
                  userInfo: value!,
                );
              },
              settings: const RouteSettings(name: 'MainScreen')),
        );
      });
    }
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Center(
              child: Text(Constants.appName),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.secondary,
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w800,
              ),
              tabs: const <Widget>[
                Tab(
                  text: "Login",
                ),
                Tab(
                  text: "Register",
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: <Widget>[
              LoginScreen(
                auth: _auth,
                login: login,
              ),
              RegisterScreen(
                auth: _auth,
                register: register,
              ),
            ],
          ),
        ),
        onWillPop: () => Future.value(false));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
