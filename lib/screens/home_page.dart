import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fish_forecast/auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';


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

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }
  
  Future<void> _fetchLocation() async {
    setState((){
      _isLoading = true;
      _locationErrorMessage = null;
    });
    try {
      Position position = await _getCurrentLocation();
      String locationString = 'Latitude: ${position.latitude}, Longitude: ${position.longitude}';

      if (user != null){
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
          {
            'location': locationString,
            'email': user?.email,
          },
          SetOptions(merge: true), 
        );
      }
      setState((){
        _location = locationString;
      });
    }catch(e){
      setState((){
        _locationErrorMessage = "Error fetching location: ${e.toString()}";
      });
  } finally{
      setState((){
        _isLoading = false;
      });
    }
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
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}
