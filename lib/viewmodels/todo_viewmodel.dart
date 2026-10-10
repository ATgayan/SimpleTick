import 'package:flutter/foundation.dart';

import '../models/todo.dart';
import '../repositories/todo_repository.dart';

class TodoViewModel extends ChangeNotifier {
  final TodoRepository _repository;

  TodoViewModel(this._repository);

  List<Todo> _todos = [];

  bool _isLoading = false;

  List<Todo> get todos => _todos;

  bool get isLoading => _isLoading;

  // LOAD ALL
  Future<void> getAllTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _repository.getAllTodos();

    _isLoading = false;
    notifyListeners();
  }

  // ADD
  Future<void> addTodo(Todo todo) async {
    await _repository.addTodo(todo);

    await getAllTodos();
  }

  // PENDING
  Future<void> getPendingTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _repository.getPendingTodos();

    _isLoading = false;
    notifyListeners();
  }

  // COMPLETED
  Future<void> getCompletedTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _repository.getCompletedTodos();

    _isLoading = false;
    notifyListeners();
  }

  // IMPORTANT
  Future<void> getImportantTodos() async {
    _isLoading = true;
    notifyListeners();

    _todos = await _repository.getImportantTodos();

    _isLoading = false;
    notifyListeners();
  }

  // UPDATE
  Future<void> updateTodo(Todo todo) async {
    await _repository.updateTodo(todo);

    await getAllTodos();
  }

  // DELETE
  Future<void> deleteTodo(int id) async {
    await _repository.deleteTodo(id);

    await getAllTodos();
  }

  // TOGGLE COMPLETED
  Future<void> toggleCompleted(
      Todo todo,
      bool completed,
      ) async {
    await _repository.toggleCompleted(
      todo.id!,
      completed,
    );

    await getAllTodos();
  }
}