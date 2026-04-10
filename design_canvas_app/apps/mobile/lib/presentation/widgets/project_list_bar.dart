// ProjectListBar — horizontal strip above the canvas showing all
// projects. Tapping a project filters the canvas to that project's
// screens. "All" shows everything.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/project_list_controller.dart';
import 'project_list_bar.styles.dart';

class ProjectListBar extends StatelessWidget {
  const ProjectListBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProjectListController>();
    final projects = controller.projects;
    final selected = controller.selectedSlug;

    return Container(
      height: ProjectListBarStyles.barHeight,
      color: ProjectListBarStyles.barBackground,
      padding: ProjectListBarStyles.barPadding,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            icon: null,
            isSelected: selected == null,
            onTap: () => controller.selectProject(null),
          ),
          const SizedBox(width: ProjectListBarStyles.cardSpacing),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: projects.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: ProjectListBarStyles.cardSpacing),
              itemBuilder: (context, i) {
                final p = projects[i];
                return _Chip(
                  label: p.name,
                  icon: p.icon.isNotEmpty ? p.icon : null,
                  isSelected: selected == p.slug,
                  onTap: () => controller.selectProject(p.slug),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ProjectListBarStyles.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? ProjectListBarStyles.cardBackgroundSelected
              : ProjectListBarStyles.cardBackground,
          borderRadius:
              BorderRadius.circular(ProjectListBarStyles.cardRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon!,
                  style: TextStyle(
                      fontSize: ProjectListBarStyles.iconSize)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: isSelected
                  ? ProjectListBarStyles.nameStyle
                  : ProjectListBarStyles.allProjectsStyle,
            ),
          ],
        ),
      ),
    );
  }
}
