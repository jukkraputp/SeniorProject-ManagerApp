import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/history.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:lottie/lottie.dart';
import 'package:manager/interfaces/order.dart';
import 'package:manager/interfaces/shop_info.dart';
import 'package:manager/screens/history.dart';
import 'package:manager/screens/product.dart';
import 'package:manager/screens/add_new_type.dart';
import 'package:manager/util/number.dart';
import 'package:manager/widgets/alerts.dart';
import 'package:manager/widgets/badge.dart';

class ShopManager extends StatefulWidget {
  ShopManager(
      {super.key,
      required this.shopInfo,
      required this.menuList,
      required this.menuTypeList,
      required this.historyList,
      required this.updateMenuType,
      required this.deleteMenuType,
      required this.afterUpdate,
      required this.deleteShop,
      required this.afterDeleteShop,
      required this.updateHistory});

  final ShopInfo shopInfo;
  final MenuList menuList;
  List<String> menuTypeList;
  final List<Order> historyList;
  final void Function(String, String) updateMenuType;
  final void Function(String, String) deleteMenuType;
  final void Function(String) afterUpdate;
  final Future<void> Function(String) deleteShop;
  final void Function(ShopInfo) afterDeleteShop;
  final Future<List<Order>> Function(ShopInfo, List<Order>, {String mode})
      updateHistory;

  @override
  State<ShopManager> createState() => _ShopManagerState();
}

