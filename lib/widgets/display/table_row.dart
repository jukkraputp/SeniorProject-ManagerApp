import 'package:flutter/material.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/widgets/display/item_card.dart';

TableRow genTableRow(List<Item> items, int perRow) {
  List<Widget> cardList = <Widget>[];
  for (var item in items) {
    cardList.add(Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Container(
                child: genCard(item),
              )),
        ],
      ),
    ));
  }
  for (var i = 0; i < perRow - items.length; i++) {
    cardList.add(Container());
  }
  TableRow tableWidget = TableRow(children: cardList);

  print('tableWidget');
  print(tableWidget);
  return tableWidget;
}
