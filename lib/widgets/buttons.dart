import 'package:flutter/material.dart';

class MyButton {
  Widget okButton({void Function()? fn}) {
    return TextButton(
      onPressed: fn,
      child: const Text("OK"),
    );
  }

  Widget cancelButton({void Function()? fn}) {
    return TextButton(
      onPressed: fn,
      child: const Text("Cancel"),
    );
  }
}
