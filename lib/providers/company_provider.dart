import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/company.dart';

class CompanyProvider extends ChangeNotifier {
  Company? _company;
  bool _isLoading = false;

  Company? get company => _company;
  bool get isLoading => _isLoading;

  CompanyProvider() {
    loadCompany();
  }

  Future<void> loadCompany() async {
    _isLoading = true;
    notifyListeners();
    _company = await DatabaseHelper.instance.getCompany();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCompany(Company newCompany) async {
    await DatabaseHelper.instance.saveCompany(newCompany);
    await loadCompany();
  }
}
