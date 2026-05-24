import 'package:flutter/material.dart';

void main() {
  runApp(const AiClosetApp());
}

class AiClosetApp extends StatelessWidget {
  const AiClosetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 옷장',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ClosetShell(),
    );
  }
}

class AppColors {
  static const ink = Color(0xFF111111);
  static const primaryText = Color(0xFF1D1D1F);
  static const secondaryText = Color(0xFF6E6E73);
  static const tertiaryText = Color(0xFF8E8E93);
  static const background = Color(0xFFFFFFFF);
  static const groupedBackground = Color(0xFFF5F5F7);
  static const elevated = Color(0xFFFFFFFF);
  static const separator = Color(0xFFE5E5EA);
  static const accent = Color(0xFF007AFF);
  static const success = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const danger = Color(0xFFFF3B30);
  static const tagBackground = Color(0xFFF2F2F7);
  static const cameraOverlay = Color(0x66000000);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          height: 41 / 34,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 34 / 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryText,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 22 / 17,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 22 / 17,
          color: AppColors.primaryText,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 20 / 15,
          color: AppColors.secondaryText,
        ),
        labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.tagBackground,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.separator),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class ClothingItem {
  const ClothingItem({
    required this.name,
    required this.category,
    required this.colors,
    required this.tags,
    required this.confidence,
    required this.imageUrl,
    required this.palette,
    required this.icon,
  });

  final String name;
  final String category;
  final List<String> colors;
  final List<String> tags;
  final double confidence;
  final String imageUrl;
  final List<Color> palette;
  final IconData icon;
}

class OutfitRecommendationData {
  const OutfitRecommendationData({
    required this.name,
    required this.itemIndexes,
    required this.reason,
  });

  final String name;
  final List<int> itemIndexes;
  final String reason;
}

const mockItems = [
  ClothingItem(
    name: '블랙 울 블레이저',
    category: '아우터',
    colors: ['블랙'],
    tags: ['포멀', '겨울', '미니멀'],
    confidence: 0.94,
    imageUrl:
        'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFF161616), Color(0xFF444247)],
    icon: Icons.checkroom_outlined,
  ),
  ClothingItem(
    name: '화이트 코튼 셔츠',
    category: '상의',
    colors: ['화이트'],
    tags: ['데일리', '깔끔함', '봄'],
    confidence: 0.91,
    imageUrl:
        'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFFECEFF3), Color(0xFFFFFFFF)],
    icon: Icons.dry_cleaning_outlined,
  ),
  ClothingItem(
    name: '인디고 스트레이트 데님',
    category: '하의',
    colors: ['블루'],
    tags: ['캐주얼', '무지', '사계절'],
    confidence: 0.88,
    imageUrl:
        'https://images.unsplash.com/photo-1542272604-787c3835535d?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFF203A5F), Color(0xFF5E7BA3)],
    icon: Icons.texture_outlined,
  ),
  ClothingItem(
    name: '토프 니트 카디건',
    category: '니트',
    colors: ['토프'],
    tags: ['따뜻함', '부드러움', '가을'],
    confidence: 0.86,
    imageUrl:
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFFA18D7B), Color(0xFFD4C2B1)],
    icon: Icons.layers_outlined,
  ),
  ClothingItem(
    name: '차콜 플리츠 스커트',
    category: '하의',
    colors: ['그레이'],
    tags: ['포멀', '플리츠', '데일리'],
    confidence: 0.9,
    imageUrl:
        'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFF4A4A4F), Color(0xFF8B8B92)],
    icon: Icons.view_agenda_outlined,
  ),
  ClothingItem(
    name: '올리브 필드 재킷',
    category: '아우터',
    colors: ['올리브'],
    tags: ['캐주얼', '봄', '유틸리티'],
    confidence: 0.84,
    imageUrl:
        'https://images.unsplash.com/photo-1551232864-3f0890e580d9?auto=format&fit=crop&w=900&q=80',
    palette: [Color(0xFF56614B), Color(0xFF87916F)],
    icon: Icons.hiking_outlined,
  ),
];

