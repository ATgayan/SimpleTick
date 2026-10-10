class Todo {
  final int? id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final bool important;
  final DateTime? dueDate;
  final String? dueTime;
  final bool completed;

  Todo({
    this.id,
    required this.title,
    this.description = '',
    required this.category,
    required this.priority,
    this.important = false,
    this.dueDate,
    this.dueTime,
    this.completed = false,
  });

  // Todo → SQLite data
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'important': important ? 1 : 0,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime,
      'completed': completed ? 1 : 0,
    };
  }

  // SQLite data → Todo
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      category: map['category'],
      priority: map['priority'],
      important: map['important'] == 1,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : null,
      dueTime: map['dueTime'],
      completed: map['completed'] == 1,
    );
  }

  Todo copyWith({
    String? title,
    String? description,
    String? category,
    String? priority,
    bool? important,
    DateTime? dueDate,
    String? dueTime,
    bool? completed,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      important: important ?? this.important,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      completed: completed ?? this.completed,
    );
  }
}