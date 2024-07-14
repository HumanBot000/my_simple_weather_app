import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';

var box = Hive.box("settings");
var location = box.get("location");
var latitude = location["lat"];
var longitude = location["long"];

Future<Map<String, dynamic>> getCurrentWeatherData() async {
  var response = await http.get(Uri.parse(
      "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_direction_10m_dominant&timezone=auto"));
  var data = jsonDecode(response.body);
  return data;
}

Future<Map<String, dynamic>> getCurrentWeatherUnits() async {
  var response = await http.get(Uri.parse(
      "https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_direction_10m_dominant&timezone=auto"));
  var data = jsonDecode(response.body);
  return data;
}

Future<Map<String, dynamic>> loadWeatherDescription() async {
  String jsonString =
  await rootBundle.loadString('assets/weatherDescription.json');
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> weatherDataForStatistics() async {
  var response = await http.get(Uri.parse("https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&minutely_15=temperature_2m,relative_humidity_2m,precipitation,wind_speed_10m,wind_gusts_10m&daily=sunrise,sunset&timezone=auto&past_minutely_15=96&forecast_minutely_15=96"));
  var data = jsonDecode(response.body);
  return data;
}