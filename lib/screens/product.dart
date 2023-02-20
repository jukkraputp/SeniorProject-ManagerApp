import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:manager/util/select_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class AddNewProduct extends StatefulWidget {
  final Future<void> Function(
      {String? id,
      Uint8List? image,
      required String name,
      required double price,
      required double time,
      required String type,
      required bool available,
      String? url}) saveProduct;
  final List<String> menuTypeList;
  final Item? item;
  final bool removable;
  final Future<bool> Function(String, Item)? removeProduct;
  final String theme;
  String? selectedType;

  AddNewProduct(
      {super.key,
      required this.saveProduct,
      required this.menuTypeList,
      this.item,
      this.removable = false,
      this.removeProduct,
      this.theme = 'light',
      this.selectedType});

  @override
  State<AddNewProduct> createState() => _AddNewProductState();
}

class _AddNewProductState extends State<AddNewProduct> {
  final TextEditingController _nameControl = TextEditingController();
  final TextEditingController _priceControl = TextEditingController();
  final TextEditingController _timeControl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String dropdownValue;
  XFile? _image;
  Uint8List? _bytesImage;
  bool _saveable = false;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    setState(() {
      dropdownValue = widget.selectedType ?? widget.menuTypeList.first;
      if (widget.item != null) {
        _nameControl.text = widget.item!.name;
        _priceControl.text = widget.item!.price.toString();
        _timeControl.text = widget.item!.time.toString();
        _saveable = true;
        _available = widget.item!.available;
      }
    });
  }

/*   Future<void> selectImage() async {
    if (await Permission.storage.request().isGranted) {
      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        Uint8List bytes = await image.readAsBytes();
        setState(() {
          _image = image;
          _bytesImage = bytes;
          _saveable = true;
        });
      }
    }
  } */

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double spaceBetween = 10;
    double imageSize = 150;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Product'),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 25, right: 25),
            children: <Widget>[
              // ---------- Type ----------------- //
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: <Widget>[
                      const Text('Category: '),
                      SizedBox(
                        width: spaceBetween,
                      ),
                      DropdownButton(
                        value: dropdownValue,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: const TextStyle(color: Colors.black),
                        underline: Container(height: 2, color: Colors.black),
                        onChanged: (String? value) {
                          setState(() {
                            dropdownValue = value!;
                          });
                        },
                        items: widget.menuTypeList
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  if (widget.removable)
                    Row(
                      children: <Widget>[
                        VerticalDivider(
                          width: screenSize.width * 0.1,
                        ),
                        const Text('Available:'),
                        Switch(
                            value: _available,
                            onChanged: (bool value) {
                              setState(() {
                                _available = value;
                              });
                            })
                      ],
                    ),
                ],
              )),

              // ---------- Name ----------------- //
              SizedBox(
                height: spaceBetween,
              ),
              const Center(
                child: Text('Name'),
              ),
              Card(
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
                      contentPadding: const EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      hintText: "Name",
                    ),
                    maxLines: 1,
                    controller: _nameControl,
                  ),
                ),
              ),
              // ---------- Price ----------------- //
              SizedBox(
                height: spaceBetween,
              ),
              const Center(
                child: Text('Price'),
              ),
              Card(
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
                      contentPadding: const EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      hintText: "Price",
                    ),
                    maxLines: 1,
                    controller: _priceControl,
                  ),
                ),
              ),
              // ---------- Time ----------------- //
              SizedBox(
                height: spaceBetween,
              ),
              const Center(
                child: Text('Time (Minute)'),
              ),
              Card(
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
                      contentPadding: const EdgeInsets.all(10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      hintText: "Time (Minute)",
                    ),
                    maxLines: 1,
                    controller: _timeControl,
                  ),
                ),
              ),
              // ------------------ Image ----------------- //
              SizedBox(
                height: spaceBetween,
              ),
              if (_bytesImage != null)
                Image(
                    width: imageSize,
                    height: imageSize,
                    image: MemoryImage(_bytesImage!))
              else if (widget.item != null)
                CachedNetworkImage(
                    width: imageSize * 0.9,
                    height: imageSize * 0.9,
                    imageUrl: widget.item!.image),
              SizedBox(
                height: spaceBetween,
              ),
              // ---------- upload image button ---------- //
              Container(
                padding: const EdgeInsets.only(left: 100, right: 100),
                width: 200,
                height: 50,
                child: TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).toggleableActiveColor),
                  onPressed: () async {
                    var res = await selectImage(_picker);
                    if (res != null) {
                      setState(() {
                        if (res.image != null) {
                          _image = res.image;
                        }
                        _bytesImage = res.bytes;
                        _saveable = true;
                      });
                    } else {
                      setState(() {
                        _saveable = false;
                      });
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(
                        Icons.upload,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: spaceBetween / 2,
                      ),
                      const Text(
                        'Upload Photo',
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: spaceBetween,
              ),
              // ---------- save button ---------- //
              if (_saveable)
                Container(
                  padding: const EdgeInsets.only(left: 100, right: 100),
                  width: 200,
                  height: 50,
                  child: TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      double price = double.parse(_priceControl.text);
                      double time = double.parse(_timeControl.text);
                      if (_bytesImage != null) {
                        widget
                            .saveProduct(
                                type: dropdownValue,
                                name: _nameControl.text,
                                price: price,
                                time: time,
                                image: _bytesImage,
                                available: _available)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else {
                        widget
                            .saveProduct(
                                type: dropdownValue,
                                name: _nameControl.text,
                                price: price,
                                time: time,
                                url: widget.item!.image,
                                id: widget.item!.id,
                                available: _available)
                            .then((value) => Navigator.of(context).pop());
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.save,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: spaceBetween / 2,
                        ),
                        const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height: spaceBetween,
              ),
              // ---------- remove button ---------- //
              if (widget.removable)
                Container(
                  padding: const EdgeInsets.only(left: 100, right: 100),
                  width: 200,
                  height: 50,
                  child: TextButton(
                    style: TextButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => widget.removeProduct!
                            (dropdownValue, widget.item!)
                        .then((value) {
                      if (value) {
                        Navigator.of(context).pop();
                      } else {
                        print('something wrong');
                      }
                    }),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: spaceBetween / 2,
                        ),
                        const Text(
                          'Remove',
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                )
            ],
          ),
        ));
  }
}
