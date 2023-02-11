import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

class AddNewProduct extends StatefulWidget {
  final Future<void> Function(String, String, String,
      {Uint8List? image, String? url, String? id}) saveProduct;
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
  final ImagePicker _picker = ImagePicker();

  late String dropdownValue;
  XFile? _image;
  Uint8List? _bytesImage;
  bool _saveable = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      dropdownValue = widget.selectedType ?? widget.menuTypeList.first;
      if (widget.item != null) {
        _nameControl.text = widget.item!.name;
        _priceControl.text = widget.item!.price;
        _saveable = true;
      }
    });
  }

  Future<void> selectImage() async {
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
  }

  @override
  Widget build(BuildContext context) {
    double spaceBetween = 10;
    double imageSize = 150;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add New Product'),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 25, right: 25),
            children: <Widget>[
              // ---------- Type ----------------- //
              SizedBox(
                height: spaceBetween,
              ),
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                    width: imageSize,
                    height: imageSize,
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
                    await selectImage();
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
                      if (_bytesImage != null) {
                        widget
                            .saveProduct(dropdownValue, _nameControl.text,
                                _priceControl.text,
                                image: _bytesImage)
                            .then((value) {
                          Navigator.of(context).pop();
                        });
                      } else {
                        widget
                            .saveProduct(dropdownValue, _nameControl.text,
                                _priceControl.text,
                                url: widget.item!.image, id: widget.item!.id)
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
                height: spaceBetween * 10,
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
