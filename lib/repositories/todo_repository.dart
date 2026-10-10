import '../database/database_helper.dart';
import '../models/todo.dart';

class TodoRepository {
  final DatabaseHelper _databaseHelper;

  TodoRepository(this._databaseHelper);

  // CREATE
  Future<void> addTodo(Todo todo) async {
    final db = await _databaseHelper.database;

    await db.insert(
      'todos',
      todo.toMap(),
    );
  }

  // READ - All
  Future<List<Todo>> getAllTodos() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'todos',
      orderBy: 'id DESC',
    );

    return result
        .map((map) => Todo.fromMap(map))
        .toList();
  }

  // READ - Pending
  Future<List<Todo>> getPendingTodos() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );

    return result
        .map((map) => Todo.fromMap(map))
        .toList();
  }

  // READ - Completed
  Future<List<Todo>> getCompletedTodos() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return result
        .map((map) => Todo.fromMap(map))
        .toList();
  }

  // READ - Important
  Future<List<Todo>> getImportantTodos() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'todos',
      where: 'important = ?',
      whereArgs: [1],
      orderBy: 'id DESC',
    );

    return result
        .map((map) => Todo.fromMap(map))
        .toList();
  }

  // UPDATE
  Future<void> updateTodo(Todo todo) async {
    final db = await _databaseHelper.database;

    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // DELETE
  Future<void> deleteTodo(int id) async {
    final db = await _databaseHelper.database;

    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // TOGGLE COMPLETED
  Future<void> toggleCompleted(
      int id,
      bool completed,
      ) async {
    final db = await _databaseHelper.database;

    await db.update(
      'todos',
      {
        'completed': completed ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}