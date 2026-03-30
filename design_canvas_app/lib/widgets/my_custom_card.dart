import 'package:flutter/material.dart';
import '../core/design_system/app_colors.dart';
import '../core/design_system/app_shapes.dart';
import '../core/design_system/app_elevations.dart';
import '../core/design_system/app_borders.dart';
import '../core/design_system/app_spacing.dart';

class MyCustomCard extends StatelessWidget {
  final String title;
  final String description;

  const MyCustomCard({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: EdgeInsets.all(context.appSpacing.m),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(context.appShapes.borderRadius),
        border: context.appBorders.borderWidth > 0 ? Border.all(
          color: context.appBorders.borderColor,
          width: context.appBorders.borderWidth,
        ) : null,
        boxShadow: context.appElevations.elevation > 0 ? [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: context.appElevations.elevation * 3,
            offset: Offset(0, context.appElevations.elevation * 1.5),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.appColors.primary,
            ),
          ),
          SizedBox(height: context.appSpacing.s),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: context.appColors.text.withOpacity(0.87),
            ),
          ),
        ],
      ),
    );
  }
}
