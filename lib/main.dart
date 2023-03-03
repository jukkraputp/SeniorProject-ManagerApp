import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manager/providers/app_provider.dart';
import 'package:manager/screens/splash.dart';
import 'package:manager/util/const.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'firebase_options.dart';

const bool USE_EMULATOR = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /* await FirebaseAppCheck.instance
      .activate(androidProvider: AndroidProvider.playIntegrity); */
  if (USE_EMULATOR) {
    await _connectToFirebaseEmulator();
  }

  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const ManagerApp(),
    ),
  );
}

Future _connectToFirebaseEmulator() async {
  final localHostString = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  await FirebaseAuth.instance.useAuthEmulator(localHostString, 9099);
}

class ManagerApp extends StatelessWidget {
  const ManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder:
        (BuildContext context, AppProvider appProvider, Widget? child) {
      return MaterialApp(
        key: appProvider.key,
        debugShowCheckedModeBanner: false,
        navigatorKey: appProvider.navigatorKey,
        title: Constants.appName,
        theme: appProvider.theme,
        darkTheme: Constants.darkTheme,
        home: SplashScreen(debug: true),
      );
    });
  }
}
