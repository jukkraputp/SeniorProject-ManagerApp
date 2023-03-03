import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:manager/interfaces/item.dart';
import 'package:manager/interfaces/order.dart';
import 'package:manager/interfaces/shop_info.dart';
import 'package:manager/widgets/cart_item.dart';

class HistoryDetail extends StatefulWidget {
  const HistoryDetail({super.key, required this.shopInfo, required this.order});

  final ShopInfo shopInfo;
  final Order order;

  @override
  State<HistoryDetail> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double imgSize = screenSize.width * 0.2;
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'ร้าน ${widget.shopInfo.name} - ออเดอร์ #${widget.order.orderId}'),
      ),
      body: ListView.builder(
          itemCount: widget.order.itemList.length,
          itemBuilder: ((context, index) {
            ItemCounter itemCounter = widget.order.itemList[index];
            return Padding(
              padding: const EdgeInsets.all(5),
              child: CartItem(
                shopName: widget.shopInfo.name,
                itemCounter: itemCounter,
                isFav: false,
                adjustButtons: false,
              ),
            );
          })),
    );
  }
}
