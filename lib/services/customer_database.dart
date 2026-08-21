import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/customer.dart';

class CustomerDatabase {
  CustomerDatabase._internal();

  static final CustomerDatabase instance = CustomerDatabase._internal();

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
    final path = join(databasesPath, 'my_customers.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            gender TEXT NOT NULL,
            firstVisit TEXT,
            lastVisit TEXT,
            appointment TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer> insertCustomer(Customer customer) async {
    final db = await database;
    final id = await db.insert('customers', customer.toMap()..remove('id'));
    return customer.copyWith(id: id);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllCustomers() async {
    final db = await database;
    await db.delete('customers');
  }
}
