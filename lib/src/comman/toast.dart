import 'package:bloc_clean_architecture/src/comman/colors.dart';
import 'package:flutter/material.dart';

void showToast({
  required String msg,
  Color? backgroundColor,
  Color? textColor,
  BuildContext? context,
}) {
  if (context == null) {
    // Fallback to print if no context is provided
    print('Toast: $msg');
    return;
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 16,
        ),
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: backgroundColor ?? ColorLight.primary,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'OK',
        textColor: textColor ?? Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
