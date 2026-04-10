// WidgetPaletteSidebar — left sidebar showing categorized Flutter
// widgets. Each item is a Draggable that can be dropped onto canvas
// screens to insert new widgets.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/widget_palette_controller.dart';
import 'widget_palette_sidebar.styles.dart';

class WidgetPaletteSidebar extends StatelessWidget {
  const WidgetPaletteSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WidgetPaletteController>();
    final categories = controller.filteredCategories;

    return Container(
      width: WidgetPaletteSidebarStyles.sidebarWidth,
      decoration: const BoxDecoration(
        color: WidgetPaletteSidebarStyles.background,
        border: Border(
          right: BorderSide(
              color: WidgetPaletteSidebarStyles.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Search
          Padding(
            padding: WidgetPaletteSidebarStyles.searchPadding,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search widgets...',
                hintStyle: WidgetPaletteSidebarStyles.searchHintStyle,
                prefixIcon:
                    const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: WidgetPaletteSidebarStyles.searchBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onChanged: controller.setSearch,
            ),
          ),
          // Categories
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: categories.length,
              itemBuilder: (context, i) =>
                  _CategorySection(category: categories[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});
  final WidgetCategory category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
          child: Row(
            children: [
              Icon(category.icon, size: 14,
                  color: WidgetPaletteSidebarStyles.categoryHeaderColor),
              const SizedBox(width: 6),
              Text(category.name,
                  style: WidgetPaletteSidebarStyles.categoryStyle),
            ],
          ),
        ),
        ...category.items.map((item) => _PaletteItemTile(item: item)),
      ],
    );
  }
}

class _PaletteItemTile extends StatelessWidget {
  const _PaletteItemTile({required this.item});
  final PaletteItem item;

  @override
  Widget build(BuildContext context) {
    return Draggable<PaletteItem>(
      data: item,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        color: WidgetPaletteSidebarStyles.dragFeedbackColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(item.label,
                  style: WidgetPaletteSidebarStyles.dragFeedbackStyle),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _ItemContent(item: item),
      ),
      child: _ItemContent(item: item),
    );
  }
}

class _ItemContent extends StatefulWidget {
  const _ItemContent({required this.item});
  final PaletteItem item;

  @override
  State<_ItemContent> createState() => _ItemContentState();
}

class _ItemContentState extends State<_ItemContent> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        padding: WidgetPaletteSidebarStyles.itemPadding,
        color: _hovering
            ? WidgetPaletteSidebarStyles.itemHoverColor
            : Colors.transparent,
        child: Row(
          children: [
            Icon(widget.item.icon, size: 16,
                color: const Color(0xFF475569)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.item.label,
                  style: WidgetPaletteSidebarStyles.itemStyle),
            ),
            if (_hovering)
              const Icon(Icons.drag_indicator,
                  size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
