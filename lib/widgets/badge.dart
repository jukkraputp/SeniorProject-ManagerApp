import 'package:flutter/material.dart';

class IconBadge extends StatefulWidget {
  final IconData icon;
  final double size;
  final int noti;

  const IconBadge(
      {Key? key, this.noti = 0, required this.icon, required this.size})
      : super(key: key);

  @override
  _IconBadgeState createState() => _IconBadgeState();
}

class _IconBadgeState extends State<IconBadge> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Icon(
          widget.icon,
          size: widget.size,
        ),
        if (widget.noti > 0)
          Positioned(
            right: 0.0,
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 13,
                minHeight: 13,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  widget.noti.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
