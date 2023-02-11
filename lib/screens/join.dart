import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/network.dart';
import 'package:manager/screens/login.dart';
import 'package:manager/screens/main_screen.dart';
import 'package:manager/screens/register.dart';
import 'package:flutter/services.dart';
import 'package:manager/interfaces/manager/user.dart' as AppUser;

class JoinApp extends StatefulWidget {
  const JoinApp({super.key});

  @override
  _JoinAppState createState() => _JoinAppState();
}

class _JoinAppState extends State<JoinApp> with SingleTickerProviderStateMixin {
  final API api = API();

  late TabController _tabController;
  bool _auth = false;
  bool _loggedIn = false;

  /* Map _source = {ConnectivityResult.none: false};
  final NetworkConnectivity _networkConnectivity = NetworkConnectivity.instance;
  String string = ''; */

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 2);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    /* _networkConnectivity.initialise();
    _networkConnectivity.myStream.listen((source) {
      _source = source;
      print('source $_source');
      // 1.
      switch (_source.keys.toList()[0]) {
        case ConnectivityResult.mobile:
          string =
              _source.values.toList()[0] ? 'Mobile: Online' : 'Mobile: Offline';
          break;
        case ConnectivityResult.wifi:
          string =
              _source.values.toList()[0] ? 'WiFi: Online' : 'WiFi: Offline';
          break;
        case ConnectivityResult.none:
        default:
          string = 'Offline';
      }
      // 2.
      setState(() {});
      // 3.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            string,
            style: TextStyle(fontSize: 30),
          ),
        ),
      );
    }); */

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');

        if (_auth) {
          Navigator.of(context).popUntil((route) {
            if (route.settings.name == 'JoinApp') {
              setState(() {
                _loggedIn = false;
              });
              return true;
            }
            return false;
          });
        }
        setState(() {
          _auth = false;
        });
      } else {
        print('User is sign in!');
        setState(() {
          _auth = true;
        });
      }
    });
  }

  Future<dynamic> anonymousLogin() async {
    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInAnonymously();
      return credential;
    } catch (e) {
      print('anonymous');
      print(e);
    }
  }

  Future<dynamic> login(
      {String username = '', String password = '', String? uid}) async {
    if (uid == null) {
      try {
        print('logging in as $username');
        final UserCredential credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: '$username@gmail.com', password: password);
        print('logged in');
        if (credential.user != null) {
          uid = credential.user!.uid;
        } else {
          print('sign in error');
          return false;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
          return 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          print('Wrong password provided for that user.');
          return 'Wrong password provided for that user.';
        }
      } catch (e) {
        print('login');
        print(e);
      }
    }

    if (uid != null) {
      api.getUserInfo(uid).then((value) {
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
  }

  Future<bool> register(String username, String password) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: '$username@gmail.com',
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
    await login(username: username, password: password);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_auth & (FirebaseAuth.instance.currentUser != null) & !_loggedIn) {
      login(uid: FirebaseAuth.instance.currentUser!.uid);
      setState(() {
        _loggedIn = true;
      });
    }
    return WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.keyboard_backspace,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: _loggedIn
                ? null
                : TabBar(
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
          body: _loggedIn
              ? null
              : TabBarView(
                  controller: _tabController,
                  children: <Widget>[
                    LoginScreen(
                      auth: _auth,
                      login: login,
                    ),
                    RegisterScreen(
                      auth: _auth,
                    ),
                  ],
                ),
        ),
        onWillPop: () => Future.value(false));
  }
}
