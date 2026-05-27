import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'auth_screen.dart';
import 'feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  String? _token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🥩', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'High Steak',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD4A054),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rate steak meals. Share photos. Join the grill.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final token = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(api: _api, register: false),
                      ),
                    );
                    if (token != null) setState(() => _token = token);
                  },
                  child: const Text('Log in'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final token = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(api: _api, register: true),
                      ),
                    );
                    if (token != null) setState(() => _token = token);
                  },
                  child: const Text('Create account'),
                ),
              ),
              if (_token != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FeedScreen(api: _api),
                        ),
                      );
                    },
                    child: const Text('Open feed'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
