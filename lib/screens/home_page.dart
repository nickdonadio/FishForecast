import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fish_forecast/auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  String? _location;
  bool _isLoading = false;
  String? _locationErrorMessage;
  List<String> _recommendedLures = [];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }
  
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }
  
  Future<Map<String, String>> _fetchWeather(double lat, double lon) async {
  const apiKey = '899cd84f06039b04b5ab060934889315';
  final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=imperial');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final description = data['weather'][0]['description'];
    final temp = data['main']['temp'];
    final windSpeed = data['wind']['speed'];
    final windTag = _getWindConditionTag(windSpeed);

    String simplified = '';
      if (description.contains('cloud')) {
        simplified = 'cloudy';
      } else if (description.contains('rain')) {
        simplified = 'rain';
      } else if (description.contains('clear')) {
        simplified = 'clear';
      } else {
        simplified = description; 
      }

    final weatherString =
        'Weather: $description, Temp: ${temp.toString()}°F, Wind: ${windSpeed.toString()} mph';

    return {
      'description': '$simplified $windTag',
      'weather': weatherString,
      'windTag': windTag,
    };

    } else {
      throw Exception('Failed to fetch weather');
    }
  }


  String _getWindConditionTag(double windSpeed) {
    if (windSpeed < 5) {
      return 'low wind';
    } else if (windSpeed < 15) {
      return 'moderate wind';
    } else {
      return 'windy';
    }
  }

  String _getTimeOfDayLabel() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 8) {
      return 'Dawn';
    } else if (hour >= 8 && hour < 17) {
      return 'Mid Day';
    } else if (hour >= 17 && hour < 20) {
      return 'Dusk';
    } else {
      return 'Night';
    }
  }

  String _getCurrentSeason() {
    final now = DateTime.now();
    final month = now.month;

    if (month >= 3 && month <= 5) {
      return 'Spring';
    } else if (month >= 6 && month <= 8) {
      return 'Summer';
    } else if (month >= 9 && month <= 11) {
      return 'Fall';
    } else {
      return 'Winter';
    }
  }

  String _simplifyWeatherDescription(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('cloud')) return 'cloudy';
    if (lower.contains('clear')) return 'clear';
    if (lower.contains('rain')) return 'rain';
    if (lower.contains('snow')) return 'snow';
    return lower;
  }

  Future<List<String>> _getRecommendedLures(String rawWeatherDescription, String windTag) async {
    final currentSeason = _getCurrentSeason().toLowerCase();
    final timeOfDay = _getTimeOfDayLabel().toLowerCase();

    final simplifiedWeather = _simplifyWeatherDescription(rawWeatherDescription).toLowerCase();

    final snapshot = await FirebaseFirestore.instance.collection('Lures').get();

    List<String> matchingLures = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final List<dynamic> conditionsList = data['idealConditions'] ?? [];
      final List<dynamic> seasonList = data['idealSeason'] ?? [];

      final lowerConditions = conditionsList.map((c) => c.toString().toLowerCase()).toList();
      final lowerSeasons = seasonList.map((s) => s.toString().toLowerCase()).toList();

      final timeMatch = lowerConditions.contains(timeOfDay);
      final weatherOrWindMatch = lowerConditions.contains(simplifiedWeather) || lowerConditions.contains(windTag.toLowerCase());
      final seasonMatches = lowerSeasons.contains(currentSeason);

      if (timeMatch && weatherOrWindMatch && seasonMatches) {
        matchingLures.add(data['name']);
      }
    }
    return matchingLures;
  }



 Future<void> _fetchLocation() async {
  setState(() {
    _isLoading = true;
    _locationErrorMessage = null;
  });

  try {
    Position position = await _getCurrentLocation();
    String locationString =
        'Latitude: ${position.latitude}, Longitude: ${position.longitude}';

    final weatherData =
        await _fetchWeather(position.latitude, position.longitude);
    final weatherInfo = weatherData['weather']!;
    final description = weatherData['description']!;

    final recommendedLures = await _getRecommendedLures(description, _getWindConditionTag(double.parse(weatherData['weather']!.split("Wind: ")[1].split(" ")[0])));


    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
        {
          'location': locationString,
          'weather': weatherInfo,
          'recommendedLures': recommendedLures,
          'email': user?.email,
        },
        SetOptions(merge: true),
      );
    }

    setState(() {
      _location =
          '$locationString\n$weatherInfo\nRecommended Lures: ${recommendedLures.join(", ")}';
      _recommendedLures = recommendedLures;
    });
  } catch (e) {
    setState(() {
      _locationErrorMessage = "Error fetching location: ${e.toString()}";
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
  
  Widget _recommendedLuresWidget() {
  if (_recommendedLures.isEmpty) {
    return const Center(
      child: Text("No lure recommendations found for current conditions."),
    );
  }

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Recommended Lures:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._recommendedLures.map((lureName) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lureName),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showLureInfo(lureName),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text('Info', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          );
        })
      ],
    ),
  );
}

Future<void> _showLureInfo(String lureName) async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('Lures')
        .where('name', isEqualTo: lureName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final literature = data['literature'] ?? 'No information available.';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(lureName),
          content: Text(literature),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog('No information found for this lure.');
    }
  } catch (e) {
    _showErrorDialog('Failed to fetch lure info: $e');
  }
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}



  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text("Fish Forecast");
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _locationInfo(){
    if (_isLoading){
      return const CircularProgressIndicator();
    }else if (_locationErrorMessage != null){
      return Text(
        _locationErrorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      );
    }else{
      return Text(
        _location ?? 'Location not available',
        style: const TextStyle(color: Colors.blue, fontSize: 14),
      );
    }
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text("Sign Out"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUid(),
            const SizedBox(height: 20),
            _locationInfo(),
            const SizedBox(height: 20),
            _recommendedLuresWidget(),
            const SizedBox(height: 20),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
