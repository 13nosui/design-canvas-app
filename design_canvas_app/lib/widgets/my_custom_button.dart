import 'package:flutter/material.dart';
import '../core/design_system/app_colors.dart';
import '../core/design_system/app_shapes.dart';
import '../core/design_system/app_elevations.dart';
import '../core/design_system/app_spacing.dart';

class MyCustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const MyCustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSpacing.l,
            vertical: context.appSpacing.m,
          ),
          decoration: BoxDecoration(
            color: context.appColors.primary,
            borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
            boxShadow: context.appElevations.elevation > 0 ? [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
                blurRadius: context.appElevations.elevation * 2,
                offset: Offset(0, context.appElevations.elevation),
              ),
            ] : null,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
