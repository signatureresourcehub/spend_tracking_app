import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class IntroPage2 extends StatelessWidget {
  const IntroPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("test 2"),
          Center(
            child: Lottie.asset('assets/animations/Animation2.json'),
          ),
        ],
      ),
    );
  }
}
