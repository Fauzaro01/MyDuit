import 'package:flutter/foundation.dart';
import '../models/tag_model.dart';
import '../services/database_service.dart';

class TagProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<TagModel> _tags = [];
  bool _isLoading = false;

  List<TagModel> get tags => _tags;
  bool get isLoading => _isLoading;

  Future<void> loadTags() async {
    _isLoading = true;
    notifyListeners();
    try {
      _tags = await _db.getAllTags();
      _tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (e) {
      debugPrint('Error loading tags: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTag(String name, {int colorValue = 0xFF0D9373}) async {
    final clean = name.trim().replaceAll('#', '');
    if (clean.isEmpty) return;
    if (_tags.any((t) => t.name.toLowerCase() == clean.toLowerCase())) return;

    final tag = TagModel(name: clean, colorValue: colorValue);
    await _db.insertTag(tag);
    _tags.add(tag);
    _tags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    notifyListeners();
  }

  Future<void> deleteTag(String id) async {
    await _db.deleteTag(id);
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
