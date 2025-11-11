// ignore_for_file: library_private_types_in_public_api
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reorderable_list/features/home/presentation/screens/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  var _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      Timer(const Duration(milliseconds: 2000), () => _navigation(context));
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  _navigation(BuildContext context) =>
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Center(
          child: Text(
            "Task Queuw Manager",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
              letterSpacing: 2,
              fontFamily: 'Geist',
            ),
          ),
        ),
      ),
    );
  }
}
