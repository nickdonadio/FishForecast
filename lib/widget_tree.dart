import 'package:flutter/material.dart';
import 'package:fish_forecast/auth.dart';
import 'package:fish_forecast/screens/home_page.dart';
import 'package:fish_forecast/screens/login_register_page.dart';

class WidgetTree extends StatefulWidget{
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree>{
  @override
  Widget build(BuildContext context){
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot){
        if (snapshot.hasData){
          return HomePage();
        }else {
          return const LoginPage();
        }
      },
    );
  }
}