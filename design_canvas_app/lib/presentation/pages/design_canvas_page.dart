import 'package:flutter/material.dart';
import '../../widgets/my_custom_button.dart';
import '../../widgets/my_custom_card.dart';
import '../../core/design_system/app_spacing.dart';

class DesignCanvasPage extends StatelessWidget {
  const DesignCanvasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Canvas (Infinite)'),
        elevation: 0,
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 4.0,
        constrained: false,
        child: Container(
          width: 3000,
          height: 3000,
          color: Colors.grey[100],
          child: Center(
            child: Wrap(
              spacing: context.appSpacing.l,
              runSpacing: context.appSpacing.l,
              alignment: WrapAlignment.center,
              children: [
                MyCustomButton(
                  text: 'Primary Button',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Button Pressed!')),
                    );
                  },
                ),
                const MyCustomCard(
                  title: 'Card Element 1',
                  description: 'This is a test card using the new design system for spacing and colors.',
                ),
                const MyCustomCard(
                  title: 'Card Element 2',
                  description: 'Another card to demonstrate the Wrap layout in the infinite canvas.',
                ),
                MyCustomButton(
                  text: 'Secondary Action',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