const mockOutfits = [
  OutfitRecommendationData(
    name: '발표용 단정 코디',
    itemIndexes: [0, 1, 2],
    reason: '화이트 셔츠와 블랙 블레이저의 대비가 깔끔하고, 데님이 부담을 낮춰 발표 자리에도 자연스럽게 어울려요.',
  ),
  OutfitRecommendationData(
    name: '가을 캠퍼스 코디',
    itemIndexes: [3, 2, 5],
    reason: '니트의 부드러운 질감과 필드 재킷의 캐주얼함이 잘 맞아서 오래 걸어도 편한 조합이에요.',
  ),
  OutfitRecommendationData(
    name: '포멀 데일리 코디',
    itemIndexes: [0, 1, 4],
    reason: '블레이저와 플리츠 스커트가 단정한 인상을 주고, 화이트 셔츠가 전체 톤을 밝게 잡아줘요.',
  ),
];

class ClosetShell extends StatefulWidget {
  const ClosetShell({super.key});

  @override
  State<ClosetShell> createState() => _ClosetShellState();
}

class _ClosetShellState extends State<ClosetShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onCapture: () => setState(() => _selectedIndex = 2),
        onAsk: () => setState(() => _selectedIndex = 3),
      ),
      const ClosetScreen(),
      const AddItemScreen(),
      const AskClosetScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '옷장',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_a_photo_outlined),
            selectedIcon: Icon(Icons.add_a_photo),
            label: '추가',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: '질문',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onCapture, required this.onAsk});

  final VoidCallback onCapture;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI 옷장', style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text(
                  '샘플 옷 ${mockItems.length}개 · 추천 코디 ${mockOutfits.length}개',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _TodayPanel(outfit: mockOutfits.first),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.camera_alt_outlined,
                    label: '촬영',
                    subtitle: '옷 추가하기',
                    onTap: onCapture,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: '옷장에게 질문',
                    subtitle: '코디 추천받기',
                    onTap: onAsk,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Text('최근 추가한 옷', style: textTheme.titleLarge),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          sliver: SliverGrid.builder(
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) =>
                ClothingTile(item: mockItems[index]),
          ),
        ),
      ],
    );
  }
}

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  String _selectedFilter = '전체';

  List<ClothingItem> get _filteredItems {
    if (_selectedFilter == '전체') {
      return mockItems;
    }

    return mockItems.where((item) {
      return item.category == _selectedFilter ||
          item.tags.contains(_selectedFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filteredItems = _filteredItems;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('옷장', style: textTheme.displaySmall),
                const SizedBox(height: 12),
                _FilterRow(
                  selectedFilter: _selectedFilter,
                  onSelected: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${filteredItems.length}개의 옷이 보여요',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid.builder(
            itemCount: filteredItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) =>
                ClothingTile(item: filteredItems[index]),
          ),
        ),
      ],
    );
  }
}

class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('옷 추가', style: textTheme.displaySmall),
        const SizedBox(height: 18),
        const _CameraPreviewMock(),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _showFeatureSnack(
            context,
            '카메라 화면은 다음 단계에서 실제 camera 패키지와 연결할게요.',
          ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('옷 촬영하기'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              _showFeatureSnack(context, '갤러리 선택은 다음 단계에서 이미지 피커와 연결할게요.'),
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('갤러리에서 가져오기'),
        ),
        const SizedBox(height: 28),
        Text('AI 분류 초안', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        const _ClassificationDraft(),
      ],
    );
  }
}

class AskClosetScreen extends StatelessWidget {
  const AskClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('옷장에게 질문', style: textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('저장된 옷과 상황 정보를 바탕으로 코디를 추천해요.', style: textTheme.bodyMedium),
        const SizedBox(height: 20),
        const _PromptBox(),
        const SizedBox(height: 24),
        Text('추천 코디', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        _OutfitRecommendation(outfit: mockOutfits.first),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('설정', style: textTheme.displaySmall),
        const SizedBox(height: 18),
        const _SettingsRow(
          icon: Icons.cloud_outlined,
          title: 'API 기본 주소',
          value: '목데이터 모드',
        ),
        const _SettingsRow(
          icon: Icons.tune_outlined,
          title: 'AI 분류 검토',
          value: '항상 확인',
        ),
        const _SettingsRow(
          icon: Icons.lock_outline,
          title: '옷장 개인정보',
          value: '로컬 우선',
        ),
      ],
    );
  }
}

