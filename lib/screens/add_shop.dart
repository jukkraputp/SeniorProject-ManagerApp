import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:manager/apis/api.dart';

class AddShop extends StatefulWidget {
  const AddShop(
      {super.key,
      required this.afterAddShop,
      required this.position,
      required this.center,
      required this.marker});

  final Position position;
  final google_map.LatLng center;
  final google_map.Marker marker;
  final Future<void> Function(String) afterAddShop;

  @override
  State<AddShop> createState() => _AddShopState();
}

class _AddShopState extends State<AddShop> {
  final TextEditingController _nameControl = TextEditingController();

  final Completer<google_map.GoogleMapController> _mapController = Completer();

  late google_map.Marker _marker;
  late google_map.LatLng center;
  google_map.LatLng? markerPosition;
  Position? _position;
  bool _ready = false;
  double _zoom = 12;

  void _onMapCreated(google_map.GoogleMapController controller) {
    _mapController.complete(controller);
  }

  Future<void> _onMarkerDrag(google_map.LatLng newPosition) async {
    _setPosition(newPosition);
  }

  Future<void> _onMarkerDragEnd(google_map.LatLng newPosition) async {
    google_map.Marker tappedMarker = _marker;
    setState(() {
      markerPosition = null;
    });
    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
              content: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 66),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Old position: ${tappedMarker.position}'),
                      Text('New position: $newPosition'),
                    ],
                  )));
        });
  }

  void _changePosition() {
    final google_map.Marker marker = _marker;
    final google_map.LatLng current = marker.position;
    final Offset offset = Offset(
      center.latitude - current.latitude,
      center.longitude - current.longitude,
    );
    setState(() {
      _marker = marker.copyWith(
        positionParam: google_map.LatLng(
          center.latitude + offset.dy,
          center.longitude + offset.dx,
        ),
      );
    });
  }

  void _setPosition(google_map.LatLng latLng) {
    final google_map.Marker marker = _marker;
    setState(() {
      _marker = marker.copyWith(
        positionParam: google_map.LatLng(latLng.latitude, latLng.longitude),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      _position = widget.position;
      center = widget.center;
      _marker = widget.marker;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    print('screenSize: $screenSize');
    return _ready
        ? GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Padding(
                padding: const EdgeInsets.all(5),
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Container(
                    constraints:
                        BoxConstraints(maxHeight: screenSize.height * 0.8),
                    child: Column(
                      children: <Widget>[
                        // ---------- Shop Name ----------------- //
                        const Expanded(
                          flex: 1,
                          child: Center(
                            child: Text('ชื่อร้านค้า'),
                          ),
                        ),

                        Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Card(
                                elevation: 3.0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5.0),
                                    ),
                                  ),
                                  child: TextField(
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.all(10.0),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.white,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(5.0),
                                      ),
                                      hintText: "ชื่อร้านค้า",
                                    ),
                                    maxLines: 1,
                                    controller: _nameControl,
                                  ),
                                ),
                              ),
                            )),

                        // ---------- Google Map  ---------- //
                        Expanded(
                            flex: 14,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: google_map.GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition:
                                    google_map.CameraPosition(
                                        target: google_map.LatLng(
                                            _position?.latitude ?? 20,
                                            _position?.longitude ?? 100),
                                        zoom: _zoom),
                                onCameraMove: (position) {
                                  print('zoom: ${position.zoom}');
                                  setState(() {
                                    _zoom = position.zoom;
                                  });
                                },
                                markers: <google_map.Marker>{_marker},
                                onTap: (argument) {
                                  print('latlng = $argument');
                                  _setPosition(argument);
                                },
                              ),
                            )),

                        // ---------- Save Button ---------- //
                        Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: TextButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () {
                                    if (_nameControl.text != '') {
                                      showDialog(
                                          context: context,
                                          builder: (context) {
                                            return Center(
                                              child: Lottie.asset(
                                                  'assets/animations/colors-circle-loader.json'),
                                            );
                                          });
                                      API()
                                          .addShop(
                                              uid: FirebaseAuth
                                                  .instance.currentUser!.uid,
                                              shopName: _nameControl.text,
                                              phoneNumber: FirebaseAuth.instance
                                                  .currentUser!.phoneNumber!,
                                              latLng: _marker.position)
                                          .then((value) {
                                        print(value.body);

                                        widget
                                            .afterAddShop(_nameControl.text)
                                            .whenComplete(() {
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        });
                                      });
                                    }
                                  },
                                  child: const Text(
                                    'Confirm',
                                    style: TextStyle(color: Colors.white),
                                  )),
                            )),
                      ],
                    ),
                  ),
                )))
        : Center(
            child: Lottie.asset('assets/animations/colors-circle-loader.json'),
          );
  }
}
