// WidgetPaletteController — provides the categorized widget catalog
// for the left sidebar palette. Each PaletteItem represents a Flutter
// widget that can be dragged onto a canvas screen.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PaletteItem {
  final String id;
  final String label;
  final IconData icon;
  final String category;
  /// Default Dart code snippet inserted when dropped.
  final String defaultCode;

  const PaletteItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    required this.defaultCode,
  });
}

class WidgetCategory {
  final String name;
  final IconData icon;
  final List<PaletteItem> items;

  const WidgetCategory({
    required this.name,
    required this.icon,
    required this.items,
  });
}

class WidgetPaletteController extends ChangeNotifier {
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isOpen = false;
  bool get isOpen => _isOpen;

  void toggleSidebar() {
    _isOpen = !_isOpen;
    notifyListeners();
  }

  void openSidebar() {
    if (_isOpen) return;
    _isOpen = true;
    notifyListeners();
  }

  void closeSidebar() {
    if (!_isOpen) return;
    _isOpen = false;
    notifyListeners();
  }

  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  /// All categories with items filtered by search query.
  List<WidgetCategory> get filteredCategories {
    if (_searchQuery.isEmpty) return _allCategories;
    final q = _searchQuery.toLowerCase();
    return _allCategories
        .map((c) => WidgetCategory(
              name: c.name,
              icon: c.icon,
              items: c.items
                  .where((i) => i.label.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((c) => c.items.isNotEmpty)
        .toList();
  }

  static const List<WidgetCategory> _allCategories = [
    WidgetCategory(name: 'Layout', icon: Icons.dashboard_outlined, items: [
      PaletteItem(id: 'row', label: 'Row', icon: Icons.view_column,
          category: 'Layout', defaultCode: 'Row(children: [])'),
      PaletteItem(id: 'column', label: 'Column', icon: Icons.view_agenda,
          category: 'Layout', defaultCode: 'Column(children: [])'),
      PaletteItem(id: 'stack', label: 'Stack', icon: Icons.layers,
          category: 'Layout', defaultCode: 'Stack(children: [])'),
      PaletteItem(id: 'wrap', label: 'Wrap', icon: Icons.wrap_text,
          category: 'Layout', defaultCode: 'Wrap(children: [])'),
      PaletteItem(id: 'sizedbox', label: 'SizedBox', icon: Icons.crop_square,
          category: 'Layout', defaultCode: 'SizedBox(height: 16)'),
      PaletteItem(id: 'padding', label: 'Padding', icon: Icons.padding,
          category: 'Layout', defaultCode: 'Padding(padding: EdgeInsets.all(8))'),
      PaletteItem(id: 'center', label: 'Center', icon: Icons.center_focus_strong,
          category: 'Layout', defaultCode: 'Center(child: ...)'),
      PaletteItem(id: 'expanded', label: 'Expanded', icon: Icons.expand,
          category: 'Layout', defaultCode: 'Expanded(child: ...)'),
      PaletteItem(id: 'container', label: 'Container', icon: Icons.check_box_outline_blank,
          category: 'Layout', defaultCode: 'Container()'),
    ]),
    WidgetCategory(name: 'Input', icon: Icons.input, items: [
      PaletteItem(id: 'textfield', label: 'TextField', icon: Icons.text_fields,
          category: 'Input', defaultCode: 'TextField()'),
      PaletteItem(id: 'checkbox', label: 'Checkbox', icon: Icons.check_box,
          category: 'Input', defaultCode: 'Checkbox(value: false, onChanged: (_) {})'),
      PaletteItem(id: 'switch', label: 'Switch', icon: Icons.toggle_on,
          category: 'Input', defaultCode: 'Switch(value: false, onChanged: (_) {})'),
      PaletteItem(id: 'slider', label: 'Slider', icon: Icons.tune,
          category: 'Input', defaultCode: 'Slider(value: 0.5, onChanged: (_) {})'),
      PaletteItem(id: 'dropdown', label: 'DropdownButton', icon: Icons.arrow_drop_down_circle,
          category: 'Input', defaultCode: 'DropdownButton(items: [], onChanged: (_) {})'),
      PaletteItem(id: 'elevatedbutton', label: 'ElevatedButton', icon: Icons.smart_button,
          category: 'Input', defaultCode: "ElevatedButton(onPressed: () {}, child: Text('Button'))"),
      PaletteItem(id: 'iconbutton', label: 'IconButton', icon: Icons.touch_app,
          category: 'Input', defaultCode: 'IconButton(onPressed: () {}, icon: Icon(Icons.add))'),
    ]),
    WidgetCategory(name: 'Display', icon: Icons.visibility, items: [
      PaletteItem(id: 'text', label: 'Text', icon: Icons.title,
          category: 'Display', defaultCode: "Text('Hello')"),
      PaletteItem(id: 'icon', label: 'Icon', icon: Icons.emoji_emotions,
          category: 'Display', defaultCode: 'Icon(Icons.star)'),
      PaletteItem(id: 'image', label: 'Image', icon: Icons.image,
          category: 'Display', defaultCode: "Image.network('https://...')"),
      PaletteItem(id: 'card', label: 'Card', icon: Icons.credit_card,
          category: 'Display', defaultCode: 'Card(child: ...)'),
      PaletteItem(id: 'listtile', label: 'ListTile', icon: Icons.list,
          category: 'Display', defaultCode: "ListTile(title: Text('Title'))"),
      PaletteItem(id: 'chip', label: 'Chip', icon: Icons.label,
          category: 'Display', defaultCode: "Chip(label: Text('Tag'))"),
      PaletteItem(id: 'badge', label: 'Badge', icon: Icons.notifications_active,
          category: 'Display', defaultCode: 'Badge(label: Text("3"), child: Icon(Icons.mail))'),
      PaletteItem(id: 'divider', label: 'Divider', icon: Icons.horizontal_rule,
          category: 'Display', defaultCode: 'Divider()'),
      PaletteItem(id: 'circularprogressindicator', label: 'Progress', icon: Icons.hourglass_empty,
          category: 'Display', defaultCode: 'CircularProgressIndicator()'),
    ]),
    WidgetCategory(name: 'Navigation', icon: Icons.navigation, items: [
      PaletteItem(id: 'bottomnavbar', label: 'BottomNavBar', icon: Icons.space_dashboard,
          category: 'Navigation', defaultCode: 'BottomNavigationBar(items: [])'),
      PaletteItem(id: 'tabbar', label: 'TabBar', icon: Icons.tab,
          category: 'Navigation', defaultCode: 'TabBar(tabs: [])'),
      PaletteItem(id: 'drawer', label: 'Drawer', icon: Icons.menu,
          category: 'Navigation', defaultCode: 'Drawer(child: ...)'),
      PaletteItem(id: 'appbar', label: 'AppBar', icon: Icons.web_asset,
          category: 'Navigation', defaultCode: "AppBar(title: Text('Title'))"),
      PaletteItem(id: 'floatingactionbutton', label: 'FAB', icon: Icons.add_circle,
          category: 'Navigation', defaultCode: 'FloatingActionButton(onPressed: () {}, child: Icon(Icons.add))'),
    ]),
  ];
}
