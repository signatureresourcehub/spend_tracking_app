import 'package:flutter/material.dart';

ValueNotifier<int> indexChanged = ValueNotifier(0);

class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: indexChanged,
      builder: (context, int newIndex, _) {
        return BottomNavigationBar(
            currentIndex: newIndex,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey[700],
            showUnselectedLabels: true,
            backgroundColor: Colors.grey[100],
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              indexChanged.value = index;
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.money), label: 'Analyticts'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance), label: 'Transactions'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle), label: 'Account')
            ]);
      },
    );
  }
}
