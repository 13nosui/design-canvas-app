class DeviceSpec {
  final String id;
  final String name;
  final double width;
  final double height;
  final double borderRadius;
  final double bezelWidth;

  const DeviceSpec({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    this.borderRadius = 0.0,
    this.bezelWidth = 0.0,
  });
}

class AppDevices {
  static const DeviceSpec free = DeviceSpec(
    id: 'free',
    name: 'Free',
    width: 250,
    height: 500,
  );

  static const DeviceSpec iphone15 = DeviceSpec(
    id: 'iphone_15',
    name: 'iPhone 15',
    width: 393,
    height: 852,
    borderRadius: 48,
    bezelWidth: 12, // 黒枠の太さ
  );

  static const DeviceSpec pixel7 = DeviceSpec(
    id: 'pixel_7',
    name: 'Pixel 7',
    width: 412,
    height: 915,
    borderRadius: 24,
    bezelWidth: 8,
  );

  static const List<DeviceSpec> values = [free, iphone15, pixel7];
}
