import 'package:flutter/material.dart';

class CustomMarker extends StatelessWidget {
  const CustomMarker({
    super.key,
    required this.icon,
    this.color,
    this.iconColor,
  });
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Card(
          // padding: const EdgeInsets.all(8),
          shape: CircleBorder(),
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              color: color ?? Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
                child: Icon(icon, size: 40, color: iconColor ?? Colors.black)),
          ),
        ),
      ],
    );
  }
}
