import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import '../models/custom_category_model.dart';
import '../providers/custom_category_provider.dart';

class CustomCategoriesScreen extends StatelessWidget {
  const CustomCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<CustomCategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Kustom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, isDark),
          ),
        ],
      ),
      body: provider.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: 64,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori kustom',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan kategori sesuai kebutuhanmu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context, isDark),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Kategori'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Income categories
                if (provider.incomeCategories.isNotEmpty) ...[
                  Text(
                    'PEMASUKAN',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.incomeCategories.asMap().entries.map((entry) {
                    return _CategoryTile(
                      category: entry.value,
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * entry.key),
                          duration: 300.ms,
                        )
                        .slideX(begin: 0.05, end: 0);
                  }),
                  const SizedBox(height: 24),
                ],

                // Expense categories
                if (provider.expenseCategories.isNotEmpty) ...[
                  Text(
                    'PENGELUARAN',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...provider.expenseCategories.asMap().entries.map((entry) {
                    return _CategoryTile(
                      category: entry.value,
                      isDark: isDark,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * entry.key),
                          duration: 300.ms,
                        )
                        .slideX(begin: 0.05, end: 0);
                  }),
                ],
              ],
            ),
    );
  }

  void _showAddDialog(BuildContext context, bool isDark) {
    _showCategoryDialog(context, isDark: isDark);
  }

  static void _showCategoryDialog(
    BuildContext context, {
    required bool isDark,
    CustomCategoryModel? existing,
  }) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emojiController = TextEditingController(text: existing?.emoji ?? '📌');
    bool isIncome = existing?.isIncome ?? false;
    int colorValue = existing?.colorValue ?? 0xFF0D9373;

    final emojis = [
      '🏠', '🚌', '🍽️', '👕', '💊', '📱', '🐶', '🎨',
      '🏋️', '☕', '🎬', '📦', '🔧', '💼', '🎯', '📌',
      '💎', '🎸', '🌱', '🍕', '🎮', '🛒', '✨', '🔔',
    ];

    final colors = [
      0xFF0D9373, 0xFF10B981, 0xFF3B82F6, 0xFF8B5CF6,
      0xFFEC4899, 0xFFEF4444, 0xFFF59E0B, 0xFF6366F1,
      0xFF14B8A6, 0xFF84CC16, 0xFFE11D48, 0xFF0891B2,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing != null
                          ? 'Edit Kategori'
                          : 'Tambah Kategori',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),

                    // Type toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isIncome = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isIncome
                                    ? AppColors.income.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: isIncome
                                    ? Border.all(color: AppColors.income)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pemasukan',
                                style: TextStyle(
                                  color: isIncome
                                      ? AppColors.income
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                  fontWeight: isIncome
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isIncome = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isIncome
                                    ? AppColors.expense.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: !isIncome
                                    ? Border.all(color: AppColors.expense)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Pengeluaran',
                                style: TextStyle(
                                  color: !isIncome
                                      ? AppColors.expense
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                  fontWeight: !isIncome
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        hintText: 'Contoh: Langganan',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Emoji picker
                    Text('Ikon', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emojis.map((emoji) {
                        final selected = emojiController.text == emoji;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => emojiController.text = emoji),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Color(colorValue).withValues(alpha: 0.2)
                                  : (isDark
                                      ? AppColors.cardAltDark
                                      : AppColors.cardAltLight),
                              borderRadius: BorderRadius.circular(10),
                              border: selected
                                  ? Border.all(
                                      color: Color(colorValue), width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color picker
                    Text('Warna', style: Theme.of(ctx).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) {
                        final selected = colorValue == color;
                        return GestureDetector(
                          onTap: () => setState(() => colorValue = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Color(color)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          final provider = ctx.read<CustomCategoryProvider>();
                          final category = CustomCategoryModel(
                            id: existing?.id,
                            name: nameController.text.trim(),
                            emoji: emojiController.text,
                            isIncome: isIncome,
                            colorValue: colorValue,
                          );
                          if (existing != null) {
                            provider.updateCategory(category);
                          } else {
                            provider.addCategory(category);
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(existing != null ? 'Simpan' : 'Tambah'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CustomCategoryModel category;
  final bool isDark;

  const _CategoryTile({required this.category, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(category.colorValue);

    return Dismissible(
      key: Key(category.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Kategori?'),
            content: Text('Hapus "${category.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<CustomCategoryProvider>().deleteCategory(category.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.isIncome ? 'Pemasukan' : 'Pengeluaran',
                    style: TextStyle(
                      fontSize: 12,
                      color: category.isIncome
                          ? AppColors.income
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              onPressed: () {
                CustomCategoriesScreen._showCategoryDialog(
                  context,
                  isDark: isDark,
                  existing: category,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
