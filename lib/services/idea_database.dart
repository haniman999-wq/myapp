import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/idea.dart';

class IdeaDatabase {
  IdeaDatabase._internal();

  static final IdeaDatabase instance = IdeaDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final db = await _initDatabase();
    _database = db;
    return db;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'idea_vault.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ideas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Idea>> getAllIdeas() async {
    final db = await database;
    final rows = await db.query('ideas', orderBy: 'createdAt DESC');
    return rows.map(Idea.fromMap).toList();
  }

  Future<Idea> insertIdea(Idea idea) async {
    final db = await database;
    final id = await db.insert('ideas', idea.toMap()..remove('id'));
    return idea.copyWith(id: id);
  }

  Future<void> updateIdea(Idea idea) async {
    final db = await database;
    await db.update(
      'ideas',
      idea.toMap(),
      where: 'id = ?',
      whereArgs: [idea.id],
    );
  }

  Future<void> deleteIdea(int id) async {
    final db = await database;
    await db.delete('ideas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'ideas',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
