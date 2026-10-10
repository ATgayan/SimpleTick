import 'package:flutter/material.dart';

import 'views/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'repositories/todo_repository.dart';

import 'viewmodels/todo_viewmodel.dart';



void main() {
  final repository = TodoRepository(DatabaseHelper.instance);
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoViewModel(repository),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
