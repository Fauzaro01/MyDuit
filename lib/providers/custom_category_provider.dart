import 'package:flutter/material.dart';
import '../models/custom_category_model.dart';
import '../services/database_service.dart';

class CustomCategoryProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<CustomCategoryModel> _categories = [];
  List<CustomCategoryModel> get categories => _categories;

  List<CustomCategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  List<CustomCategoryModel> get expenseCategories =>
      _categories.where((c) => !c.isIncome).toList();

  CustomCategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _categories = await _dbService.getAllCustomCategories();
    notifyListeners();
  }

  Future<void> addCategory(CustomCategoryModel category) async {
    await _dbService.insertCustomCategory(category);
    await loadCategories();
  }

  Future<void> updateCategory(CustomCategoryModel category) async {
    await _dbService.updateCustomCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _dbService.deleteCustomCategory(id);
    await loadCategories();
  }

  CustomCategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
