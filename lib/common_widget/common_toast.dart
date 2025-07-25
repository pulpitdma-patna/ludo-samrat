import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommonToast {
  static void show(String message, {Color? backgroundColor, Color? textColor}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor ?? Colors.black87,
      textColor: textColor ?? Colors.white,
      fontSize: 16.sp,
    );
  }

  static void success(String message) {
    show(message, backgroundColor: Colors.green);
  }

  static void error(String message) {
    show(message, backgroundColor: Colors.red);
  }

  static void warning(String message) {
    show(message, backgroundColor: Colors.orange);
  }
}
