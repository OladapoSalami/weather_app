import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'additional_info_item.dart';
import 'hourly_forecast_item.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  List<dynamic>? forecastData;
  bool isLoading = true;
  bool hasError = false;

  // API key pulled from .env file (hidden from GitHub)
  final String apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> getWeatherData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final position = await _determinePosition();

      final currentUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric',
      );
      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric',
      );

      final currentResponse = await http.get(currentUrl);
      final forecastResponse = await http.get(forecastUrl);

      if (currentResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final current = jsonDecode(currentResponse.body);
        final forecast = jsonDecode(forecastResponse.body);

        setState(() {
          weatherData = current;
          forecastData = forecast['list'].take(5).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weather App',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: getWeatherData,
            icon: const Icon(Icons.refresh_rounded, size: 26),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? const Center(
            child: Text(
              'Failed to load weather data 😔',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          )
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Main Weather Card ---
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Colors.white.withValues(alpha: 0.15),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 15, sigmaY: 15),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Text(
                                  '${weatherData!['main']['temp']}°C',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Icon(
                                  _getWeatherIcon(weatherData![
                                  'weather'][0]['main']),
                                  size: 80,
                                  color: Colors.yellowAccent,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  weatherData!['weather'][0]['main'],
                                  style: const TextStyle(
                                      fontSize: 22,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  weatherData!['name'],
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    'Next Hours Forecast',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // --- Forecast Scroll Section ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: forecastData!.map((item) {
                        final time = item['dt_txt']
                            .toString()
                            .substring(11, 16);
                        final icon = _getWeatherIcon(
                            item['weather'][0]['main']);
                        final temp =
                            '${item['main']['temp'].round()}°C';

                        return HourlyForecastItem(
                            time: time,
                            icon: icon,
                            temperature: temp);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value:
                        '${weatherData!['main']['humidity']}%',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.air,
                        label: 'Wind',
                        value:
                        '${weatherData!['wind']['speed']} m/s',
                      ),
                      AdditionalInfoItem(
                        icon: Icons.compress,
                        label: 'Pressure',
                        value:
                        '${weatherData!['main']['pressure']} hPa',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.umbrella;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'drizzle':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }
}