class _ShopManagerState extends State<ShopManager>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final API api = API();
  late MenuList menuList;

  String? _selectedType;
  bool _ready = false;
  List<Widget> _menuTypeButtons = [];
  ListView _bodies = ListView();
  bool _editing = false;
  Map<String, List<Item>> needUpdateObj = {};
  Map<String, int> latestId = {};
  bool _saving = false;
  bool _deleting = false;
  bool _hasType = false;

  @override
  void initState() {
    super.initState();
    Map<String, List<Item>> tempObj = {};
    Map<String, int> id = {};
    for (var type in widget.menuTypeList) {
      id[type] = widget.menuList.menu[type]!.length;
    }
    setState(() {
      latestId = id;
      if (widget.menuTypeList.isNotEmpty) {
        _selectedType = widget.menuTypeList.first;
      }
      _menuTypeButtons = createMenuTypeButtons();
      needUpdateObj = tempObj;
      menuList = initMenu();
    });
  }

  MenuList initMenu() {
    MenuList newMenuList = MenuList(typesList: widget.menuTypeList);
    for (var menuType in widget.menuTypeList) {
      for (var item in widget.menuList.menu[menuType]!) {
        newMenuList.menu[menuType]!.add(item);
      }
    }
    return newMenuList;
  }

  Future<bool> setNewType(String typeName) async {
    widget.updateMenuType(widget.shopInfo.name, typeName);
    var res = await api.setNewType(
        FirebaseAuth.instance.currentUser!.uid, widget.shopInfo.name, typeName);
    print(res.statusCode);
    if (res.statusCode == 200) {
      setState(() {
        latestId[typeName] = 0;
        menuList.menu[typeName] = [];
        _selectedType = typeName;
        _hasType = true;
      });
      return true;
    }
    return false;
  }

  List<Widget> createMenuTypeButtons() {
    List<Widget> buttons = [];
    for (var foodType in widget.menuTypeList) {
      buttons.add(Container(
          margin: const EdgeInsets.all(1),
          child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = foodType;
                });
              },
              style: ButtonStyle(
                backgroundColor: _selectedType == foodType
                    ? MaterialStateProperty.all(Colors.black)
                    : MaterialStateProperty.all(Colors.grey.shade400),
              ),
              child: Text(
                foodType,
                style: TextStyle(
                    color: _selectedType == foodType
                        ? Colors.white
                        : Colors.black),
              ))));
    }

    if (!_editing) {
      // ---------- + Button ---------- //
      buttons.add(Container(
        decoration:
            const BoxDecoration(border: Border(right: BorderSide(width: 2))),
        child: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return AddNewType(
                  setNewType: setNewType,
                );
              }));
            },
            child: const Text('+')),
      ));

      if (_selectedType != null) {
        // ---------- - Button ---------- //
        buttons.add(TextButton(
            onPressed: _selectedType != null ? _confirmDelete : null,
            child: const Icon(
              Icons.delete,
              color: Colors.red,
            )));
      }
    }

    return buttons;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          title: const Text(
            'Confirm Delete',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                // Perform delete action
                if (_selectedType != null) {
                  setState(() {
                    _deleting = true;
                  });
                  api
                      .deleteType(FirebaseAuth.instance.currentUser!.uid,
                          widget.shopInfo.name, _selectedType!)
                      .whenComplete(() {
                    widget.deleteMenuType(widget.shopInfo.name, _selectedType!);
                    setState(() {
                      _deleting = false;
                      _hasType = false;
                      menuList.menu.remove(_selectedType);
                      if (widget.menuTypeList.isNotEmpty) {
                        _selectedType = widget.menuTypeList.first;
                      } else {
                        _selectedType = null;
                      }
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: const Text(
                'Yes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void editProduct(Item item, {bool removable = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddNewProduct(
            saveProduct: saveProduct,
            menuTypeList: widget.menuTypeList,
            item: item,
            removable: removable,
            removeProduct: removeProduct,
            selectedType: _selectedType,
          );
        },
      ),
    );
  }

  Future<bool> removeProduct(String type, Item item) async {
    item.delete = true;
    if (needUpdateObj.containsKey(type)) {
      List<Item> temp = needUpdateObj[type]!;
      int? index = item.idIn(temp);
      if (index != null) {
        temp[index] = item;
      } else {
        temp.add(item);
      }
      setState(() {
        menuList.menu[type]!.remove(item);
        needUpdateObj[type] = temp;
      });
      return true;
    } else {
      return false;
    }
  }

  ListView createListView() {
    double imgSize = 75;
    Size screenSize = MediaQuery.of(context).size;
    late ListView widgets;
    if (menuList.menu.containsKey(_selectedType)) {
      widgets = ListView.builder(
          itemCount: menuList.menu[_selectedType]!.length,
          itemBuilder: ((BuildContext context, int index) {
            Item item = menuList.menu[_selectedType]![index];
            late num itemPrice;
            if (isInteger(item.price)) {
              itemPrice = item.price.toInt();
            } else {
              itemPrice = item.price;
            }
            return Container(
                margin:
                    const EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 5),
                child: TextButton(
                  onPressed: _editing
                      ? () => editProduct(menuList.menu[_selectedType]![index],
                          removable: true)
                      : () {},
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        item.bytes != null
                            ? Image.memory(
                                item.bytes!,
                                width: imgSize,
                                height: imgSize,
                                fit: BoxFit.cover,
                                color: item.available ? null : Colors.grey,
                                colorBlendMode: item.available
                                    ? null
                                    : BlendMode.saturation,
                              )
                            : CachedNetworkImage(
                                width: imgSize,
                                height: imgSize,
                                fit: BoxFit.cover,
                                imageUrl:
                                    menuList.menu[_selectedType]![index].image,
                                color: item.available ? null : Colors.grey,
                                colorBlendMode: item.available
                                    ? null
                                    : BlendMode.saturation,
                              ),
                        Text(
                          menuList.menu[_selectedType]![index].name,
                          textAlign: TextAlign.center,
                        ),
                        Text('$itemPrice  บาท')
                      ]),
                ));
          }));
    } else {
      widgets = ListView();
    }
    return widgets;
  }

  void saveNewItem(String type, Item newItem) {
    List<Item> itemList = menuList.menu[type]!;
    itemList.add(newItem);
    setState(() {
      menuList.menu[type] = itemList;
    });
  }

  void saveEdit(String type, Item item) {
    List<Item> itemList = menuList.menu[type]!;
    for (var i = 0; i < itemList.length; i++) {
      if (itemList[i].id == item.id) {
        itemList[i] = item;
        break;
      }
    }
    setState(() {
      menuList.menu[type] = itemList;
    });
  }

  Future<void> saveProduct(
      {required String type,
      required String name,
      required double price,
      required double time,
      required bool available,
      Uint8List? image,
      String? url,
      String? id,
      String? productDetail}) async {
    bool exist = true;
    if (id == null) {
      exist = false;
      if (latestId[type] != null) {
        id = '$type-${latestId[type]}';
        int newId = latestId[type]! + 1;
        setState(() {
          latestId[type] = newId;
        });
      } else {
        print('Error: lastest[$type] is null.');
      }
    }
    late String imageUrl;
    if (url == null) {
      imageUrl = '';
    } else {
      imageUrl = url;
    }
    Item newItem = Item(
        name: name,
        price: price,
        time: time,
        image: imageUrl,
        id: id!,
        bytes: image,
        available: available,
        productDetail: productDetail);
    List<Item> updateList = needUpdateObj[type] ?? [];
    int? index = newItem.idIn(updateList);
    if (index == null) {
      updateList.add(newItem);
    } else {
      updateList[index] = newItem;
    }
    setState(() {
      needUpdateObj[type] = updateList;
    });
    if (exist) {
      saveEdit(type, newItem);
    } else {
      saveNewItem(type, newItem);
    }
  }

  Future<void> updateFirebase() async {
    if (await api.updateStorageData(widget.shopInfo.name,
        FirebaseAuth.instance.currentUser!.uid, needUpdateObj)) {
      widget.afterUpdate(widget.shopInfo.name);
      setState(() {
        _editing = false;
      });
    }
  }

  Future<void> cancelEdit() async {
    setState(() {
      _editing = false;
      needUpdateObj = {};
      menuList = initMenu();
      _bodies = createListView();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;
    double iconSize = 24;
    if ((_menuTypeButtons != []) & (_bodies != ListView()) & !_ready) {
      setState(() {
        _bodies = createListView();
        _ready = true;
      });
    } else {
      setState(() {
        _menuTypeButtons = createMenuTypeButtons();
        _bodies = createListView();
      });
    }
    var _text = _Text().thai;

    print(menuList.menu.keys);
    if (menuList.menu.keys.isEmpty) {
      setState(() {
        _hasType = false;
      });
    } else {
      setState(() {
        _hasType = true;
      });
    }

    return Scaffold(
      key: _key,
      endDrawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            // Shop name
            SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  widget.shopInfo.name,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            // // Edit Button
            // ListTile(
            //   onTap: () {
            //     Navigator.of(context).pop();
            //     setState(() {
            //       _editing = true;
            //     });
            //   },
            //   leading: IconBadge(
            //     icon: Icons.edit,
            //     size: iconSize,
            //   ),
            //   title: Text(
            //     _text.edit,
            //     style: const TextStyle(fontSize: 20),
            //   ),
            // ),
            // Stat
            ListTile(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: ((context) {
                return HistoryScreen(
                  shopInfo: widget.shopInfo,
                  listOfHistory: widget.historyList,
                  updateHistory: widget.updateHistory,
                );
              }))),
              leading: IconBadge(
                icon: Icons.receipt,
                size: iconSize,
              ),
              title: Text(
                _text.stat,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            // Gen Reception Code Button
            ListTile(
              onTap: () async {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                        child: Lottie.asset(
                            'assets/animations/colors-circle-loader.json'),
                      );
                    });
                String token = await api.generateToken(
                    shopName: widget.shopInfo.name,
                    uid: FirebaseAuth.instance.currentUser!.uid);
                setState(() {
                  Navigator.of(context).pop();
                  widget.shopInfo.reception = token;
                });
              },
              leading: IconBadge(
                icon: Icons.numbers,
                size: iconSize,
              ),
              title: Text(
                widget.shopInfo.reception != null
                    ? 'Reception Token: ${widget.shopInfo.reception}'
                    : _text.genReceptionCode,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            // Gen Chef Code Button
            ListTile(
              onTap: () async {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                        child: Lottie.asset(
                            'assets/animations/colors-circle-loader.json'),
                      );
                    });
                String token = await api.generateToken(
                    shopName: widget.shopInfo.name,
                    uid: FirebaseAuth.instance.currentUser!.uid,
                    mode: 'Chef');
                setState(() {
                  Navigator.of(context).pop();
                  widget.shopInfo.chef = token;
                });
              },
              leading: IconBadge(
                icon: Icons.numbers,
                size: iconSize,
              ),
              title: Text(
                widget.shopInfo.chef != null
                    ? 'Chef Token: ${widget.shopInfo.chef}'
                    : _text.genChefCode,
                style: const TextStyle(fontSize: 20),
              ),
            ),

            // Delete Shop Button
            ListTile(
              onTap: () {
                showDialog(
                    context: context,
                    builder: ((context) {
                      return AlertDialog(
                        title: const Text('กำลังลบร้านค้า'),
                        content: const Text('ยืนยันการลบ ?'),
                        actions: <Widget>[
                          TextButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Center(
                                        child: Lottie.asset(
                                            'assets/animations/colors-circle-loader.json'),
                                      );
                                    });
                                widget
                                    .deleteShop(widget.shopInfo.name)
                                    .whenComplete(() {
                                  widget.afterDeleteShop(widget.shopInfo);
                                  Navigator.of(context).popUntil((route) {
                                    if (route.settings.name == 'MainScreen') {
                                      return true;
                                    }
                                    return false;
                                  });
                                });
                              },
                              child: const Text('ลบ')),
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('ยกเลิก'))
                        ],
                      );
                    }));
              },
              leading: IconBadge(
                icon: Icons.delete_forever,
                size: iconSize,
              ),
              title: Text(
                _text.delete,
                style: const TextStyle(fontSize: 20),
              ),
            )
          ],
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: _editing
            ? IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                ),
                onPressed: () => cancelEdit(),
                tooltip: 'Cancel',
              )
            : IconButton(
                icon: const Icon(
                  Icons.keyboard_backspace,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        centerTitle: true,
        title: Text(
          'ร้าน ${widget.shopInfo.name}',
        ),
        actions: _hasType
            ? <Widget>[
                _editing
                    ? Row(
                        children: _saving
                            ? [
                                Center(
                                  child: Lottie.asset(
                                      'assets/animations/colors-circle-loader.json'),
                                )
                              ]
                            : [
                                IconButton(
                                  icon: IconBadge(
                                    icon: Icons.add,
                                    size: iconSize,
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return AddNewProduct(
                                          saveProduct: saveProduct,
                                          menuTypeList: widget.menuTypeList,
                                          selectedType: _selectedType,
                                          removable: false,
                                        );
                                      },
                                    ),
                                  ),
                                  tooltip: "Add",
                                ),
                                IconButton(
                                  icon: IconBadge(
                                    icon: Icons.check,
                                    size: iconSize,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _saving = true;
                                    });
                                    updateFirebase().then((value) {
                                      setState(() {
                                        _saving = false;
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return MyAlert().complete(
                                                fn: () => Navigator.of(context)
                                                    .pop());
                                          },
                                        );
                                      });
                                    });
                                  },
                                  tooltip: "Done",
                                )
                              ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: <Widget>[
                            TextButton(
                              onPressed: () => setState(() {
                                _editing = true;
                              }),
                              style: TextButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).backgroundColor),
                              child: Text(
                                'เพิ่มและแก้ไขเมนู',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            IconButton(
                              icon: IconBadge(
                                icon: Icons.menu,
                                size: iconSize,
                              ),
                              onPressed: () =>
                                  _key.currentState!.openEndDrawer(),
                              tooltip: "Menu",
                            ),
                          ],
                        ))
              ]
            : null,
      ),
      body: _hasType
          ? ((_ready & !_saving & !_deleting)
              ? _bodies
              : Center(
                  child: Lottie.asset(
                      'assets/animations/colors-circle-loader.json'),
                ))
          : Container(
              decoration: BoxDecoration(),
              height: screenSize.height * 0.8,
              child: Center(
                  child: TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (BuildContext context) {
                    return AddNewType(
                      setNewType: setNewType,
                    );
                  }));
                },
                style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context)
                            .buttonTheme
                            .colorScheme
                            ?.primaryContainer ??
                        Colors.black),
                child: const Text(
                  'สร้างหมวดหมู่อาหารแรกของร้าน',
                  style: TextStyle(color: Colors.white),
                ),
              )),
            ),
      bottomNavigationBar: _hasType
          ? BottomAppBar(
              color: Theme.of(context).primaryColor,
              shape: const CircularNotchedRectangle(),
              child: SizedBox(
                  height: 50,
                  child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _menuTypeButtons)),
            )
          : null,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Text {
  _TH thai = _TH();
  _EN englist = _EN();
}

class _TH {
  String edit = 'แก้ไข';
  String genReceptionCode = 'สร้างรหัสสำหรับ POS ของพนักงานต้อนรับ';
  String genChefCode = 'สร้างรหัสสำหรับ POS ของคนทำอาหาร';
  String stat = 'ดูข้อมูลการขาย';
  String delete = 'ลบร้านค้านี้';
}

class _EN {
  String edit = 'Edit';
  String genReceptionCode = 'Generate POS Code (Reception)';
  String genChefCode = 'Generate POS Code (Chef)';
  String stat = 'Statistic';
  String delete = 'Delete this shop';
}
