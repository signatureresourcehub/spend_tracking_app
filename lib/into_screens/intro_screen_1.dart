import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class IntroPage1 extends StatelessWidget {
  const IntroPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Hey there!!"),
          Center(
            child: Lottie.asset('assets/animations/Animation1.json'),
          ),
        ],
      ),
    );
  }
}
