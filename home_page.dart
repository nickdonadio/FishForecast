import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fish_forecast/auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = Auth().currentUser;
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  String? _locationErrorMessage;

  Future<void> signOut() async {
    await Auth().signOut();
  }
  Future<void> saveLocation() async {
    if (_locationController.text.isEmpty) {
      setState(() {
        _locationErrorMessage = "Location cannot be empty";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set(
        {
          'location': _locationController.text.trim(),
          'email': user?.email,
        },
        SetOptions(merge: true), 
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location saved successfully!")),
        );
      }
    } catch (e) {
      setState(() {
        _locationErrorMessage = "Error saving location: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _title() {
    return const Text("Fish Forecast");
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
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
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: "Enter your location",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            _locationErrorMessage != null
                ? Text(
                    _locationErrorMessage!,
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  )
                : Container(),
            const SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveLocation,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(fontSize: 18),
                    ),
                    child: Text("Save Location"),
                  ),
            const SizedBox(height: 20),
            _signOutButton(),
          ],
        ),
      ),
    );
  }
}



// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fish_forecast/auth.dart';
// import 'package:flutter/material.dart';

// class HomePage extends StatelessWidget{
//   HomePage({super.key});

//   final User? user = Auth().currentUser;

//   Future<void> signOut() async {
//     await Auth().signOut();
//   }

//   Widget _title(){
//     return const Text("Fish Forecast");
//   }

//   Widget _userUid(){
//     return Text(user?.email ?? 'User email');
//   }

//   Widget _signOutButton(){
//     return ElevatedButton(
//       onPressed: signOut,
//       child: const Text("Sign Out"),
//     );
//   }

//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//       appBar: AppBar(
//         title: _title(),
//       ),
//       body: Container(
//         height: double.infinity,
//         width: double.infinity,
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             _userUid(),
//             _signOutButton(),
//           ]
//         )
//       )
//     );
//   }
// }