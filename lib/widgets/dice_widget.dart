import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

/// Simple dice animation using a rotating casino icon.
class DiceWidget extends StatelessWidget {
  /// Size of the square animation area.
  final double size;

  /// Whether the dice is currently rolling.
  /// When `false` the animation is paused.
  final bool? rolling;

  /// Final values to display when not rolling.
  final List<int>? values;
  final int? selected;
  final void Function(int)? onSelected;

  const DiceWidget({
    Key? key,
    this.size = 64,
    this.rolling,
    this.values,
    this.selected,
    this.onSelected,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (rolling == true) {
      return Lottie.asset(
        'assets/animations/dice.json',
        width: size,
        height: size,
        animate: true,
        repeat: true,
      );
    }
    if (values == null || values!.isEmpty) {
      return Icon(Icons.casino_outlined, size: size);
    }

    Widget buildFace(int value) {
      final path = 'assets/images/dice3d_${value}.svg';
      final bool isSelected = selected == value;
      final decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      );
      return FutureBuilder<bool>(
        future: rootBundle
            .load(path)
            .then((_) => true)
            .catchError((_) => false),
        builder: (context, snapshot) {
          final hasAsset = snapshot.data == true;
          final Widget child = hasAsset
              ? SvgPicture.asset(
                  path,
                  width: size * 0.8,
                  height: size * 0.8,
                )
              : Text(
                  '$value',
                  style: TextStyle(
                      fontSize: size * 0.5, fontWeight: FontWeight.bold),
                );
          Widget result = Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: decoration,
            child: child,
          );
          if (onSelected != null) {
            result = GestureDetector(
              onTap: () => onSelected!(value),
              child: result,
            );
          }
          return result;
        },
      );
    }

    if (values!.length == 1) {
      return buildFace(values!.first);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: values!
          .map((v) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: buildFace(v),
              ))
          .toList(),
    );
  }
}
