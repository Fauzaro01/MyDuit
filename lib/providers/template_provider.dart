import 'package:flutter/foundation.dart';
import '../models/transaction_template_model.dart';
import '../services/database_service.dart';

class TemplateProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<TransactionTemplateModel> _templates = [];
  bool _isLoading = false;

  List<TransactionTemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;

  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();
    try {
      _templates = await _db.getAllTemplates();
    } catch (e) {
      debugPrint('Error loading templates: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTemplate(TransactionTemplateModel template) async {
    await _db.insertTemplate(template);
    _templates.add(template);
    notifyListeners();
  }

  Future<void> updateTemplate(TransactionTemplateModel template) async {
    await _db.updateTemplate(template);
    final index = _templates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _templates[index] = template;
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String id) async {
    await _db.deleteTemplate(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
