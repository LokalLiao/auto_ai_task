//通过定位获取当前定位等信息

class AppLocation {
  final double latitude;
  final double longitude;
  final String? country;
  final String? city;
  final String? district;
  final String? address;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.country,
    this.city,
    this.district,
    this.address,
  });

  //方便 UI 展示的格式化名称
  String get displayName => city?.isNotEmpty == true
      ? '$city ${district ?? ''}'
      : '$latitude, $longitude';
}