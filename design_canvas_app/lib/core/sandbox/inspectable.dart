import 'package:flutter/material.dart';

class CanvasState extends InheritedWidget {
  final String? selectedComponentId;

  const CanvasState({
    super.key,
    required this.selectedComponentId,
    required super.child,
  });

  static CanvasState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CanvasState>();
  }

  @override
  bool updateShouldNotify(CanvasState oldWidget) {
    return selectedComponentId != oldWidget.selectedComponentId;
  }
}

class InspectableData {
  final String id;
  final bool isText;

  const InspectableData({
    required this.id,
    this.isText = false,
  });
}

class Inspectable extends StatelessWidget {
  final String id;
  final bool isText;
  final Widget child;

  const Inspectable({
    super.key,
    required this.id,
    this.isText = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = CanvasState.of(context)?.selectedComponentId;
    final isSelected = selectedId == id;
    
    Widget content = MetaData(
      metaData: InspectableData(id: id, isText: isText),
      behavior: HitTestBehavior.translucent, // Allow hit testing even if transparent
      child: child,
    );
    
    if (isSelected) {
      content = Container(
        foregroundDecoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2.0),
          color: Colors.blueAccent.withOpacity(0.1),
        ),
        child: content,
      );
    }
    
    return content;
  }
}
