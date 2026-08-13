import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/product.dart';

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
    const textNull = 'TEXT';
    const realNull = 'REAL';
    const intNull = 'INTEGER';

    // 1. Company Table
    await db.execute('''
      CREATE TABLE company (
        id $idType,
        name $textNull,
        tagline $textNull,
        phone $textNull,
        email $textNull,
        address $textNull,
        gst_number $textNull,
        state_code $textNull,
        bank_name $textNull,
        account_number $textNull,
        ifsc_code $textNull,
        bank_branch $textNull,
        upi_id $textNull,
        payment_duration_days $intNull,
        logo_base64 $textNull,
        signature_base64 $textNull,
        terms_and_conditions $textNull
      )
    ''');

    // 2. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id $idType,
        name $textNull,
        contact_person $textNull,
        phone $textNull,
        email $textNull,
        address $textNull,
        gst_number $textNull,
        state_code $textNull,
        opening_balance $realNull
      )
    ''');

    // 3. Products Table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textNull,
        description $textNull,
        hsn_code $textNull,
        unit $textNull,
        price $realNull,
        gst_rate $realNull
      )
    ''');

    // 4. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id $idType,
        invoice_number $textNull,
        customer_id $intNull,
        date $textNull,
        subtotal $realNull,
        tax_amount $realNull,
        total_amount $realNull,
        is_paid $intNull,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // 5. Invoice Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id $idType,
        invoice_id $intNull,
        product_id $intNull,
        quantity $intNull,
        price $realNull,
        total $realNull,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // --- COMPANY CRUD ---
  Future<Company?> getCompany() async {
    final db = await instance.database;
    final result = await db.query('company', limit: 1);
    if (result.isNotEmpty) {
      return Company.fromMap(result.first);
    }
    return null;
  }

  Future<int> saveCompany(Company company) async {
    final db = await instance.database;
    final existing = await getCompany();
    if (existing == null) {
      return await db.insert('company', company.toMap());
    } else {
      return await db.update(
        'company',
        company.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  // --- CUSTOMERS CRUD ---
  Future<List<Customer>> getCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((json) => Customer.fromMap(json)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- PRODUCTS CRUD ---
  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
