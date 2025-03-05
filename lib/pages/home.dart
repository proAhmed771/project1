import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  final String text;

  const Home({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Result Page")),
      body: Center(
        child: Text(
          "You selected: $text",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
