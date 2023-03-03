import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AddNewType extends StatefulWidget {
  const AddNewType({super.key, required this.setNewType});

  final Future<void> Function(String) setNewType;

  @override
  State<AddNewType> createState() => _AddNewTypeState();
}

class _AddNewTypeState extends State<AddNewType> {
  final TextEditingController _nameControl = TextEditingController();

  bool _saveable = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    double spaceBetween = MediaQuery.of(context).size.height / 5;
    if (_nameControl.value.text != '') {
      setState(() {
        _saveable = true;
      });
    } else {
      setState(() {
        _saveable = false;
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มหมวดหมู่ใหม่')),
      body: _saving
          ? Center(
              child:
                  Lottie.asset('assets/animations/colors-circle-loader.json'),
            )
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: ListView(
                padding: const EdgeInsets.only(left: 25, right: 25),
                children: [
                  // ---------- name ---------- //
                  SizedBox(
                    height: spaceBetween,
                  ),
                  const Center(
                    child: Text('ชื่อหมวดหมู่'),
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
                          hintText: "ชื่อหมวดหมู่",
                        ),
                        maxLines: 1,
                        controller: _nameControl,
                      ),
                    ),
                  ),
                  // ---------- save button ---------- //
                  SizedBox(
                    height: spaceBetween / 4,
                  ),
                  if (_saveable)
                    Container(
                      padding: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width / 4,
                          right: MediaQuery.of(context).size.width / 4),
                      width: 200,
                      height: 50,
                      child: TextButton(
                        style:
                            TextButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          setState(() {
                            _saving = true;
                          });
                          widget
                              .setNewType(_nameControl.value.text)
                              .whenComplete(() => Navigator.of(context).pop());
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                            ),
                            SizedBox(
                              width: spaceBetween / 4,
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
                ],
              ),
            ),
    );
  }
}
