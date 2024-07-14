import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:weather/statistics/humidity.dart';
import 'package:weather/statistics/precipitation.dart';
import 'package:weather/statistics/temperature.dart';
import 'package:weather/statistics/windSpeed.dart';
import 'weather_api.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  Future<void> _onItemTapped(int index) async {
    var box = Hive.box("settings");
    await box.delete("location");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Scaffold>(
      future: _build_body(),
      builder: (BuildContext context, AsyncSnapshot<Scaffold> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return snapshot.data!;
        }
      },
    );
  }

  Future<Scaffold> _build_body() async {
    var box = await Hive.openBox("settings");
    TextEditingController _latitude = TextEditingController();
    TextEditingController _longitude = TextEditingController();
    if (box.get("location") == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(child: Text("No Location set")),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitude,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Latitude',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _longitude,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Longitude',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _latitude.text = _latitude.text.replaceAll(",", ".");
                  _longitude.text = _longitude.text.replaceAll(",", ".");
                  if (_latitude.text.isNotEmpty &&
                      _longitude.text.isNotEmpty &&
                      double.tryParse(_latitude.text) != null &&
                      double.tryParse(_longitude.text) != null &&
                      double.parse(_latitude.text) >= -90 &&
                      double.parse(_latitude.text) <= 90 &&
                      double.parse(_longitude.text) >= -180 &&
                      double.parse(_longitude.text) <= 180) {
                    box.put("location", {
                      "lat": double.parse(_latitude.text),
                      "long": double.parse(_longitude.text)
                    });
                    setState(() {});
                  }
                },
                child: Text("Set Location"),
              ),
            ],
          ),
        ),
      );
    } else {
      Map<String, dynamic> weatherData = await getCurrentWeatherData();
      var currentWeatherData = weatherData["current"];
      Map<String, dynamic> weatherDescription = await loadWeatherDescription();
      var isDay = currentWeatherData["is_day"] == 1;
      var weatherCode = currentWeatherData["weather_code"].toString();
      var units = await getCurrentWeatherUnits();
      var current_units = units["current_units"];
      if (!weatherDescription.containsKey(weatherCode)) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: Center(
              child:
                  Text('Weather code not found in description: $weatherCode')),
        );
      }

      var imageUrl = isDay
          ? weatherDescription[weatherCode]["day"]["image"]
          : weatherDescription[weatherCode]["night"]["image"];
      return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: isDay
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.inversePrimary,
            leading: Builder(
              builder: (context) {
                return IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    });
              },
            ),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text('Settings'),
                ),
                ListTile(
                  title: const Text('Set Location'),
                  selected: true,
                  onTap: () {
                    // Update the state of the app
                    _onItemTapped(0);
                    // Then close the drawer
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fill,
                ),
              ),
              child: Stack(children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isDay
                              ? weatherDescription[weatherCode]["day"]
                                  ["description"]
                              : weatherDescription[weatherCode]["night"]
                                  ["description"],
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                    InkWell(
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Temperatur: ${currentWeatherData["temperature_2m"]} ${current_units["temperature_2m"]}",
                                style: TextStyle(fontSize: 30),
                              ),
                              Text(
                                "(${weatherData["daily"]["temperature_2m_max"][0]} ${current_units["temperature_2m"]}/${weatherData["daily"]["temperature_2m_min"][0]} ${current_units["temperature_2m"]} ${current_units["temperature_2m"]})",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TemperatureForecast(isDay: isDay,)),
                          );
                        }),
                    Table(
                      children: [
                        TableRow(
                          children: [
                            InkWell(
                              child: Card(
                                child: ListTile(
                                  leading: Icon(Icons.water_drop),
                                  title: Text('Feuchtigkeit'),
                                  subtitle: Text(
                                      '${currentWeatherData["relative_humidity_2m"]} ${current_units["relative_humidity_2m"]}'),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HumidityForecast(isDay: isDay,)),
                                );
                              }
                            ),
                            InkWell(
                              child: Card(
                                child: ListTile(
                                  leading: Icon(Icons.water_drop),
                                  title: Text('Niederschlag'),
                                  subtitle: Text(
                                      '${currentWeatherData["precipitation"]} ${current_units["precipitation"]}'),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PrecipitationForecast(isDay: isDay)),
                                  );
                              }
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            InkWell(
                              child: Card(
                                child: ListTile(
                                  leading: Icon(Icons.speed),
                                  title: Text('Windgeschwindigkeit'),
                                  subtitle: Text(
                                      '${currentWeatherData["wind_speed_10m"]} ${current_units["wind_speed_10m"]}'),
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WindSpeedForecast(isDay: isDay)),
                                  );
                              },
                            ),
                            Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.speed_outlined,
                                  color: Colors.red,
                                ),
                                title: Text('Wind Gusts'),
                                subtitle: Text(
                                    '${currentWeatherData["wind_gusts_10m"]} ${current_units["wind_gusts_10m"]}'),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            Card(
                              child: ListTile(
                                leading: Icon(Icons.cloud),
                                title: Text('Bewölkung'),
                                subtitle: Text(
                                    '${currentWeatherData["cloud_cover"]} ${current_units["cloud_cover"]}'),
                              ),
                            ),
                            Card(
                              child: ListTile(
                                leading: Icon(Icons.compress),
                                title: Text('Luftdruck'),
                                subtitle: Text(
                                    '${currentWeatherData["pressure_msl"]} ${current_units["pressure_msl"]}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.navigation),
                            title: Text('Windrichtung'),
                            subtitle: FutureBuilder<String>(
                              future: _getWindDirection(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text('Loading...');
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return Text(snapshot.data ?? '');
                                }
                              },
                            ),
                          ),
                          FutureBuilder<String>(
                            future: _getWindDirection(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                double rotationDegrees = double.parse(
                                    snapshot.data!.replaceAll('°', ''));
                                return Transform.rotate(
                                  angle: _degreesToRadians(rotationDegrees),
                                  child: Image.asset(
                                    'assets/compass.png',
                                    width: 100,
                                    height: 100,
                                  ),
                                );
                              }
                            },
                          ),
                          SizedBox(
                            height: 20,
                          )
                        ],
                      ),
                    ),
                    Table(children: [
                      TableRow(children: [
                        Card(
                          child: ListTile(
                            leading: Icon(Icons.sunny_snowing),
                            title: Text('Sonnenaufgang'),
                            subtitle: Text(
                                '${DateTime.parse(weatherData["daily"]["sunrise"][0]).hour}:${DateTime.parse(weatherData["daily"]["sunrise"][0]).minute}'),
                          ),
                        ),
                        Card(
                            child: ListTile(
                          leading: Icon(Icons.nightlight_round),
                          title: Text('Sonnenuntergang'),
                          subtitle: Text(
                              '${DateTime.parse(weatherData["daily"]["sunset"][0]).hour}:${DateTime.parse(weatherData["daily"]["sunset"][0]).minute}'),
                        ))
                      ])
                    ])
                  ],
                ),
              ]),
            ),
          ));
    }
  }
}

Future<String> _getWindDirection() async {
  var weatherData = await getCurrentWeatherData();
  var windDirection = weatherData["current"]["wind_direction_10m"];
  var directionInDegrees = (windDirection.toDouble() + 180) % 360;
  return '${directionInDegrees.round()}°';
}

double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}
