import 'package:flutter/material.dart';
import 'package:myapp/account.dart';
import 'package:myapp/bottom_navigation.dart';
import 'package:myapp/dashboard.dart';
import 'package:myapp/spend.dart';
import 'package:myapp/transactions.dart';

final pages = [DashBoard(), SpendPage(), TransactionPage(), AccountPage()];
final tites = ["Home", "Spend", "Transactions", "Account"];

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: indexChanged,
      builder: (context, int index, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tites[index]),
          ),
          bottomNavigationBar: const CustomerBottomNav(),
          body: pages[index],
        );
      },
    );
  }
}
