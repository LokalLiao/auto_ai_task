import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../utils/app_navigator.dart';
import '../viewmodels/weather_view_model.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late final WeatherViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WeatherViewModel();
    _viewModel.load7DaysWeather();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('未来7天天气预报'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigator.back(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_viewModel.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _viewModel.load7DaysWeather,
                    child: const Text('重试'),
                  )
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _viewModel.cityName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _viewModel.forecastList.length,
                  itemBuilder: (context, index) {
                    final item = _viewModel.forecastList[index];
                    return _buildWeatherCard(item, index == 0);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(DailyWeather item, bool isToday) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isToday ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday ? const BorderSide(color: Colors.blue, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 顶部：图标 + 日期/天气 + 温度区间
            Row(
              children: [
                Icon(item.icon, size: 32, color: Colors.orange),
                const SizedBox(width: 10),
                // 使用 Expanded 限制中间文字区域，防止撑爆
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? '${item.date} (今天)' : item.date,
                        style: TextStyle(
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.condition,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.tempRange,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            // 底部：4项微缩指标（全部使用 Expanded 均分，防止超宽）
            Row(
              children: [
                Expanded(child: _buildSubInfo(Icons.water_drop, '降水', '${item.precipitationProbability}%')),
                Expanded(child: _buildSubInfo(Icons.air, '风速', '${item.maxWindSpeed.toStringAsFixed(0)}km/h')),
                Expanded(child: _buildSubInfo(Icons.wb_sunny_outlined, '紫外线', '${item.maxUvIndex.toStringAsFixed(1)}')),
                Expanded(child: _buildSubInfo(Icons.nights_stay_outlined, '日落', item.sunset)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubInfo(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: Colors.blueGrey),
            const SizedBox(width: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}