class ClothingTile extends StatelessWidget {
  const ClothingTile({super.key, required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: _ClothingImageFallback(item: item)),
                Positioned.fill(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }

                          return _ClothingImageFallback(item: item);
                        },
                    errorBuilder: (context, error, stackTrace) {
                      return _ClothingImageFallback(item: item);
                    },
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.18),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${(item.confidence * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 2),
        Text(item.category, style: textTheme.bodyMedium),
      ],
    );
  }
}

class _ClothingImageFallback extends StatelessWidget {
  const _ClothingImageFallback({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final iconColor = item.palette.first.computeLuminance() > 0.5
        ? AppColors.primaryText
        : Colors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.palette,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: TextilePainter(item.palette)),
          ),
          Center(child: Icon(item.icon, size: 46, color: iconColor)),
        ],
      ),
    );
  }
}

class TextilePainter extends CustomPainter {
  const TextilePainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }

    paint.color = Colors.black.withValues(alpha: 0.08);
    for (double y = 12; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant TextilePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color ?? AppColors.tagBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class _TodayPanel extends StatelessWidget {
  const _TodayPanel({required this.outfit});

  final OutfitRecommendationData outfit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  outfit.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(outfit.reason, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [TagChip('포멀'), TagChip('편안함'), TagChip('23°C')],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.groupedBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selectedFilter, required this.onSelected});

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = ['전체', '아우터', '상의', '하의', '니트', '겨울', '포멀'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _FilterChipButton(
              label: filter,
              selected: selectedFilter == filter,
              onTap: () => onSelected(filter),
            ),
            if (filter != filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? const Color(0xFFE8F1FF) : AppColors.tagBackground,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(Icons.check, size: 15, color: AppColors.accent),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraPreviewMock extends StatelessWidget {
  const _CameraPreviewMock();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2E3138), Color(0xFF111111)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: TextilePainter(const [
                    Color(0xFF2E3138),
                    Color(0xFF111111),
                  ]),
                ),
              ),
              Center(
                child: Container(
                  width: 190,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      color: Colors.white,
                      size: 72,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  '가이드 안에 옷 한 벌만 맞춰주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassificationDraft extends StatelessWidget {
  const _ClassificationDraft();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.accent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fashionpedia 분류 결과',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              TagChip('88%'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              TagChip('셔츠'),
              TagChip('화이트'),
              TagChip('코튼'),
              TagChip('무지'),
              TagChip('데일리'),
              TagChip('봄'),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showTagReviewSheet(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('태그 검토하고 수정하기'),
          ),
        ],
      ),
    );
  }
}

class _PromptBox extends StatelessWidget {
  const _PromptBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.separator),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.search_outlined, color: AppColors.secondaryText),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '내일 발표 때 입을 옷 추천해줘',
              style: TextStyle(fontSize: 17, color: AppColors.primaryText),
            ),
          ),
          Icon(Icons.mic_none_outlined, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}

class _OutfitRecommendation extends StatelessWidget {
  const _OutfitRecommendation({required this.outfit});

  final OutfitRecommendationData outfit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: outfit.itemIndexes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: 112,
                child: ClothingTile(item: mockItems[outfit.itemIndexes[index]]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(outfit.reason, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _showFeatureSnack(
                    context,
                    '상의를 토프 니트 카디건으로 바꾼 대안을 준비했어요.',
                  ),
                  icon: const Icon(Icons.swap_horiz_outlined),
                  label: const Text('바꾸기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _showFeatureSnack(context, '추천 코디를 임시 저장했어요.'),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('저장'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showFeatureSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
}

void _showTagReviewSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('태그 검토', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '지금은 더미 데이터라 저장은 하지 않고, 나중에 FastAPI 저장 요청으로 연결할 자리예요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                TagChip('셔츠'),
                TagChip('화이트'),
                TagChip('코튼'),
                TagChip('무지'),
                TagChip('데일리'),
                TagChip('봄'),
                TagChip('+ 태그 추가'),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFeatureSnack(context, '태그 수정 흐름을 확인했어요.');
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    },
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
