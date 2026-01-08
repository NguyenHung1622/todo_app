import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'todo.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY,
            title TEXT,
            time TEXT,
            category TEXT,
            done INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', {
      'id': task.id,
      'title': task.title,
      'time': task.time.toIso8601String(),
      'category': task.category,
      'done': task.isDone ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', {
      'title': task.title,
      'time': task.time.toIso8601String(),
      'category': task.category,
      'done': task.isDone ? 1 : 0,
    }, where: 'id = ?', whereArgs: [task.id]);
  }

  static Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}
