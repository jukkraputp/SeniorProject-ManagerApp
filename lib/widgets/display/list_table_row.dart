import 'package:flutter/cupertino.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:manager/widgets/display/table_row.dart';

List<TableRow> genListTableRow(MenuList menuList, String content, int perRow) {
  List<TableRow> myWidget = <TableRow>[];

  final List<Item> items;
  var menuMap = menuList.menu;
  var menu = menuMap[content];
  menu != null ? items = menu : items = [];
  List<Item> itemList = <Item>[];
  for (var item in items) {
    itemList.add(item);
    if (itemList.length == perRow) {
      myWidget.add(genTableRow(itemList, perRow));
      itemList = <Item>[];
    }
  }
  if (itemList.isNotEmpty) {
    myWidget.add(genTableRow(itemList, perRow));
  }

  print('genListTableRow');
  print(myWidget);
  return myWidget;
}
