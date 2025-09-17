import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/grabber_bar.dart';

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
    // - Header + spacing: 50 + 12 = 62
    // - Tab bar + spacing: 48 + 16 = 64
    // - Grid: 4 rows * 48px (emoji size + spacing) = 192
    // - Bottom padding: 16
    // Total: 350px
    const double bottomSheetHeight = 350;

    return Container(
      width: double.infinity,
      height: bottomSheetHeight,
      decoration: BoxDecoration(
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
          Padding(
            padding: EdgeInsets.only(top: Gaps.sm),
            child: Center(child: GrabberBar()),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Gaps.lg),
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
                  icon: Icon(Icons.close, color: BrandColors.text2),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Tab bar para categorias
          TabBarTheme(
            data: TabBarTheme.of(context).copyWith(
              labelPadding: EdgeInsets.symmetric(horizontal: Gaps.xs),
              tabAlignment: TabAlignment.fill,
            ),
            child: Container(
              height: 40, // Altura fixa menor
              margin: EdgeInsets.symmetric(horizontal: Gaps.lg),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                indicator: BoxDecoration(
                  color: BrandColors.planning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                labelColor: BrandColors.planning,
                unselectedLabelColor: BrandColors.text2,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab, // Mudança aqui
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                tabs: _categories.map((category) {
                  return Container(
                    height: 40, // Altura específica para cada tab
                    alignment: Alignment.center,
                    child: Icon(
                      category.icon,
                      size: 18,
                      color: BrandColors.text2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Grid de emojis
          SizedBox(
            height: 192,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                _tabController.animateTo(index);
              },
              itemCount: _categories.length,
              itemBuilder: (context, categoryIndex) {
                final category = _categories[categoryIndex];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: Gaps.lg),
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
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
                                ? BrandColors.planning.withOpacity(0.1)
                                : BrandColors.bg3,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: BrandColors.planning,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: Text(emoji, style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
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
