import 'package:flutter/material.dart';
import '../core/design_system/app_colors.dart';
import '../core/design_system/app_shapes.dart';
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
        border: Border.all(
          color: context.appColors.primary.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
