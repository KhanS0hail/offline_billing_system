import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billing_system.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      password: 'default_secure_key',
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE company (
        id $idType,
        name $textType,
        email $textNullType,
        phone $textNullType,
        address $textNullType,
        gst_number $textNullType,
        logo_base64 $textNullType
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textType,
        email $textNullType,
        phone $textNullType,
        address $textNullType,
        gst_number $textNullType
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        hsn_code $textNullType,
        price $realType,
        stock $intType,
        gst_rate $realType
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id $idType,
        invoice_number $textType,
        customer_id $intType,
        date $textType,
        subtotal $realType,
        tax_amount $realType,
        total_amount $realType,
        is_paid $boolType,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id $idType,
        invoice_id $intType,
        product_id $intType,
        quantity $intType,
        price $realType,
        total $realType,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
