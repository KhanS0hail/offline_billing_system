import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import '../models/company.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billing_system.db');
    await _ensureSchemaUpToDate(_database!);
    return _database!;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        invoice_type $textNull,
        invoice_number $textNull,
        challan_number $textNull,
        delivery_date $textNull,
        vehicle_number $textNull,
        transport_mode $textNull,
        customer_id $intNull,
        customer_name $textNull,
        customer_gstin $textNull,
        customer_state_code $textNull,
        customer_address $textNull,
        shipping_customer_name $textNull,
        shipping_address $textNull,
        shipping_gstin $textNull,
        shipping_state_code $textNull,
        date $textNull,
        due_date $textNull,
        status $textNull,
        subtotal $realNull,
        transport_charges $realNull,
        taxable_base $realNull,
        gst_rate $realNull,
        cgst_total $realNull,
        sgst_total $realNull,
        igst_total $realNull,
        total_tax $realNull,
        discount_amount $realNull,
        round_off $realNull,
        grand_total $realNull,
        received_amount $realNull,
        balance_amount $realNull,
        notes $textNull
      )
    ''');

    // 5. Invoice Items Table
    await db.execute('''
      CREATE TABLE invoice_items (
        id $idType,
        invoice_id $intNull,
        product_id $intNull,
        product_name $textNull,
        size $textNull,
        pcs_count $textNull,
        hsn_code $textNull,
        quantity $intNull,
        unit $textNull,
        price $realNull,
        amount $realNull,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _ensureSchemaUpToDate(db);
  }

  Future<void> _ensureSchemaUpToDate(Database db) async {
    // Ensure all tables exist
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER
      )
    ''');

    // Company columns
    await _addColumnIfNotExists(db, 'company', 'tagline', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'phone', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'email', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'address', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'gst_number', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'state_code', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'bank_name', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'account_number', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'ifsc_code', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'bank_branch', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'upi_id', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'payment_duration_days', 'INTEGER');
    await _addColumnIfNotExists(db, 'company', 'logo_base64', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'signature_base64', 'TEXT');
    await _addColumnIfNotExists(db, 'company', 'terms_and_conditions', 'TEXT');

    // Customer columns
    await _addColumnIfNotExists(db, 'customers', 'contact_person', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'phone', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'email', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'address', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'gst_number', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'state_code', 'TEXT');
    await _addColumnIfNotExists(db, 'customers', 'opening_balance', 'REAL');

    // Product columns
    await _addColumnIfNotExists(db, 'products', 'description', 'TEXT');
    await _addColumnIfNotExists(db, 'products', 'hsn_code', 'TEXT');
    await _addColumnIfNotExists(db, 'products', 'unit', 'TEXT');
    await _addColumnIfNotExists(db, 'products', 'price', 'REAL');
    await _addColumnIfNotExists(db, 'products', 'gst_rate', 'REAL');

    // Invoices columns
    await _addColumnIfNotExists(db, 'invoices', 'invoice_type', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'challan_number', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'delivery_date', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'vehicle_number', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'transport_mode', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'customer_id', 'INTEGER');
    await _addColumnIfNotExists(db, 'invoices', 'customer_name', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'customer_gstin', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'customer_state_code', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'customer_address', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'shipping_customer_name', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'shipping_address', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'shipping_gstin', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'shipping_state_code', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'date', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'due_date', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'payment_date', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'status', 'TEXT');
    await _addColumnIfNotExists(db, 'invoices', 'subtotal', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'transport_charges', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'taxable_base', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'gst_rate', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'cgst_total', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'sgst_total', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'igst_total', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'total_tax', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'discount_amount', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'round_off', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'grand_total', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'received_amount', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'balance_amount', 'REAL');
    await _addColumnIfNotExists(db, 'invoices', 'notes', 'TEXT');

    // Invoice Items columns
    await _addColumnIfNotExists(db, 'invoice_items', 'product_id', 'INTEGER');
    await _addColumnIfNotExists(db, 'invoice_items', 'product_name', 'TEXT');
    await _addColumnIfNotExists(db, 'invoice_items', 'size', 'TEXT');
    await _addColumnIfNotExists(db, 'invoice_items', 'pcs_count', 'TEXT');
    await _addColumnIfNotExists(db, 'invoice_items', 'hsn_code', 'TEXT');
    await _addColumnIfNotExists(db, 'invoice_items', 'quantity', 'INTEGER');
    await _addColumnIfNotExists(db, 'invoice_items', 'unit', 'TEXT');
    await _addColumnIfNotExists(db, 'invoice_items', 'price', 'REAL');
    await _addColumnIfNotExists(db, 'invoice_items', 'amount', 'REAL');
  }

  static Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      final exists = info.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
      }
    } catch (_) {
      // Ignored
    }
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

  // --- INVOICES CRUD ---
  Future<String> generateNextInvoiceNumber() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT MAX(id) as max_id FROM invoices');
    int maxId = (result.first['max_id'] as int?) ?? 0;
    int nextId = maxId + 1;
    final year = DateTime.now().year;
    return 'INV-$year-${nextId.toString().padLeft(4, '0')}';
  }

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await instance.database;
    int invoiceId = 0;

    await db.transaction((txn) async {
      invoiceId = await txn.insert('invoices', invoice.toMap());

      for (var item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoiceId).toMap();
        await txn.insert('invoice_items', itemMap);
      }
    });

    return invoiceId;
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await instance.database;
    if (invoice.id == null) return;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Replace line items
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoice.id]);

      for (var item in invoice.items) {
        final itemMap = item.copyWith(invoiceId: invoice.id).toMap();
        await txn.insert('invoice_items', itemMap);
      }
    });
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await instance.database;
    final result = await db.query('invoices', orderBy: 'id DESC');

    List<Invoice> invoices = [];
    for (var map in result) {
      int invoiceId = map['id'] as int;
      final itemsResult = await db.query(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );
      final items = itemsResult.map((iMap) => InvoiceItem.fromMap(iMap)).toList();
      invoices.add(Invoice.fromMap(map, items: items));
    }
    return invoices;
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await instance.database;
    final result = await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isEmpty) return null;

    final itemsResult = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    final items = itemsResult.map((iMap) => InvoiceItem.fromMap(iMap)).toList();

    return Invoice.fromMap(result.first, items: items);
  }

  Future<int> updateInvoiceStatus(int id, String status, {double? receivedAmount, double? balanceAmount, String? paymentDate}) async {
    final db = await instance.database;
    Map<String, dynamic> updateData = {'status': status};
    if (receivedAmount != null) updateData['received_amount'] = receivedAmount;
    if (balanceAmount != null) updateData['balance_amount'] = balanceAmount;
    if (paymentDate != null) updateData['payment_date'] = paymentDate;

    return await db.update(
      'invoices',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
      return await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
