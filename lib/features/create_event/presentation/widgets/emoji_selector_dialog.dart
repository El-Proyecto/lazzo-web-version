import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/widgets/grabber_bar.dart';

/// Bottom sheet para seleção de emoji
/// Exibe grid de emojis organizados por categorias com seleção por toque
class EmojiSelectorBottomSheet extends StatefulWidget {
  final String? selectedEmoji;
  final Function(String)? onEmojiSelected;

  const EmojiSelectorBottomSheet({
    super.key,
    this.selectedEmoji,
    this.onEmojiSelected,
  });

  @override
  State<EmojiSelectorBottomSheet> createState() =>
      _EmojiSelectorBottomSheetState();
}

class _EmojiSelectorBottomSheetState extends State<EmojiSelectorBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();

  // Lista de categorias de emoji
  final List<EmojiCategory> _categories = [
    EmojiCategory(
      name: 'Recent',
      icon: Icons.access_time,
      emojis: ['🎉', '🎊', '🎈', '🍰', '🎁', '🥳', '🎭', '🎪'],
    ),
    EmojiCategory(
      name: 'Smileys',
      icon: Icons.sentiment_satisfied,
      emojis: [
        '😀',
        '😃',
        '😄',
        '😁',
        '😆',
        '😅',
        '😂',
        '🤣',
        '😊',
        '😇',
        '🙂',
        '🙃',
        '😉',
        '😌',
        '😍',
        '🥰',
        '😘',
        '😗',
        '😙',
        '😚',
        '😋',
        '😛',
        '😝',
        '😜',
        '🤪',
        '🤨',
        '🧐',
        '🤓',
        '😎',
        '🤩',
        '🥳',
        '😏',
      ],
    ),
    EmojiCategory(
      name: 'Gestures',
      icon: Icons.pan_tool,
      emojis: [
        '👋',
        '🤚',
        '🖐️',
        '✋',
        '🖖',
        '👌',
        '🤌',
        '🤏',
        '✌️',
        '🤞',
        '🫰',
        '🤟',
        '🤘',
        '🤙',
        '👈',
        '👉',
        '👆',
        '🖕',
        '👇',
        '☝️',
        '🫵',
        '👍',
        '👎',
        '👊',
        '✊',
        '🤛',
        '🤜',
        '👏',
        '🙌',
        '🫶',
        '👐',
        '🤲',
      ],
    ),
    EmojiCategory(
      name: 'Activities',
      icon: Icons.sports_soccer,
      emojis: [
        '⚽',
        '🏀',
        '🏈',
        '⚾',
        '🥎',
        '🎾',
        '🏐',
        '🏉',
        '🥏',
        '🎱',
        '🪀',
        '🏓',
        '🏸',
        '🏒',
        '🏑',
        '🥍',
        '🏏',
        '🪃',
        '🥅',
        '⛳',
        '🪁',
        '🏹',
        '🎣',
        '🤿',
        '🥊',
        '🥋',
        '🎽',
        '🛹',
        '🛼',
        '🛷',
        '⛸️',
        '🥌',
      ],
    ),
    EmojiCategory(
      name: 'Food',
      icon: Icons.restaurant,
      emojis: [
        '🍎',
        '🍏',
        '🍐',
        '🍊',
        '🍋',
        '🍌',
        '🍉',
        '🍇',
        '🍓',
        '🫐',
        '🍈',
        '🍒',
        '🍑',
        '🥭',
        '🍍',
        '🥥',
        '🥝',
        '🍅',
        '🍆',
        '🥑',
        '🥦',
        '🥬',
        '🥒',
        '🌶️',
        '🫑',
        '🌽',
        '🥕',
        '🫒',
        '🧄',
        '🧅',
        '🥔',
        '🍠',
      ],
    ),
    EmojiCategory(
      name: 'Travel',
      icon: Icons.directions_car,
      emojis: [
        '🚗',
        '🚕',
        '🚙',
        '🚌',
        '🚎',
        '🏎️',
        '🚓',
        '🚑',
        '🚒',
        '🚐',
        '🛻',
        '🚚',
        '🚛',
        '🚜',
        '🏍️',
        '🛵',
        '🚲',
        '🛴',
        '🛹',
        '🛼',
        '🚁',
        '🛸',
        '✈️',
        '🛩️',
        '🛫',
        '🛬',
        '🪂',
        '💺',
        '🚀',
        '🛰️',
        '🚢',
        '⛵',
      ],
    ),
    EmojiCategory(
      name: 'Objects',
      icon: Icons.phone_android,
      emojis: [
        '📱',
        '📲',
        '💻',
        '⌨️',
        '🖥️',
        '🖨️',
        '🖱️',
        '🖲️',
        '💽',
        '💾',
        '💿',
        '📀',
        '📼',
        '📷',
        '📸',
        '📹',
        '🎥',
        '📽️',
        '🎞️',
        '📞',
        '☎️',
        '📟',
        '📠',
        '📺',
        '📻',
        '🎙️',
        '🎚️',
        '🎛️',
        '🧭',
        '⏱️',
        '⏲️',
        '⏰',
      ],
    ),
    EmojiCategory(
      name: 'Flags',
      icon: Icons.flag,
      emojis: [
        '🇵🇹', // Portugal
        '🇪🇸', // Spain
        '🇫🇷', // France
        '🇮🇹', // Italy
        '🇩🇪', // Germany
        '🇬🇧', // United Kingdom
        '🇳🇱', // Netherlands
        '🇧🇪', // Belgium
        '🇨🇭', // Switzerland
        '🇦🇹', // Austria
        '🇵🇱', // Poland
        '🇨🇿', // Czech Republic
        '🇷🇴', // Romania
        '🇬🇷', // Greece
        '🇸🇮', // Slovenia
        '🇸🇪', // Sweden
        '🇳🇴', // Norway
        '🇩🇰', // Denmark
        '🇫🇮', // Finland
        '🇮🇪', // Ireland
        '🇺🇸', // United States
        '🇨🇦', // Canada
        '🇧🇷', // Brazil
        '🇦🇷', // Argentina
        '🇲🇽', // Mexico
        '🇯🇵', // Japan
        '🇰🇷', // South Korea
        '🇨🇳', // China
        '🇮🇳', // India
        '🇦🇺', // Australia
        '🇿🇦', // South Africa
        '🇪🇬', // Egypt
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Find the category that contains the selected emoji
    int initialIndex = 0;
    if (widget.selectedEmoji != null) {
      for (int i = 0; i < _categories.length; i++) {
        if (_categories[i].emojis.contains(widget.selectedEmoji)) {
          initialIndex = i;
          break;
        }
      }
    }

    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Set initial page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate height for 8x4 grid:
    // - Grabber bar + padding: 12 + 4 = 16
    // - Header + spacing: 44 + 12 = 56
    // - Tab bar + spacing: 40 + 16 = 56
    // - Grid: 4 rows * 48px (emoji size + spacing) = 192
    // - Bottom padding: 24
    // Total: 344px (reduced to fix overflow)
    const double bottomSheetHeight = 344;

    return Container(
      width: double.infinity,
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grabber bar
          const Padding(
            padding: EdgeInsets.only(top: Gaps.sm),
            child: Center(child: GrabberBar()),
          ),

          // Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Emoji',
                  style: AppText.titleMediumEmph.copyWith(
                    color: BrandColors.text1,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close,
                    color: BrandColors.text2,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tab bar para categorias
          TabBarTheme(
            data: TabBarTheme.of(context).copyWith(
              labelPadding: const EdgeInsets.symmetric(horizontal: Gaps.xs),
              tabAlignment: TabAlignment.fill,
            ),
            child: Container(
              height: 36, // Reduced height
              margin: const EdgeInsets.symmetric(horizontal: Gaps.lg),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: BrandColors.planning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                labelColor: BrandColors.planning,
                unselectedLabelColor: BrandColors.text2,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: _categories.map((category) {
                  return Container(
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(
                      category.icon,
                      size: 16,
                      color: BrandColors.text2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Grid de emojis - use Expanded to take remaining space
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              itemCount: _categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = _categories[categoryIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: category.emojis.length > 32
                        ? 32
                        : category.emojis.length, // Limit to 4 rows (8x4=32)
                    itemBuilder: (context, emojiIndex) {
                      final emoji = category.emojis[emojiIndex];
                      final isSelected = emoji == widget.selectedEmoji;

                      return GestureDetector(
                        onTap: () {
                          widget.onEmojiSelected?.call(emoji);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? BrandColors.planning.withValues(alpha: 0.1)
                                : BrandColors.bg3,
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? Border.all(
                                    color: BrandColors.planning,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Modelo para categoria de emoji
class EmojiCategory {
  final String name;
  final IconData icon;
  final List<String> emojis;

  EmojiCategory({required this.name, required this.icon, required this.emojis});
}
