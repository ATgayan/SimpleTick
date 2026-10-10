import 'package:flutter/material.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do App'),
      ),

      body:  Center(
        child: ElevatedButton(
          onPressed: () {
            print('Add Todo clicked');
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                if (states.contains(WidgetState.hovered)) {
                  return Colors.green; // Hover color
                }

                return Colors.blue; // Normal color
              },
            ),
          ),
          child: const Text(
            'Add Todo',
            style: TextStyle(color: Colors.white),
          ),
        )
      ),
    );
  }
}