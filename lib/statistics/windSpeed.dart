import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:weather/weather_api.dart'; // Assuming this file contains the weatherDataForStatistics function

class WindSpeedForecast extends StatefulWidget {
  final bool isDay;
  const WindSpeedForecast({super.key, required this.isDay});

  @override
  State<WindSpeedForecast> createState() => _WindSpeedForecastState();
}

class _WindSpeedForecastState extends State<WindSpeedForecast> {
  List<String> time = [];
  List<double> wind = [];
  int firstPredictionIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchForecastData();
  }

  Future<void> fetchForecastData() async {
    final forecastData = await weatherDataForStatistics();
    setState(() {
      time = List<String>.from(forecastData["minutely_15"]["time"]);
      wind =
      List<double>.from(forecastData["minutely_15"]["wind_speed_10m"]);
      for (int i = 0; i < time.length; i++) {
        if (DateTime.parse(time[i]).isAfter(DateTime.now())) {
          firstPredictionIndex = i;
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (time.isEmpty || wind.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.isDay
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Windgeschwindigkeits Verlauf'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
            LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(time.length, (index) {
                      return FlSpot(index.toDouble(), wind[index]);
                    }),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                gridData: FlGridData(
                  show: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: const Text('Windgeschwindigkeit in km/h'),
                    sideTitles: SideTitles(
                      interval: 2,
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(value.round().toString());
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Time'),
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text("${DateTime.parse(time[value.toInt()]).hour.toString()}:00");
                      },
                    ),
                  ),
                ),
                // Add extra line for prediction start
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: firstPredictionIndex.toDouble(),
                      color: Colors.black,
                      strokeWidth: 1,
                      label: VerticalLineLabel(
                          show: true,
                          style: Theme.of(context).textTheme.bodySmall,
                          labelResolver: (line) {
                            return 'Vorhersage';
                          }
                      ),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                minY: 0
            )

        ),
      ),
    );
  }
}
