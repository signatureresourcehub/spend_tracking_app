import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Guide'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSection(
                'Home Page',
                [
                  _buildFeature(
                    'Login',
                    'Choose your login method:',
                    bulletPoints: [
                      'Continue with Google',
                      'Create account',
                      'Login with existing credentials',
                    ],
                  ),
                  _buildFeature(
                    'Set Budget',
                    'Enter your monthly budget. Our AI feature can also predict your budget based on your previous spending patterns.',
                  ),
                  _buildFeature(
                    'Add Transaction',
                    'Click the "+" icon in the top right corner to manually add a transaction:',
                    numberedPoints: [
                      'Select transaction type',
                      'Choose a category from the dropdown menu',
                      'Enter the amount',
                      'Set date and time',
                      'Click "Add Transaction" to save',
                    ],
                  ),
                ],
              ),
              _buildSection(
                'Analytics Page',
                [
                  _buildFeature(
                    'View Data',
                    'Select a date range or single date to analyze',
                  ),
                  _buildFeature(
                    'Save',
                    'After selecting your date preferences, click "Save"',
                  ),
                  _buildFeature(
                    'Visualization',
                    'View your financial data in pie chart format',
                  ),
                ],
              ),
              _buildSection(
                'Transaction Page',
                [
                  _buildFeature(
                    'Filter Transactions',
                    'Select a date range or single date',
                  ),
                  _buildFeature(
                    'Select Chart Type',
                    'Choose your preferred visualization method',
                  ),
                  _buildFeature(
                    'Save',
                    'Click "Save" to apply your selections',
                  ),
                  _buildFeature(
                    'Results',
                    'View a pie chart showing your spending categorized by expense type',
                  ),
                ],
              ),
              _buildSection(
                'Account Page',
                [
                  _buildFeature(
                    'Collaborator Tool',
                    'Connect with others by entering their unique code',
                  ),
                  _buildFeature(
                    'Your Unique Code',
                    'Find your personal code at the bottom of this page to share with others',
                  ),
                  _buildFeature(
                    'Delete Collaboration',
                    'Remove a connection using the delete button',
                  ),
                  _buildFeature(
                    'Logout',
                    'Sign out of the app using the logout option',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Personal Finance Management System Help',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Welcome to the Personal Finance Management System! This guide will help you navigate the different features of our app.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...features,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFeature(String title, String description,
      {List<String>? bulletPoints, List<String>? numberedPoints}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.star, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (bulletPoints != null) ...[
                  const SizedBox(height: 8),
                  ...bulletPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white)),
                            Expanded(
                              child: Text(
                                point,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                if (numberedPoints != null) ...[
                  const SizedBox(height: 8),
                  ...List.generate(
                    numberedPoints.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${index + 1}. ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                          Expanded(
                            child: Text(
                              numberedPoints[index],
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// To use this page in your app, you would navigate to it like this:
// Navigator.push(
//   context,
//   MaterialPageRoute(builder: (context) => const HelpPage()),
// );