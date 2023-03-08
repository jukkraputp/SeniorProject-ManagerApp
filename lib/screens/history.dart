import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:manager/apis/api.dart';
import 'package:manager/interfaces/order.dart';
import 'package:manager/interfaces/shop_info.dart';
import 'package:intl/intl.dart';
import 'package:manager/screens/history_detail.dart';
import 'package:manager/util/number.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen(
      {super.key,
      required this.shopInfo,
      required this.listOfHistory,
      required this.updateHistory});

  final ShopInfo shopInfo;
  final List<Order> listOfHistory;
  final Future<List<Order>> Function(ShopInfo, List<Order>, {String mode})
      updateHistory;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final API api = API();
  final dateFormat = DateFormat('dd MMM yyyy - HH:mm');
  final List<Color> monthColor = [
    Colors.white,
    Colors.red.shade900,
    Colors.purple,
    Colors.lightBlue,
    Colors.grey,
    Colors.green,
    Colors.purple,
    Colors.red,
    Colors.lightGreen,
    Colors.blue.shade900,
    Colors.pink,
    Colors.yellow,
    Colors.blue
  ];
  final List<Color> textColor = [
    Colors.black,
    Colors.red.shade900,
    Colors.purple,
    Colors.lightBlue,
    Colors.black,
    Colors.black,
    Colors.purple,
    Colors.red,
    Colors.black,
    Colors.blue.shade900,
    Colors.pink,
    Colors.black,
    Colors.blue
  ];

  List<Order> historyList = [];
  bool _available = false;

  @override
  void initState() {
    super.initState();
    setData();
  }

  Future<void> setData() async {
    List<String> dateStringList = await api.getHistoryDateList(
        uid: widget.shopInfo.uid, shopName: widget.shopInfo.name);
    List<DateTime> dateList = [];
    for (var date in dateStringList) {
      List<String> splitted = date.split('/');
      String year = splitted.first;
      String month = splitted[1];
      String day = splitted.last;
      if (month.length == 1) {
        month = '0$month';
      }
      if (day.length == 1) {
        day = '0$day';
      }
      dateList.add(DateTime.parse('$year-$month-$day'));
    }
    dateList.sort(((a, b) => b.compareTo(a)));
    for (var date in dateList) {
      List<Order> historyList = await api.getHistoryByDate(
          uid: widget.shopInfo.uid,
          shopName: widget.shopInfo.name,
          date: '${date.year}/${date.month}/${date.day}');
      widget.updateHistory(widget.shopInfo, historyList, mode: 'add');
      this.historyList.addAll(historyList);
      setState(() {
        _available = true;
      });
    }
  }

  String intToMonthName(int number) {
    return DateFormat('MMMM').format(DateTime(0, number));
  }

  ListView createListView(List<Order> historyList) {
    Size screenSize = MediaQuery.of(context).size;
    int monthCount = 0;
    int? currentMonth;
    for (var order in historyList) {
      if ((currentMonth == null) || (currentMonth != order.date.month)) {
        currentMonth = order.date.month;
        monthCount += 1;
      }
    }
    int _currentMonth = 0;
    int _dividerCount = 0;
    if (historyList.isNotEmpty) {
      _currentMonth = historyList.first.date.month;
    }

    return ListView.builder(
        itemCount: historyList.length + monthCount,
        itemBuilder: ((context, index) {
          Order order = historyList[index - _dividerCount];
          if (index == 0) {
            _dividerCount += 1;
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Expanded(child: Divider()),
                  Expanded(
                      child: Text(
                    '${intToMonthName(order.date.month)} ${order.date.year}',
                    textAlign: TextAlign.center,
                  )),
                  const Expanded(child: Divider()),
                ],
              ),
            );
          }

          if (order.date.month != _currentMonth) {
            _currentMonth = order.date.month;
            _dividerCount += 1;
            return Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Expanded(child: Divider()),
                  Expanded(
                      child: Text(
                    '${intToMonthName(order.date.month)} ${order.date.year}',
                    textAlign: TextAlign.center,
                  )),
                  const Expanded(child: Divider()),
                ],
              ),
            );
          }
          late num orderCost;
          if (isInteger(order.cost)) {
            orderCost = order.cost.toInt();
          } else {
            orderCost = order.cost;
          }
          return Container(
            padding: const EdgeInsets.only(top: 5),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) {
                return HistoryDetail(
                  shopInfo: widget.shopInfo,
                  order: order,
                );
              })),
              style: ElevatedButton.styleFrom(
                  backgroundColor: monthColor[order.date.month]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('${dateFormat.format(order.date)}'),
                  Text('ออเดอร์ #${order.orderId}'),
                  Text('ราคารวม $orderCost บาท')
                ],
              ),
            ),
          );
        }));
  }

  @override
  Widget build(BuildContext context) {
    ListView body = createListView(historyList);
    return Scaffold(
      appBar: AppBar(title: Text('ประวัติการขายร้าน ${widget.shopInfo.name}')),
      body: _available
          ? Padding(
              padding: const EdgeInsets.all(5),
              child: body,
            )
          : const Center(
              child: Text('ไม่พบประวัติการขาย'),
            ),
    );
  }
}
