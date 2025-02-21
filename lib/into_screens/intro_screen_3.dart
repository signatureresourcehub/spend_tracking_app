import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class IntroPage3 extends StatelessWidget {
  const IntroPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Every transcation  tells your financial story"),
          Center(
            child: Lottie.asset('assets/animations/Animation3.json'),
          ),
        ],
      ),
    );
  }
}
