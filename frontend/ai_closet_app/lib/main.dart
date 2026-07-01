import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/clothing_api_item.dart';
import 'services/api_client.dart';
import 'services/gemini_client.dart';
import 'services/llm_settings_store.dart';

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
    required this.materials,
    required this.seasons,
    required this.occasions,
    required this.palette,
    required this.icon,
  });

  final String name;
  final String category;
  final List<String> colors;
  final List<String> tags;
  final double confidence;
  final String imageUrl;
  final List<String> materials;
  final List<String> seasons;
  final List<String> occasions;
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
        '',
    materials: ['울', '안감 있음'],
    seasons: ['가을', '겨울'],
    occasions: ['발표', '면접', '격식'],
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
        '',
    materials: ['코튼'],
    seasons: ['봄', '여름', '가을'],
    occasions: ['데일리', '발표', '레이어드'],
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
        '',
    materials: ['데님', '코튼'],
    seasons: ['사계절'],
    occasions: ['데일리', '캠퍼스', '캐주얼'],
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
        '',
    materials: ['니트', '울 블렌드'],
    seasons: ['가을', '겨울'],
    occasions: ['카페', '캠퍼스', '데일리'],
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
        '',
    materials: ['폴리', '플리츠'],
    seasons: ['봄', '가을'],
    occasions: ['발표', '모임', '데일리'],
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
        '',
    materials: ['코튼', '나일론'],
    seasons: ['봄', '가을'],
    occasions: ['산책', '여행', '캐주얼'],
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
  ClothingApiItem? _askItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Offstage + TickerMode: IndexedStack와 동일하게 State를 유지하지만
      // 각 화면이 독립적인 크기 제약을 받아 스크롤이 정상 동작합니다.
      body: SafeArea(
        child: Stack(
          children: [
            _buildTab(0, HomeScreen(
              onCapture: () => setState(() => _selectedIndex = 2),
              onAsk: () => setState(() {
                _askItem = null;
                _selectedIndex = 3;
              }),
              onAskWithItem: (item) => setState(() {
                _askItem = item;
                _selectedIndex = 3;
              }),
            )),
            _buildTab(1, ClosetScreen(
              onAskWithItem: (item) {
                print('DEBUG: ClosetShellState onAskWithItem called for tab 1');
                setState(() {
                  _askItem = item;
                  _selectedIndex = 3;
                });
              },
            )),
            _buildTab(2, AddItemScreen(
              onUploadComplete: () => setState(() => _selectedIndex = 1),
            )),
            _buildTab(3, AskClosetScreen(
              targetItem: _askItem,
              onClearTarget: () => setState(() => _askItem = null),
            )),
            _buildTab(4, const SettingsScreen()),
          ],
        ),
      ),
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

  Widget _buildTab(int index, Widget child) {
    final isActive = _selectedIndex == index;
    return Offstage(
      offstage: !isActive,
      child: TickerMode(
        enabled: isActive,
        child: child,
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onCapture, required this.onAsk, required this.onAskWithItem});

  final VoidCallback onCapture;
  final VoidCallback onAsk;
  final void Function(ClothingApiItem) onAskWithItem;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ClothingApiItem> _recentItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentItems();
  }

  Future<void> _loadRecentItems() async {
    try {
      final items = await ClosetApiClient.getClothingList(userId: 1);
      // 최신 순으로 정렬하여 최대 4개만 표시
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _recentItems = items.take(4).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                  _isLoading
                      ? '옷장 정보를 불러오는 중...'
                      : '내 옷 ${_recentItems.length}개',
                  style: textTheme.bodyMedium,
                ),
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
                    onTap: widget.onCapture,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble_outline,
                    label: '옷장에게 질문',
                    subtitle: '코디 추천받기',
                    onTap: widget.onAsk,
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
        if (_isLoading)
          const SliverPadding(
            padding: EdgeInsets.all(40),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (_recentItems.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.groupedBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.checkroom_outlined,
                        size: 48, color: AppColors.tertiaryText),
                    const SizedBox(height: 12),
                    Text('아직 옷이 없어요', style: textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('추가 탭에서 옷 사진을 업로드해보세요.',
                        style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverGrid.builder(
              itemCount: _recentItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) => ApiClothingTile(
                item: _recentItems[index],
                onAsk: widget.onAskWithItem,
              ),
            ),
          ),
      ],
    );
  }
}

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key, this.onAskWithItem});
  final void Function(ClothingApiItem)? onAskWithItem;

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  String _selectedFilter = '전체';
  List<ClothingApiItem> _apiItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await ClosetApiClient.getClothingList(userId: 1);
      if (mounted) {
        setState(() {
          _apiItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 실데이터 기반 동적 카테고리 필터 목록
  List<String> get _filters {
    final categories = _apiItems
        .map((item) => item.category)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return ['전체', ...categories];
  }

  List<ClothingApiItem> get _filteredItems {
    if (_selectedFilter == '전체') return _apiItems;
    return _apiItems.where((item) {
      return item.category == _selectedFilter ||
          item.subCategory == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('옷장', style: textTheme.displaySmall)),
                    IconButton(
                      icon: const Icon(Icons.refresh_outlined),
                      onPressed: _loadItems,
                      tooltip: '새로고침',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _FilterRow(
                  selectedFilter: _selectedFilter,
                  filters: _filters,
                  onSelected: (filter) =>
                      setState(() => _selectedFilter = filter),
                ),
                const SizedBox(height: 12),
                if (!_isLoading)
                  Text(
                    '${_filteredItems.length}개의 옷이 보여요',
                    style: textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      size: 48, color: AppColors.tertiaryText),
                  const SizedBox(height: 12),
                  Text('백엔드 연결 실패', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('localhost:8000 서버가 실행 중인지 확인하세요.',
                      style: textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadItems,
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          )
        else if (_filteredItems.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.checkroom_outlined,
                      size: 56, color: AppColors.tertiaryText),
                  const SizedBox(height: 12),
                  Text('아직 옷이 없어요', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('추가 탭에서 갤러리 이미지를 업로드해보세요.', style: textTheme.bodyMedium),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid.builder(
              itemCount: _filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) => ApiClothingTile(
                item: _filteredItems[index],
                onAsk: widget.onAskWithItem,
              ),
            ),
          ),
      ],
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.onUploadComplete});

  /// 업로드 완료 시 옷장 탭으로 이동하기 위한 콜백
  final VoidCallback? onUploadComplete;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  File? _pickedImage;
  bool _isUploading = false;
  String _statusMessage = '';

  final _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null) return;
    setState(() {
      _pickedImage = File(xfile.path);
      _statusMessage = '';
    });
  }

  Future<void> _upload() async {
    if (_pickedImage == null) return;
    setState(() {
      _isUploading = true;
      _statusMessage = '업로드 중...';
    });

    try {
      // 1. 업로드
      final taskId = await ClosetApiClient.uploadClothing(
        imageFile: _pickedImage!,
        userId: 1,
      );
      setState(() => _statusMessage = 'AI 분석 중... (최초 실행 시 1~2분 소요)');

      // 2. 폴링 (2초 간격, 최대 3분)
      const interval = Duration(seconds: 2);
      const timeout = Duration(minutes: 3);
      final deadline = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(interval);
        final status = await ClosetApiClient.getPipelineStatus(taskId);

        if (status.isDone) {
          setState(() {
            _isUploading = false;
            _statusMessage = '분류 완료!';
          });
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('옷 분류가 완료됐어요 👕  옷장에서 확인하세요!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            widget.onUploadComplete?.call();
          }
          return;
        }

        if (status.isFailed) {
          setState(() {
            _isUploading = false;
            _statusMessage = '분석 실패: ${status.error ?? "알 수 없는 오류"}';
          });
          return;
        }
      }

      // 타임아웃
      setState(() {
        _isUploading = false;
        _statusMessage = '처리 시간이 초과됐어요. 서버를 확인해주세요.';
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _statusMessage = '오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('옷 추가', style: textTheme.displaySmall),
        const SizedBox(height: 18),

        // 이미지 미리보기
        _ImagePreviewArea(pickedImage: _pickedImage),
        const SizedBox(height: 20),

        // 갤러리 버튼
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickFromGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('갤러리에서 가져오기'),
        ),
        const SizedBox(height: 12),

        // 업로드 버튼
        FilledButton.icon(
          onPressed: (_pickedImage != null && !_isUploading) ? _upload : null,
          icon: _isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(_isUploading ? 'AI 분석 중...' : 'AI로 분류하기'),
        ),

        // 상태 메시지
        if (_statusMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.groupedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_isUploading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    _statusMessage.contains('완료')
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 16,
                    color: _statusMessage.contains('완료')
                        ? AppColors.success
                        : AppColors.secondaryText,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_statusMessage, style: textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class AskClosetScreen extends StatefulWidget {
  const AskClosetScreen({super.key, this.targetItem, this.onClearTarget});
  final ClothingApiItem? targetItem;
  final VoidCallback? onClearTarget;

  @override
  State<AskClosetScreen> createState() => _AskClosetScreenState();
}

class _AskClosetScreenState extends State<AskClosetScreen> {
  final _settingsStore = LlmSettingsStore();
  final _questionController = TextEditingController();

  bool _isLoading = false;
  List<GeminiRecommendation> _recommendations = [];
  List<ClothingApiItem> _allClosetItems = [];
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askGemini() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      setState(() => _error = '질문을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _recommendations = [];
    });

    try {
      final apiKey = await _settingsStore.loadGeminiApiKey();
      if (apiKey.isEmpty) {
        throw const GeminiException('설정 탭에서 Gemini API 키를 먼저 입력해주세요.');
      }

      // 1. 날씨 정보 가져오기
      WeatherInfo? weather;
      try {
        weather = await ClosetApiClient.getWeather();
      } catch (weatherErr) {
        debugPrint('날씨 호출 실패 (Mock Fallback 동작 예정): $weatherErr');
      }

      // 2. 옷 목록 가져오기
      final allItems = await ClosetApiClient.getClothingList(userId: 1);
      _allClosetItems = allItems;
      var items = List<ClothingApiItem>.from(allItems);

      // 3. 날씨 기온 기반으로 클라이언트 사이드 옷 필터링 (부하 감소)
      if (weather != null) {
        items = _filterItemsByWeather(items, weather.temp);
        // 타겟 아이템이 필터링으로 날아갔다면 강제로 부활시킴
        if (widget.targetItem != null && !items.any((i) => i.clothId == widget.targetItem!.clothId)) {
          items.add(widget.targetItem!);
        }
      }

      // 4. Gemini에 질문 전송
      final answer = await GeminiClient(apiKey: apiKey).askCloset(
        question: question,
        closetItems: items,
        weatherInfo: weather?.summary,
        targetItem: widget.targetItem,
      );

      // 5. JSON 응답 파싱
      List<GeminiRecommendation> recommendations = [];
      try {
        // Gemini가 ```json ... ``` 으로 감싸는 경우 대비 정리
        var cleaned = answer.trim();
        if (cleaned.startsWith('```')) {
          cleaned = cleaned
              .replaceFirst(RegExp(r'^```json?\s*'), '')
              .replaceFirst(RegExp(r'```\s*$'), '')
              .trim();
        }
        final parsed = jsonDecode(cleaned);
        if (parsed is Map<String, dynamic> && parsed.containsKey('recommendations')) {
          final list = parsed['recommendations'] as List<dynamic>;
          recommendations = list
              .map((e) => GeminiRecommendation.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (parsed is Map<String, dynamic>) {
          recommendations = [GeminiRecommendation.fromJson(parsed)];
        }
      } catch (e, st) {
        debugPrint('Gemini JSON 파싱 실패: $e\n$st');
        // JSON 파싱 실패 시 일반 텍스트 응답을 폴백 추천 객체로 포장
        recommendations = [
          GeminiRecommendation(
            name: '추천 코디',
            itemIds: [],
            reason: answer,
            tip: '',
          )
        ];
      }

      if (!mounted) return;
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ClothingApiItem> _filterItemsByWeather(List<ClothingApiItem> items, double temp) {
    // 옷 개수가 적으면 필터링하지 않고 전부 보냅니다.
    if (items.length <= 12) return items;

    return items.where((item) {
      final subCategory = item.subCategory?.toLowerCase() ?? '';
      final category = item.category?.toLowerCase() ?? '';

      // 여름 날씨 (23도 이상): 아우터(코트, 무거운 패딩/재킷) 및 니트/스웨터류 제외
      if (temp >= 23.0) {
        if (subCategory.contains('코트') ||
            subCategory.contains('패딩') ||
            subCategory.contains('스웨터') ||
            category.contains('니트') ||
            (category.contains('아우터') && (subCategory.contains('코트') || subCategory.contains('재킷') && !subCategory.contains('가벼운')))) {
          return false;
        }
      }
      // 겨울 날씨 (9도 이하): 가벼운 여름 옷(반바지, 민소매) 제외
      if (temp <= 9.0) {
        if (subCategory.contains('반바지') ||
            subCategory.contains('민소매') ||
            subCategory.contains('쇼츠') ||
            subCategory.contains('나시')) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _useExample(String question) {
    _questionController.text = question;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Column(
        children: [
          // 상단: 답변 영역 (챗봇처럼 위에서부터 스크롤 가능하게 출력)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                Text('옷장에게 질문', style: textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('저장된 옷장 데이터를 기반으로 날씨와 TPO에 알맞은 코디를 제안합니다.', style: textTheme.bodyMedium),
                const SizedBox(height: 24),
                
                if (_isLoading)
                  const _AssistantStatusCard(message: 'Gemini가 옷장 데이터를 분석하여 답변을 구성하고 있어요...')
                else if (_error != null)
                  _AssistantStatusCard(message: _error!, isError: true)
                else if (_recommendations.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _recommendations
                        .map((rec) => _GeminiRecommendationCard(
                              recommendation: rec,
                              closetItems: _allClosetItems,
                            ))
                        .toList(),
                  )
                else ...[
                  // 초기 상태 화면 (기존 목 코디 1개 표시)
                  Text('추천 코디 예시', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _OutfitRecommendation(outfit: mockOutfits.first),
                ],
              ],
            ),
          ),

          // 하단: 질문 입력 및 칩 영역 (챗봇 스타일로 하단 고정)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: AppColors.separator, width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 질문 바로 위의 추천 질문 Action 칩 세트 (가로 스크롤 지원)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.work_outline, size: 16),
                        label: const Text('면접 코디'),
                        onPressed: _isLoading
                            ? null
                            : () => _useExample('내일 면접에 단정하게 입을 옷 추천해줘.'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                        label: const Text('더운 날'),
                        onPressed: _isLoading
                            ? null
                            : () => _useExample('더운 날 캠퍼스에서 입기 좋은 조합 알려줘.'),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
                        label: const Text('데이트'),
                        onPressed: _isLoading
                            ? null
                            : () => _useExample('주말 데이트에 어울리는 깔끔한 코디 추천해줘.'),
                      ),
                    ],
                  ),
                ),
                if (widget.targetItem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.groupedBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.separator, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.targetItem!.imageUrl.isNotEmpty
                                ? Image.network(
                                    ClosetApiClient.imageFullUrl(widget.targetItem!.imageUrl),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: AppColors.background,
                                    child: const Icon(Icons.checkroom),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '필수 포함 아이템',
                                  style: TextStyle(fontSize: 12, color: AppColors.tertiaryText),
                                ),
                                Text(
                                  widget.targetItem!.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: widget.onClearTarget,
                            color: AppColors.secondaryText,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                // 프롬프트 입력창
                _PromptBox(
                  controller: _questionController,
                  isLoading: _isLoading,
                  onSubmit: _askGemini,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GeminiRecommendation {
  const GeminiRecommendation({
    required this.name,
    required this.itemIds,
    required this.reason,
    required this.tip,
  });

  final String name;
  final List<int> itemIds;
  final String reason;
  final String tip;

  factory GeminiRecommendation.fromJson(Map<String, dynamic> json) {
    return GeminiRecommendation(
      name: json['name'] as String? ?? '추천 코디',
      itemIds: (json['item_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      reason: json['reason'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
    );
  }
}

class _GeminiRecommendationCard extends StatelessWidget {
  const _GeminiRecommendationCard({
    required this.recommendation,
    required this.closetItems,
  });

  final GeminiRecommendation recommendation;
  final List<ClothingApiItem> closetItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // 추천된 cloth_id와 일치하는 실제 API 아이템 필터링
    final matchedItems = closetItems
        .where((item) => recommendation.itemIds.contains(item.clothId))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
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
                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 추천된 실제 의류가 매칭된 경우 이미지 슬라이더 표시
              if (matchedItems.isNotEmpty) ...[
                SizedBox(
                  height: 152,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matchedItems.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: 112,
                      child: _ClothingApiItemTile(item: matchedItems[index]),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text('추천 이유', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(recommendation.reason, style: textTheme.bodyLarge),
              
              if (recommendation.tip.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('스타일링 팁', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(recommendation.tip, style: textTheme.bodyLarge),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ClothingApiItemTile extends StatelessWidget {
  const _ClothingApiItemTile({required this.item});

  final ClothingApiItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ClosetApiClient.imageFullUrl(item.imageUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.separator.withOpacity(0.3),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.secondaryText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.displayName,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.categoryLabel,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.secondaryText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsStore = LlmSettingsStore();
  final _apiKeyController = TextEditingController();

  bool _isLoading = true;
  bool _obscureApiKey = true;
  String _saveMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final apiKey = await _settingsStore.loadGeminiApiKey();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = apiKey;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsStore.saveGeminiApiKey(_apiKeyController.text);
    if (!mounted) return;
    setState(() => _saveMessage = 'Gemini API 키가 저장됐어요.');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Gemini API 키 저장 완료'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text('설정', style: textTheme.displaySmall),
        const SizedBox(height: 18),
        _SettingsPanel(
          icon: Icons.key_outlined,
          title: 'Gemini API 키',
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscureApiKey,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        hintText: 'AIza...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.separator),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('저장'),
                    ),
                    if (_saveMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_saveMessage,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: AppColors.success)),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 12),
        const _SettingsRow(
          icon: Icons.auto_awesome_outlined,
          title: '질문 기능',
          value: 'Gemini',
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
  const ClothingTile({super.key, required this.item, this.onTap});

  final ClothingItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: '${item.name} 상세 보기',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: _ClothingImageFallback(item: item)),
                    if (item.imageUrl.isNotEmpty)
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
        ),
      ),
    );
  }
}

/// 백엔드 API 데이터를 표시하는 옷 카드 타일
class ApiClothingTile extends StatelessWidget {
  const ApiClothingTile({super.key, required this.item, this.onAsk});

  final ClothingApiItem item;
  final void Function(ClothingApiItem)? onAsk;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = ClosetApiClient.imageFullUrl(item.imageUrl);
    final colors = item.tagValues('color');

    return Semantics(
      button: true,
      label: '${item.displayName} 상세 보기',
      child: InkWell(
        onTap: () => _openApiItemDetail(context, item, onAsk: onAsk),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 배경 플레이스홀더
                    Container(
                      color: AppColors.groupedBackground,
                      child: const Center(
                        child: Icon(Icons.checkroom_outlined,
                            size: 40, color: AppColors.tertiaryText),
                      ),
                    ),
                    // 크롭 이미지
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.groupedBackground,
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined,
                              size: 40, color: AppColors.tertiaryText),
                        ),
                      ),
                    ),
                    // 그라데이션
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
                    // Confidence 배지
                    if (item.confidenceLabel != null)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.confidenceLabel!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    // 색상 태그
                    if (colors.isNotEmpty)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            colors.first,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
              item.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(item.categoryLabel, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// 갤러리에서 선택한 이미지 미리보기 영역
class _ImagePreviewArea extends StatelessWidget {
  const _ImagePreviewArea({required this.pickedImage});

  final File? pickedImage;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: pickedImage != null
            ? Image.file(pickedImage!, fit: BoxFit.cover)
            : const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2E3138), Color(0xFF111111)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          color: Colors.white54, size: 48),
                      SizedBox(height: 12),
                      Text(
                        '갤러리에서 이미지를 선택하세요',
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ClothingDetailScreen extends StatelessWidget {
  const ClothingDetailScreen({super.key, required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primaryText,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _ClothingImageFallback(item: item),
                  if (item.imageUrl.isNotEmpty)
                    Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _ClothingImageFallback(item: item);
                      },
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.38),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DetailPill(item.category),
                            _DetailPill(
                              'AI ${(item.confidence * 100).round()}%',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                _DetailSection(
                  title: '기본 정보',
                  children: [
                    _InfoRow(label: '카테고리', value: item.category),
                    _InfoRow(label: '색상', value: item.colors.join(', ')),
                    _InfoRow(label: '소재', value: item.materials.join(', ')),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailSection(
                  title: '활용 정보',
                  children: [
                    _InfoRow(label: '계절', value: item.seasons.join(', ')),
                    _InfoRow(label: '상황', value: item.occasions.join(', ')),
                  ],
                ),
                const SizedBox(height: 20),
                Text('태그', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final tag in item.tags) TagChip(tag)],
                ),
                const SizedBox(height: 24),
                _DetailSection(
                  title: 'AI 분류 메모',
                  children: [
                    Text(
                      'Fashionpedia가 이 옷을 ${item.category}로 분류했고, 신뢰도는 ${(item.confidence * 100).round()}%예요. 실제 저장 전에는 사용자가 태그를 수정할 수 있도록 연결할 예정입니다.',
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showFeatureSnack(context, '수정 화면은 다음 단계에서 연결할게요.'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('수정'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showFeatureSnack(
                          context,
                          '이 옷을 포함한 추천 코디를 준비할게요.',
                        ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('코디 추천'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

void _openItemDetail(BuildContext context, ClothingItem item) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => ClothingDetailScreen(item: item)),
  );
}

Future<void> _openApiItemDetail(BuildContext context, ClothingApiItem item, {void Function(ClothingApiItem)? onAsk}) async {
  print('DEBUG: _openApiItemDetail called with onAsk: $onAsk');
  final result = await Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => ApiClothingDetailScreen(item: item)),
  );
  print('DEBUG: _openApiItemDetail result: $result, is ClothingApiItem: ${result is ClothingApiItem}, onAsk: $onAsk');
  if (result is ClothingApiItem && onAsk != null) {
    print('DEBUG: _openApiItemDetail calling onAsk!');
    onAsk(result);
  }
}

class ApiClothingDetailScreen extends StatefulWidget {
  const ApiClothingDetailScreen({super.key, required this.item});

  final ClothingApiItem item;

  @override
  State<ApiClothingDetailScreen> createState() =>
      _ApiClothingDetailScreenState();
}

class _ApiClothingDetailScreenState extends State<ApiClothingDetailScreen> {
  late ClothingApiItem _item;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  // ─── 삭제 ───────────────────────────────────────────────────
  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('옷 삭제'),
        content: Text('"${_item.displayName}"을(를)\n정말 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await ClosetApiClient.deleteClothing(clothId: _item.clothId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다.')),
        );
        Navigator.of(context).pop(true); // pop → true = 목록 갱신 신호
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  // ─── 수정 ───────────────────────────────────────────────────
  Future<void> _editItem() async {
    final catCtrl = TextEditingController(text: _item.category ?? '');
    final subCtrl = TextEditingController(text: _item.subCategory ?? '');
    final patCtrl = TextEditingController(text: _item.pattern ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(
                  labelText: '카테고리',
                  hintText: '예: 상의, 하의, 아우터',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subCtrl,
                decoration: const InputDecoration(
                  labelText: '세부 분류',
                  hintText: '예: 셔츠, 슬랙스, 패딩',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: patCtrl,
                decoration: const InputDecoration(
                  labelText: '패턴',
                  hintText: '예: 무지, 스트라이프, 체크',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final updated = await ClosetApiClient.updateClothing(
        clothId: _item.clothId,
        category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
        subCategory: subCtrl.text.trim().isEmpty ? null : subCtrl.text.trim(),
        pattern: patCtrl.text.trim().isEmpty ? null : patCtrl.text.trim(),
      );
      if (mounted) {
        setState(() {
          _item = updated;
          _isBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수정되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = ClosetApiClient.imageFullUrl(_item.imageUrl);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.primaryText,
            // 앱바 우측 삭제 버튼
            actions: [
              if (_isBusy)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '삭제',
                  onPressed: _deleteItem,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 배경 플레이스홀더
                  Container(
                    color: AppColors.groupedBackground,
                    child: const Center(
                      child: Icon(Icons.checkroom_outlined,
                          size: 56, color: AppColors.tertiaryText),
                    ),
                  ),
                  // 네트워크 이미지
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.groupedBackground,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 56, color: AppColors.tertiaryText),
                      ),
                    ),
                  ),
                  // 그라데이션 오버레이
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x60000000),
                        ],
                      ),
                    ),
                  ),
                  // 이름 & 카테고리 pill
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.displayName,
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DetailPill(_item.categoryLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailSection(
                    title: '기본 정보',
                    children: [
                      _InfoRow(label: '카테고리', value: _item.categoryLabel),
                      _InfoRow(
                          label: '세부 분류', value: _item.subCategory ?? '-'),
                      _InfoRow(label: '패턴', value: _item.pattern ?? '-'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DetailSection(
                    title: 'AI 분석',
                    children: [
                      _InfoRow(
                          label: 'AI 신뢰도',
                          value: _item.confidenceLabel ?? '-'),
                      _InfoRow(
                          label: '파이프라인 상태',
                          value: _item.pipelineStatus),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('태그', style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _item.tags.isEmpty
                      ? Text('태그 없음', style: textTheme.bodyMedium)
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in _item.tags)
                              TagChip('${tag.tagType}: ${tag.tagValue}'),
                          ],
                        ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy ? null : _editItem,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('수정'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isBusy
                              ? null
                              : () => Navigator.pop(context, _item),
                          icon: const Icon(Icons.auto_awesome_outlined),
                          label: const Text('코디 추천'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  const _FilterRow({
    required this.selectedFilter,
    required this.onSelected,
    required this.filters,
  });

  final String selectedFilter;
  final ValueChanged<String> onSelected;

  /// 표시할 필터 목록 (외부에서 주입, '전체' 포함)
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
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

class _PromptBox extends StatelessWidget {
  const _PromptBox({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.separator.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: isLoading ? null : (_) => onSubmit(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                hintText: '코디를 추천받아 보세요',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 36,
            height: 36,
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton.filled(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryText,
                      foregroundColor: AppColors.background,
                      shape: const CircleBorder(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AssistantStatusCard extends StatelessWidget {
  const _AssistantStatusCard({
    required this.message,
    this.isError = false,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.danger.withValues(alpha: 0.08)
            : AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isError)
            const Icon(Icons.error_outline, color: AppColors.danger)
          else
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(message, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _AssistantAnswerCard extends StatelessWidget {
  const _AssistantAnswerCard({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              const Icon(Icons.auto_awesome, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Gemini 추천', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          Text(answer, style: textTheme.bodyLarge),
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.groupedBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
