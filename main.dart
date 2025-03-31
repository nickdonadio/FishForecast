import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fish_forecast/widget_tree.dart';


const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyCm0uLtex9OCqBrL5MjKjpzk5SWruo0FxU",
  authDomain: "fish-forecast.firebaseapp.com",
  projectId: "fish-forecast",
  storageBucket: "fish-forecast.firebasestorage.app",
  messagingSenderId: "316812327596",
  appId: "1:316812327596:web:dad2f6049a7b660e9a7d09",
  measurementId: "G-5DPFMEWX21",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WidgetTree(),
    );
  }
}
