import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

/// Centers page content and applies adaptive horizontal padding + max width.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
    this.safeArea = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final Alignment alignment;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.pagePadding;
    final resolvedPadding = padding ??
        EdgeInsets.fromLTRB(horizontal, 0, horizontal, context.isPhone ? 16 : 24);

    Widget content = Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? context.contentMaxWidth,
        ),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }
    return content;
  }
}

/// Drop-in for fixed `EdgeInsets.all(24)` — adaptive gutter + max width.
class AdaptivePadding extends StatelessWidget {
  const AdaptivePadding({
    super.key,
    required this.child,
    this.top,
    this.bottom,
    this.horizontal,
    this.maxWidth,
  });

  final Widget child;
  final double? top;
  final double? bottom;
  final double? horizontal;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final h = horizontal ?? context.pagePadding;
    final t = top ?? 0.0;
    final b = bottom ?? context.pagePadding;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? context.contentMaxWidth),
        child: Padding(
          padding: EdgeInsets.fromLTRB(h, t, h, b),
          child: child,
        ),
      ),
    );
  }
}

/// Scrollable [AppPage] for long forms / lists.
class AppScrollPage extends StatelessWidget {
  const AppScrollPage({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.physics,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.pagePadding;
    final vertical = context.responsiveValue(phone: 16.0, tablet: 24.0, desktop: 28.0);
    final resolved = padding ??
        EdgeInsets.fromLTRB(horizontal, vertical, horizontal, vertical);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics ?? const BouncingScrollPhysics(),
          padding: resolved,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? context.contentMaxWidth,
                minHeight: (constraints.maxHeight - resolved.vertical)
                    .clamp(0.0, double.infinity),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Two columns on wide screens, stacked on phone.
class ResponsiveSplit extends StatelessWidget {
  const ResponsiveSplit({
    super.key,
    required this.primary,
    required this.secondary,
    this.gap = 24,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
    this.breakpoint = Breakpoints.phone,
  });

  final Widget primary;
  final Widget secondary;
  final double gap;
  final int primaryFlex;
  final int secondaryFlex;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    if (context.screenWidth < breakpoint) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: primary),
          SizedBox(height: gap),
          secondary,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: primaryFlex, child: primary),
        SizedBox(width: gap),
        Expanded(flex: secondaryFlex, child: secondary),
      ],
    );
  }
}
