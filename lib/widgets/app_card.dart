import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Header section for [AppCard]. Wraps a title widget and optional trailing actions.
class CardHeader extends StatelessWidget {
  final Widget title;
  final Widget? center;
  final List<Widget>? actions;

  const CardHeader({
    super.key,
    required this.title,
    this.center,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'card header',
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(child: title),
            if (center != null)
              Expanded(
                child: Center(child: center!),
              ),
            if (actions != null)
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Body section for [AppCard]. Provides configurable padding around the content.
class CardBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const CardBody({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'card body',
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

/// Footer section for [AppCard]. Typically holds buttons or status text aligned to the right.
class CardFooter extends StatelessWidget {
  final Widget child;

  const CardFooter({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'card footer',
      child: Align(
        alignment: Alignment.centerRight,
        child: child,
      ),
    );
  }
}

/// Base card component applying background color and rounded corners.
class AppCard extends StatelessWidget {
  final Widget? header;
  final Widget? body;
  final Widget? footer;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;

  const AppCard({
    super.key,
    this.header,
    this.body,
    this.footer,
    this.backgroundColor,
    this.backgroundGradient,
    this.padding,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (header != null) children.add(header!);
    if (body != null) {
      if (children.isNotEmpty) children.add(SizedBox(height: 8.h));
      children.add(body!);
    }
    if (footer != null) {
      if (children.isNotEmpty) children.add(SizedBox(height: 12.h));
      children.add(footer!);
    }

    return Container(
      padding: padding ?? EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundGradient == null
            ? backgroundColor ?? Theme.of(context).cardColor
            : null,
        gradient: backgroundColor == null ? backgroundGradient : null,
        borderRadius: BorderRadius.circular(12.r),
        border: border,
        boxShadow: boxShadow ?? const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
