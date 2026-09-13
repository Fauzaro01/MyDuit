import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';

class EmojiGroup {
  final String title;
  final String icon;
  final List<String> emojis;

  const EmojiGroup({
    required this.title,
    required this.icon,
    required this.emojis,
  });
}

class EmojiPickerSheet extends StatefulWidget {
  final String? initialEmoji;

  const EmojiPickerSheet({super.key, this.initialEmoji});

  static Future<String?> show(BuildContext context, {String? initialEmoji}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EmojiPickerSheet(initialEmoji: initialEmoji),
    );
  }

  @override
  State<EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<EmojiPickerSheet> {
  static const List<EmojiGroup> groups = [
    EmojiGroup(
      title: 'Keuangan',
      icon: '💰',
      emojis: [
        '💰', '💵', '💳', '🏦', '📈', '📉', '🪙', '💎',
        '💼', '🧾', '🏷️', '💸', '🤑', '🏧', '📊', '👛',
      ],
    ),
    EmojiGroup(
      title: 'Makanan',
      icon: '🍛',
      emojis: [
        '🍛', '🍔', '🍕', '🍜', '☕', '🍱', '🍲', '🥗',
        '🍰', '🧋', '🍦', '🍣', '🥑', '🍎', '🥪', '🍟',
        '🍿', '🍩', '🍪', '🍫', '🥩', '🍗', '🍳', '🥖',
      ],
    ),
    EmojiGroup(
      title: 'Transportasi',
      icon: '🚗',
      emojis: [
        '🚗', '🏍️', '⛽', '🚌', '🚆', '✈️', '🚲', '🛵',
        '🅿️', '🚕', '🛳️', '🚁', '🛴', '🛞', '🚦', '⚓',
      ],
    ),
    EmojiGroup(
      title: 'Belanja & Barang',
      icon: '🛍️',
      emojis: [
        '🛍️', '👕', '🛒', '👟', '💄', '🎁', '📦', '🧴',
        '📱', '💻', '🎧', '📚', '👗', '👜', '🕶️', '⌚',
      ],
    ),
    EmojiGroup(
      title: 'Tagihan & Rumah',
      icon: '💡',
      emojis: [
        '💡', '⚡', '💧', '📱', '🏠', '📶', '🌐', '🔧',
        '🏥', '💊', '🛡️', '📄', '🏢', '🚪', '🔑', '🧹',
      ],
    ),
    EmojiGroup(
      title: 'Lifestyle & Hiburan',
      icon: '🎮',
      emojis: [
        '🎮', '🎬', '🍿', '🎧', '✈️', '🏖️', '🏋️', '⚽',
        '🎨', '🎵', '🎟️', '🏕️', '🏊', '🚴', '⛺', '🎳',
      ],
    ),
    EmojiGroup(
      title: 'Simbol & Umum',
      icon: '⭐',
      emojis: [
        '⭐', '🎯', '📌', '🔑', '🌟', '🔥', '⚡', '🔔',
        '❤️', '🚀', '💡', '🐾', '🪴', '🌸', '✨', '🏆',
      ],
    ),
  ];

  int _selectedGroupIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeGroup = groups[_selectedGroupIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_emotions_outlined, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Pilih Emoji / Ikon',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Group category bar
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  final isSelected = _selectedGroupIndex == index;
                  return ChoiceChip(
                    avatar: Text(group.icon, style: const TextStyle(fontSize: 14)),
                    label: Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedGroupIndex = index);
                    },
                    selectedColor: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withValues(alpha: 0.2),
                    backgroundColor: isDark ? AppColors.cardAltDark : AppColors.cardAltLight,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Emoji grid
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: activeGroup.emojis.length,
                itemBuilder: (context, index) {
                  final emoji = activeGroup.emojis[index];
                  final isCurrent = widget.initialEmoji == emoji;

                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, emoji);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                                .withValues(alpha: 0.25)
                            : (isDark ? AppColors.cardAltDark : AppColors.cardAltLight),
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrent
                            ? Border.all(
                                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                                width: 2,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
