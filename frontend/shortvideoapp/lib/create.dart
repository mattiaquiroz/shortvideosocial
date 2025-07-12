import 'package:flutter/material.dart';

class Create extends StatelessWidget {
  const Create({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CreatePage(),
      debugShowCheckedModeBanner: false
    );
  }
}

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create'),
      ),
      body: const Center(
        child: Text('Create New Content'),
      ),
    );
  }
}