import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget svgIcon({
  required String name,
  required double width,
  required double height,
  Color? color,
  bool isRTL = false,
  String? semanticsLabel,
}) {
  final transformation =
  isRTL ? Matrix4.rotationY(-math.pi) : Matrix4.identity();
  return Transform(
    alignment: Alignment.center,
    transform: transformation,
    child: SvgPicture.asset(
      name,
      width: width,
      height: height,
      semanticsLabel: semanticsLabel,
      colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    ),
  );
}
