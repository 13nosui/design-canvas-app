import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/design_system/app_colors.dart';
import '../core/design_system/app_shapes.dart';
import '../core/design_system/app_elevations.dart';
import '../core/design_system/app_borders.dart';
import '../core/design_system/app_opacity.dart';
import '../core/design_system/app_blur.dart';
import '../core/design_system/app_gradients.dart';
import '../core/design_system/app_spacing.dart';
import '../core/design_system/linter_wrapper.dart';

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
    return LinterWrapper(
      isCompliant: true,
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
            boxShadow: context.appElevations.elevation > 0 ? [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.2),
                blurRadius: context.appElevations.elevation * 2,
                offset: Offset(0, context.appElevations.elevation),
              ),
            ] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: context.appBlur.blur,
                sigmaY: context.appBlur.blur,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.appSpacing.l,
                  vertical: context.appSpacing.m,
                ),
                decoration: BoxDecoration(
                  color: context.appGradients.useGradient ? null : context.appColors.primary.withOpacity(context.appOpacity.opacity),
                  gradient: context.appGradients.useGradient
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.appGradients.startColor.withOpacity(context.appOpacity.opacity),
                            context.appGradients.endColor.withOpacity(context.appOpacity.opacity),
                          ],
                        )
                      : null,
                  border: context.appBorders.borderWidth > 0 ? Border.all(
                    color: context.appBorders.borderColor,
                    width: context.appBorders.borderWidth,
                  ) : null,
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
          ),
        ),
        ),
      ),
    );
  }
}
