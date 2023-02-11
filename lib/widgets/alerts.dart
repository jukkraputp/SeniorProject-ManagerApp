import 'package:flutter/material.dart';
import 'package:manager/widgets/buttons.dart';

class MyAlert {
  AlertDialog error({void Function()? fn}) {
    return AlertDialog(
      title: Text('Error'),
      content: Text('Error has occur. Please contact admin.'),
      actions: [MyButton().okButton(fn: fn)],
    );
  }

  AlertDialog complete({void Function()? fn}) {
    return AlertDialog(
      title: const Text('Complete'),
      content: const Text('Datas have been saved.'),
      actions: [MyButton().okButton(fn: fn)],
    );
  }
}
