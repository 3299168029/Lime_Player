import 'package:flutter/material.dart';

class WindowControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;

  const WindowControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: TextButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ? hoverColor : Colors.transparent),
        ),
        onPressed: onPressed,
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}