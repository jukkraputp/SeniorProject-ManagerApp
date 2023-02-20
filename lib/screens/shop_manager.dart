import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/menu_list.dart';
import 'package:lottie/lottie.dart';
import 'package:manager/screens/product.dart';
import 'package:manager/screens/add_new_type.dart';
import 'package:manager/widgets/alerts.dart';
import 'package:manager/widgets/badge.dart';

class ShopManager extends StatefulWidget {
  const ShopManager(
      {super.key,
      required this.shopName,
      required this.menuList,
      required this.menuTypeList,
      required this.updateMenuType,
      required this.deleteMenuType,
      required this.afterUpdate,
      this.receptionToken,
      this.chefToken});

  final String shopName;
  final MenuList menuList;
  final List<String> menuTypeList;
  final void Function(String, String) updateMenuType;
  final void Function(String, String) deleteMenuType;
  final void Function(String) afterUpdate;
  final String? receptionToken;
  final String? chefToken;

  @override
  State<ShopManager> createState() => _ShopManagerState();
}

class _ShopManagerState extends State<ShopManager>
    with AutomaticKeepAliveClientMixin {
  final API api = API();

  String? _selectedType;
  bool _ready = false;
  List<Widget> _menuTypeButtons = [];
  ListView _bodies = ListView();
  bool _editing = false;
  Map<String, List<Item>> needUpdateObj = {};
  late MenuList menuList;
  Map<String, int> latestId = {};
  bool _saving = false;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  Map<String, String?> posToken = {};
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    api.getShopMenu(
        uid: FirebaseAuth.instance.currentUser!.uid, shopName: widget.shopName);
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
      posToken['Reception'] = widget.receptionToken;
      posToken['Chef'] = widget.chefToken;
    });
  }

  MenuList initMenu() {
    MenuList newMenu = MenuList(typesList: widget.menuTypeList);
    for (var menuType in widget.menuTypeList) {
      for (var item in widget.menuList.menu[menuType]!) {
        newMenu.menu[menuType]!.add(item);
      }
    }
    return newMenu;
  }

  Future<bool> setNewType(String typeName) async {
    widget.updateMenuType(widget.shopName, typeName);
    await api.setNewType(
        FirebaseAuth.instance.currentUser!.uid, widget.shopName, typeName);
    while (true) {
      if (widget.menuTypeList.contains(typeName)) {
        print('finished!');
        setState(() {
          latestId[typeName] = 0;
          menuList.menu[typeName] = [];
          _selectedType = typeName;
        });
        return true;
      }
    }
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

    // ---------- - Button ---------- //
    buttons.add(TextButton(
        onPressed: _confirmDelete,
        child: const Icon(
          Icons.delete,
          color: Colors.red,
        )));

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
                          widget.shopName, _selectedType!)
                      .whenComplete(() {
                    widget.deleteMenuType(widget.shopName, _selectedType!);
                    setState(() {
                      _deleting = false;
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
    print('$type, ${item.id}, ${item.name}');
    print(needUpdateObj);
    for (var element in needUpdateObj.keys) {
      print(element);
    }
    if (needUpdateObj.containsKey(type)) {
      print('deleting item');
      List<Item> temp = needUpdateObj[type]!;
      int? index = item.idIn(temp);
      if (index != null) {
        temp[index] = item;
      } else {
        temp.add(item);
      }
      print(temp);
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
            print('item-${item.name}: ${item.available}');
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
                        Text(
                            '${menuList.menu[_selectedType]![index].price}     ')
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
      print('itemList[i].id = ${itemList[i].id}');
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
      String? id}) async {
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
        available: available);
    List<Item> updateList = needUpdateObj[type] ?? [];
    int? index = newItem.idIn(updateList);
    print(index);
    if (index == null) {
      updateList.add(newItem);
    } else {
      updateList[index] = newItem;
    }
    print(updateList);
    for (var item in updateList) {
      print('updateList: ${item.id}, ${item.name}, ${item.price}');
    }
    setState(() {
      needUpdateObj[type] = updateList;
    });
    if (exist) {
      print('saveEdit: saving');
      saveEdit(type, newItem);
    } else {
      saveNewItem(type, newItem);
    }
  }

  Future<void> updateFirebase() async {
    if (await api.updateStorageData(widget.shopName,
        FirebaseAuth.instance.currentUser!.uid, needUpdateObj)) {
      widget.afterUpdate(widget.shopName);
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
    print('latestId: $latestId');
    double iconSize = 24;
    if ((_menuTypeButtons != []) & (_bodies != ListView()) & !_ready) {
      print('1');
      setState(() {
        _bodies = createListView();
        _ready = true;
      });
    } else {
      print('2');
      setState(() {
        _menuTypeButtons = createMenuTypeButtons();
        _bodies = createListView();
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
            SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  widget.shopName,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                setState(() {
                  _editing = true;
                });
              },
              leading: IconBadge(
                icon: Icons.edit,
                size: iconSize,
              ),
              title: const Text(
                'Edit',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              onTap: posToken['Reception'] == null
                  ? () async {
                      String token = await api.generateToken(
                          shopName: widget.shopName,
                          uid: FirebaseAuth.instance.currentUser!.uid);
                      setState(() {
                        posToken['Reception'] = token;
                      });
                      print(token);
                    }
                  : null,
              leading: IconBadge(
                icon: Icons.receipt,
                size: iconSize,
              ),
              title: Text(
                posToken['Reception'] != null
                    ? 'Reception Token: ${posToken['Reception']!}'
                    : 'Generate POS Code (Reception)',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              onTap: posToken['Chef'] == null
                  ? () async {
                      String token = await api.generateToken(
                          shopName: widget.shopName,
                          uid: FirebaseAuth.instance.currentUser!.uid,
                          mode: 'Chef');
                      setState(() {
                        posToken['Chef'] = token;
                      });
                      print(token);
                    }
                  : null,
              leading: IconBadge(
                icon: Icons.food_bank,
                size: iconSize,
              ),
              title: Text(
                posToken['Chef'] != null
                    ? 'Chef Token: ${posToken['Chef']!}'
                    : 'Generate POS Code (Chef)',
                style: const TextStyle(fontSize: 20),
              ),
            ),
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
        title: const Text(
          "Shop Manager",
        ),
        actions: <Widget>[
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
                                          fn: () =>
                                              Navigator.of(context).pop());
                                    },
                                  );
                                });
                              });
                            },
                            tooltip: "Done",
                          )
                        ],
                )
              : IconButton(
                  icon: IconBadge(
                    icon: Icons.menu,
                    size: iconSize,
                  ),
                  onPressed: () => _key.currentState!.openEndDrawer(),
                  tooltip: "Menu",
                ),
        ],
      ),
      body: (_ready & !_saving & !_deleting)
          ? _bodies
          : Center(
              child:
                  Lottie.asset('assets/animations/colors-circle-loader.json'),
            ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
            height: 50,
            child: ListView(
                scrollDirection: Axis.horizontal, children: _menuTypeButtons)),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
