class Task {
  final int id;
  String title;
  DateTime time;
  String category;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.time,
    this.category = 'Chung',
    this.isDone = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      time: DateTime.parse(map['time']),
      category: map['category'] ?? 'Chung',
      isDone: map['done'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': time.toIso8601String(),
      'category': category,
      'done': isDone ? 1 : 0,
    };
  }
}
