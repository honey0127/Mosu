import 'package:flutter/material.dart';
import 'package:animal_crossing_ui/animal_crossing_ui.dart';
import 'package:avatar_maker/avatar_maker.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../models/wardrobe_item.dart';
import '../../models/deco_item.dart';

// ── 팔레트 ────────────────────────────────────────────────────────────────────
const _primary  = Color(0xFF7DB879);
const _primary2 = Color(0xFF5A9A4A);
const _bgPage   = Color(0xFFF2F2F0);
const _bgCard   = Color(0xFFFFFFFF);
const _bgSoft   = Color(0xFFE8F3E3);
const _textMain = Color(0xFF1A1A1A);
const _textSub  = Color(0xFF8E8E93);
const _border   = Color(0xFFDDDDDD);

// 기본 방 색상
const _wallDefault  = Color(0xFFF5EFE4);
const _floorDefault = Color(0xFFDFCDB3);

// ── 방 테마 ─────────────────────────────────────────────────────────────────
class RoomTheme {
  final String id;
  final String name;
  final String emoji;
  final Color wall;       // 벽
  final Color floor;      // 바닥
  final Color frame;      // 창문/문/책상 테두리
  final Color glass;      // 창문 유리
  final Color door;       // 문 본체
  final Color doorPanel;  // 문 패널 라인
  final Color deskTop;    // 책상 상판
  final Color deskLeg;    // 책상 다리
  final Color knob;       // 문 손잡이
  const RoomTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.wall,
    required this.floor,
    required this.frame,
    required this.glass,
    required this.door,
    required this.doorPanel,
    required this.deskTop,
    required this.deskLeg,
    required this.knob,
  });
}

const roomThemes = <RoomTheme>[
  RoomTheme(
    id: 'basic', name: '기본', emoji: '🏠',
    wall: Color(0xFFF5EFE4), floor: Color(0xFFDFCDB3),
    frame: Color(0xFF8B7355), glass: Color(0xFFB8DDEF),
    door: Color(0xFFB58B5E), doorPanel: Color(0xFF7A5A38),
    deskTop: Color(0xFFC9A878), deskLeg: Color(0xFF8B7355),
    knob: Color(0xFFFFD54F),
  ),
  RoomTheme(
    id: 'princess', name: '공주', emoji: '👑',
    wall: Color(0xFFFBE4EF), floor: Color(0xFFF6CBDD),
    frame: Color(0xFFD976A4), glass: Color(0xFFFFF0F6),
    door: Color(0xFFF4A9C8), doorPanel: Color(0xFFD976A4),
    deskTop: Color(0xFFF8C8DC), deskLeg: Color(0xFFD976A4),
    knob: Color(0xFFFFD54F),
  ),
  RoomTheme(
    id: 'modern', name: '모던', emoji: '🖤',
    wall: Color(0xFFF7F7F7), floor: Color(0xFFD9D9D9),
    frame: Color(0xFF1A1A1A), glass: Color(0xFFCDD8DE),
    door: Color(0xFF2B2B2B), doorPanel: Color(0xFF5A5A5A),
    deskTop: Color(0xFF222222), deskLeg: Color(0xFF111111),
    knob: Color(0xFFBDBDBD),
  ),
  RoomTheme(
    id: 'forest', name: '자연', emoji: '🌿',
    wall: Color(0xFFE8F3E3), floor: Color(0xFFCBB995),
    frame: Color(0xFF5A9A4A), glass: Color(0xFFC9EFD0),
    door: Color(0xFF6FA86A), doorPanel: Color(0xFF4C7C46),
    deskTop: Color(0xFFA7C8B5), deskLeg: Color(0xFF5A9A4A),
    knob: Color(0xFF8B5E3C),
  ),
];

RoomTheme roomThemeById(String id) =>
    roomThemes.firstWhere((t) => t.id == id, orElse: () => roomThemes.first);

// ══════════════════════════════════════════════════════════════════════════════
class CharacterRoomScreen extends StatefulWidget {
  const CharacterRoomScreen({super.key});

  @override
  State<CharacterRoomScreen> createState() => _CharacterRoomScreenState();
}

class _CharacterRoomScreenState extends State<CharacterRoomScreen> {
  int _tabIndex = 0;

  // 하나의 controller를 Avatar와 Customizer가 공유해야 실시간으로 연동됨
  late final AvatarMakerController _avatarController;

  @override
  void initState() {
    super.initState();
    // PersistentAvatarMakerController: 변경사항을 SharedPreferences에 자동 저장
    _avatarController = PersistentAvatarMakerController();
  }

  @override
  Widget build(BuildContext context) {
    return ACUITheme(
      data: ACUIThemePresets.celeste(),
      child: Builder(builder: _buildBody),
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = AppState.i;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            const _ACHeader(),

            // 미니 캐릭터/방 상태 스트립
            _MiniPreviewStrip(state: state, avatarController: _avatarController),
            const SizedBox(height: 6),

            // 탭 바 (캐릭터, 방)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ACTabBar(
                index: _tabIndex,
                tabs: const ['캐릭터', '방'],
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: 4),

            // 탭 콘텐츠
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _CharacterEditTab(avatarController: _avatarController),
                  _RoomEditTab(onUpdate: () => setState(() {}), avatarController: _avatarController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                            공유 헬퍼
// ══════════════════════════════════════════════════════════════════════════════
WardrobeItem? _findItem(String? id) {
  if (id == null) return null;
  for (final it in allWardrobeItems) {
    if (it.id == id) return it;
  }
  return null;
}

/// Wardrobe + AI 아이템 통합 이모지 조회
String? _slotEmoji(String? id) {
  if (id == null) return null;
  final w = _findItem(id);
  if (w != null) return w.emoji;
  return AppState.i.aiDecoItems.where((it) => it.id == id).firstOrNull?.emoji;
}

/// Wardrobe + AI 아이템 통합 색상 조회 (AI 아이템은 기본 색상)
Color _slotColor(String? id, {bool isWall = false}) {
  final w = _findItem(id);
  if (w != null) return _categoryColor(w.category);
  final hasAi = id != null &&
      AppState.i.aiDecoItems.any((it) => it.id == id);
  if (hasAi) return const Color(0xFFB8D4A8); // AI 기본 색
  return isWall ? _wallDefault : _floorDefault;
}

// 카테고리별 소프트 색상
Color _categoryColor(ExperienceCategory cat) {
  switch (cat) {
    case ExperienceCategory.cooking:    return const Color(0xFFF5EAD2);
    case ExperienceCategory.exercise:   return const Color(0xFF6FA3D8);
    case ExperienceCategory.travel:     return const Color(0xFFC9A878);
    case ExperienceCategory.social:     return const Color(0xFFE08FA1);
    case ExperienceCategory.creative:   return const Color(0xFFD68C5D);
    case ExperienceCategory.reading:    return const Color(0xFFB89BD0);
    case ExperienceCategory.meditation: return const Color(0xFFD4C9E2);
    case ExperienceCategory.hobby:      return const Color(0xFFA7C8B5);
    case ExperienceCategory.music:      return const Color(0xFF8A7FB9);
    case ExperienceCategory.nature:     return const Color(0xFFA0C57F);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                              헤더
// ══════════════════════════════════════════════════════════════════════════════
class _ACHeader extends StatelessWidget {
  const _ACHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('내 공간',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textMain)),
              SizedBox(height: 2),
              Text('밖에서 어떤 사람인지 · 내면이 어떤지',
                  style: TextStyle(fontSize: 11, color: _textSub)),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                   AC 스타일 2D 방 씬 — 벽/바닥 분리
// ══════════════════════════════════════════════════════════════════════════════
class _RoomScene extends StatelessWidget {
  final AppState state;
  final AvatarMakerController avatarController;
  const _RoomScene({required this.state, required this.avatarController});

  @override
  Widget build(BuildContext context) {
    final wall   = _findItem(state.roomEquipped['wall']);
    final desk   = _findItem(state.roomEquipped['desk']);
    final floor  = _findItem(state.roomEquipped['floor']);
    final window = _findItem(state.roomEquipped['window']);

    // 장착 아이템 카테고리로 방 색상 결정
    final wallColor = wall != null
        ? _categoryColor(wall.category)
        : _wallDefault;
    final floorColor = floor != null
        ? _categoryColor(floor.category).withOpacity(0.85)
        : _floorDefault;

    // 씬 전체 높이 (아바타 195px 기준으로 넉넉하게)
    const sceneH = 252.0;
    const wallH  = 150.0;  // 벽 영역 높이
    const floorH = sceneH - wallH; // 바닥 영역 높이

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: sceneH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── 벽 영역 ──────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: wallH,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      wallColor.withOpacity(0.55),
                      wallColor.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── 바닥 영역 ─────────────────────────────────────────────
            Positioned(
              top: wallH, left: 0, right: 0,
              height: floorH + 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      floorColor,
                      Color.lerp(floorColor, Colors.brown.shade300, 0.25)!,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── 벽/바닥 경계선 (원근감) ────────────────────────────────
            Positioned(
              top: wallH - 1.5,
              left: 0, right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── 천장 그림자 ───────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              height: 18,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.07),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── 걸레받이 ──────────────────────────────────────────────
            Positioned(
              top: wallH - 8,
              left: 0, right: 0,
              child: Container(
                height: 10,
                color: wallColor.withOpacity(0.6),
              ),
            ),

            // ── 창문 (오른쪽 벽) ──────────────────────────────────────
            Positioned(
              top: 14,
              right: 20,
              child: _WindowFrame(item: window),
            ),

            // ── 벽 장식 (왼쪽 벽) ─────────────────────────────────────
            Positioned(
              top: 12,
              left: 18,
              child: wall != null
                  ? _WallDecor(item: wall)
                  : _EmptySlotPill(label: '벽'),
            ),

            // ── 책상/가구 (바닥 왼쪽) ─────────────────────────────────
            Positioned(
              left: 14,
              bottom: 6,
              child: desk != null
                  ? _FloorFurniture(item: desk, size: 46)
                  : _EmptySlotPill(label: '책상'),
            ),

            // ── 바닥 소품 (바닥 오른쪽) ───────────────────────────────
            Positioned(
              right: 14,
              bottom: 6,
              child: floor != null
                  ? _FloorFurniture(item: floor, size: 38)
                  : _EmptySlotPill(label: '바닥'),
            ),

            // ── 캐릭터 (바닥 중앙) — AvatarMaker SVG 캐릭터 ──────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 180,
                  child: AvatarMakerAvatar(controller: avatarController),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//               창문 프레임 위젯
// ══════════════════════════════════════════════════════════════════════════════
class _WindowFrame extends StatelessWidget {
  final WardrobeItem? item;
  const _WindowFrame({this.item});

  @override
  Widget build(BuildContext context) {
    // 창문 배경: 아이템 없으면 낮 하늘, 있으면 아이템 색상
    final bgColor = item != null
        ? _categoryColor(item!.category).withOpacity(0.5)
        : const Color(0xFFB8DDEF);

    return Container(
      width: 68,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF8B7355), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 창문 십자 구분선
          Center(
            child: Container(
              height: 2,
              color: const Color(0xFF8B7355).withOpacity(0.7),
            ),
          ),
          Center(
            child: Container(
              width: 2,
              color: const Color(0xFF8B7355).withOpacity(0.7),
            ),
          ),
          // 아이템 이모지 (있으면)
          if (item != null)
            Center(
              child: Text(item!.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
          // 없으면 기본 하늘 뷰
          if (item == null)
            const Center(
              child: Text('☁️', style: TextStyle(fontSize: 18)),
            ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//               벽 장식 위젯 (액자 스타일)
// ══════════════════════════════════════════════════════════════════════════════
class _WallDecor extends StatelessWidget {
  final WardrobeItem item;
  const _WallDecor({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF8B7355), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 26)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//               바닥 가구 위젯 (그림자 포함)
// ══════════════════════════════════════════════════════════════════════════════
class _FloorFurniture extends StatelessWidget {
  final WardrobeItem item;
  final double size;
  const _FloorFurniture({required this.item, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.emoji, style: TextStyle(fontSize: size)),
        Container(
          width: size * 0.9,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.10),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
//               진행도
// ══════════════════════════════════════════════════════════════════════════════
class _ProgressRow extends StatelessWidget {
  final AppState state;
  const _ProgressRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _ProgressItem(
                emoji: '🙂', label: '캐릭터', ratio: state.characterFillRatio)),
        const SizedBox(width: 10),
        Expanded(
            child: _ProgressItem(
                emoji: '🏠', label: '방', ratio: state.roomFillRatio)),
      ],
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String emoji;
  final String label;
  final double ratio;
  const _ProgressItem(
      {required this.emoji, required this.label, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textMain)),
            const Spacer(),
            Text('${(ratio * 100).round()}%',
                style: const TextStyle(fontSize: 10, color: _textSub)),
          ],
        ),
        const SizedBox(height: 5),
        ACUILinearProgress(value: ratio),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//               탭 바
// ══════════════════════════════════════════════════════════════════════════════
class _ACTabBar extends StatelessWidget {
  final int index;
  final List<String> tabs;
  final ValueChanged<int> onChanged;
  const _ACTabBar(
      {required this.index, required this.tabs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ACUICard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: index == i ? _primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: index == i ? Colors.white : _textSub,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//   캐릭터 편집 탭 — AvatarMakerCustomizer (avatar_maker 패키지)
//   헤어, 피부, 눈, 입, 옷, 소품 등 전문적인 커스터마이저 제공
// ══════════════════════════════════════════════════════════════════════════════
// ══════════════════════════════════════════════════════════════════════════════
//  캐릭터 편집 탭 — 아바타(AvatarMaker) + 코디(경험 획득 아이템)
// ══════════════════════════════════════════════════════════════════════════════
class _CharacterEditTab extends StatefulWidget {
  final AvatarMakerController avatarController;
  const _CharacterEditTab({required this.avatarController});

  @override
  State<_CharacterEditTab> createState() => _CharacterEditTabState();
}

class _CharacterEditTabState extends State<_CharacterEditTab> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 편집 패널(커스터마이저) 높이를 제한 → 위쪽 아바타를 크게 노출
        final customizerH =
            (constraints.maxHeight * 0.5).clamp(280.0, 460.0);
        return Column(
          children: [
            const SizedBox(height: 10),
            // ── 큰 아바타 미리보기 (제페토 스타일) ──────────────
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                decoration: BoxDecoration(
                  color: _bgSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AvatarMakerAvatar(
                      controller: widget.avatarController),
                ),
              ),
            ),
            // ── 안내 + 저장 ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
              child: Row(
                children: [
                  const Expanded(
                      child: Text('헤어·피부·눈·표정을 자유롭게 바꿔보세요',
                          style: TextStyle(
                              fontSize: 12, color: _textSub))),
                  AvatarMakerSaveWidget(
                      controller: widget.avatarController),
                ],
              ),
            ),
            // ── 컴팩트 커스터마이저 (고정 높이) ─────────────────
            SizedBox(
              height: customizerH,
              child: AvatarMakerCustomizer(
                controller: widget.avatarController,
                autosave: true,
                scaffoldHeight: customizerH,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  방 편집 탭 — 미니 룸 미리보기 + 슬롯 탭 + 아이템 그리드
// ══════════════════════════════════════════════════════════════════════════════
class _RoomEditTab extends StatefulWidget {
  final VoidCallback onUpdate;
  final AvatarMakerController avatarController;
  const _RoomEditTab({required this.onUpdate, required this.avatarController});

  @override
  State<_RoomEditTab> createState() => _RoomEditTabState();
}

class _RoomEditTabState extends State<_RoomEditTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 인터랙티브 방 캔버스
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _InteractiveRoomCanvas(
                avatarController: widget.avatarController,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
        // 소품 팔레트
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text('방 구조',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSub)),
              ),
              _FixtureToggleRow(onChanged: () => setState(() {})),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text('소품 추가하기',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSub)),
              ),
              _RoomItemPalette(onChanged: () => setState(() {})),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text('방 테마 선택',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSub)),
              ),
              _ThemePickerRow(onChanged: () => setState(() {})),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  방 테마 선택 — 공주/모던/자연 등
// ══════════════════════════════════════════════════════════════════════════════
class _ThemePickerRow extends StatelessWidget {
  final VoidCallback onChanged;
  const _ThemePickerRow({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: roomThemes.length,
        itemBuilder: (_, i) {
          final t = roomThemes[i];
          final selected = state.roomThemeId == t.id;
          return GestureDetector(
            onTap: () {
              state.roomThemeId = t.id;
              onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 10),
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _bgSoft : _bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected ? _primary : _border,
                    width: selected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 벽/바닥 색상 미리보기
                  Container(
                    width: 34, height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: t.frame, width: 1.5),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [t.wall, t.floor],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${t.emoji} ${t.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _primary2 : _textSub)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── 방 미니 미리보기 카드 ───────────────────────────────────────────────────
class _RoomPreviewCard extends StatelessWidget {
  final AppState state;
  final AvatarMakerController avatarController;
  const _RoomPreviewCard({required this.state, required this.avatarController});

  @override
  Widget build(BuildContext context) {
    final wallEmoji   = _slotEmoji(state.roomEquipped['wall']);
    final deskEmoji   = _slotEmoji(state.roomEquipped['desk']);
    final floorEmoji  = _slotEmoji(state.roomEquipped['floor']);
    final windowEmoji = _slotEmoji(state.roomEquipped['window']);

    final wallColor  = _slotColor(state.roomEquipped['wall'], isWall: true);
    final floorColor = _slotColor(state.roomEquipped['floor']).withOpacity(0.85);

    return ACUICard(
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // 벽
              Positioned(
                top: 0, left: 0, right: 0, height: 72,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [wallColor.withOpacity(0.5), wallColor.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // 바닥
              Positioned(
                bottom: 0, left: 0, right: 0, height: 52,
                child: Container(color: floorColor),
              ),
              // 경계선
              Positioned(
                top: 69, left: 0, right: 0,
                child: Container(
                    height: 2,
                    color: Colors.black.withOpacity(0.08)),
              ),
              // 창문
              Positioned(
                top: 8, right: 14,
                child: Container(
                  width: 38, height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8DDEF),
                    border: Border.all(color: const Color(0xFF8B7355), width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: windowEmoji != null
                      ? Center(child: Text(windowEmoji,
                          style: const TextStyle(fontSize: 14)))
                      : const Center(child: Text('☁️',
                          style: TextStyle(fontSize: 12))),
                ),
              ),
              // 벽 장식
              if (wallEmoji != null)
                Positioned(
                  top: 6, left: 14,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      border: Border.all(
                          color: const Color(0xFF8B7355), width: 1.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text(wallEmoji,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              // 책상
              if (deskEmoji != null)
                Positioned(
                  bottom: 6, left: 14,
                  child: Text(deskEmoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              // 바닥 소품
              if (floorEmoji != null)
                Positioned(
                  bottom: 6, right: 14,
                  child: Text(floorEmoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              // 캐릭터 아바타 (바닥 중앙)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Center(
                  child: SizedBox(
                    width: 56, height: 70,
                    child: AvatarMakerAvatar(controller: avatarController),
                  ),
                ),
              ),
              // 현재 채워진 슬롯 수
              Positioned(
                top: 8, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '방 꾸미기 ${state.roomEquipped.values.where((v) => v != null).length}/4',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _primary2),
                    ),
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

// ══════════════════════════════════════════════════════════════════════════════
//              슬롯 섹션
// ══════════════════════════════════════════════════════════════════════════════
class _SlotSection extends StatelessWidget {
  final String slotLabel;
  final String? equippedId;
  final List<WardrobeItem> items;
  final void Function(String id) onTap;

  const _SlotSection({
    required this.slotLabel,
    required this.equippedId,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(slotLabel,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textMain)),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _bgSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${items.length}개',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primary)),
            ),
            if (equippedId != null) ...[
              const Spacer(),
              const Text('탭하면 해제',
                  style: TextStyle(fontSize: 10, color: _textSub)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 94,
          child: items.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bgPage,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    '아직 잠금 해제된 아이템이 없어요\n경험을 완료하면 아이템이 해금돼요',
                    style: TextStyle(fontSize: 11, color: _textSub),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final isEquipped = equippedId == it.id;
                    return GestureDetector(
                      onTap: () => onTap(it.id),
                      child: _ItemCell(item: it, isSelected: isEquipped),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//              아이템 셀
// ══════════════════════════════════════════════════════════════════════════════
class _ItemCell extends StatelessWidget {
  final WardrobeItem item;
  final bool isSelected;
  const _ItemCell({required this.item, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? _bgSoft : _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _primary : _border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 4),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? _primary : _textMain,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  미니 캐릭터/방 상태 스트립
// ══════════════════════════════════════════════════════════════════════════════
class _MiniPreviewStrip extends StatelessWidget {
  final AppState state;
  final AvatarMakerController avatarController;
  const _MiniPreviewStrip({required this.state, required this.avatarController});

  @override
  Widget build(BuildContext context) {
    final animal = state.selectedAnimal;
    return Container(
      height: 64,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48, height: 48,
            child: AvatarMakerAvatar(controller: avatarController),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(animal?.name ?? '내 캐릭터',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Lv.${state.level}',
                    style: const TextStyle(fontSize: 11, color: _textSub)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('✨', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('아이템 ${state.aiDecoItems.length}개',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5E35B1))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  빈 슬롯 필
// ══════════════════════════════════════════════════════════════════════════════
class _EmptySlotPill extends StatelessWidget {
  final String label;
  const _EmptySlotPill({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: _textSub)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  인터랙티브 방 캔버스 — 드래그로 소품 배치
// ══════════════════════════════════════════════════════════════════════════════
class _InteractiveRoomCanvas extends StatefulWidget {
  final AvatarMakerController avatarController;
  final VoidCallback onChanged;
  const _InteractiveRoomCanvas({required this.avatarController, required this.onChanged});

  @override
  State<_InteractiveRoomCanvas> createState() => _InteractiveRoomCanvasState();
}

class _InteractiveRoomCanvasState extends State<_InteractiveRoomCanvas> {
  String? _selectedId;

  void _changeScale(String id, double delta) {
    final state = AppState.i;
    final cur = state.roomItemScales[id] ?? 1.0;
    state.updateRoomItemScale(id, (cur + delta).clamp(0.5, 3.0));
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final theme = roomThemeById(state.roomThemeId);
    final placed = state.placedRoomItemIds
        .map((id) => state.aiDecoItems.where((it) => it.id == id).firstOrNull)
        .whereType<DecoItem>()
        .toList();

    // 선택된 아이템이 더 이상 배치돼 있지 않으면 선택 해제
    if (_selectedId != null && !state.placedRoomItemIds.contains(_selectedId)) {
      _selectedId = null;
    }
    final selectedItem =
        placed.where((it) => it.id == _selectedId).firstOrNull;

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Container(
        decoration: BoxDecoration(color: theme.wall),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 빈 공간 탭 → 선택 해제
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _selectedId = null),
              ),
            ),
            // 바닥
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: h * 0.40,
              child: Container(color: theme.floor),
            ),
            // 바닥/벽 경계선
            Positioned(
              bottom: h * 0.40, left: 0, right: 0,
              child: Container(height: 2, color: Colors.black12),
            ),

            // ── 고정 요소(문/창문/책상) — 캐릭터 뒤에 배치 ─────────────
            // 문 (왼쪽 벽, 바닥에 닿게)
            if (state.roomFixtures.contains('door'))
              Positioned(
                left: w * 0.05,
                bottom: h * 0.40 - 2,
                child: _DoorFixture(width: w * 0.16, height: h * 0.42, theme: theme),
              ),
            // 창문 (오른쪽 벽 상단)
            if (state.roomFixtures.contains('window'))
              Positioned(
                top: h * 0.10,
                right: w * 0.08,
                child: _WindowFixture(width: w * 0.26, height: h * 0.26, theme: theme),
              ),
            // 책상 (오른쪽 바닥)
            if (state.roomFixtures.contains('desk'))
              Positioned(
                right: w * 0.07,
                bottom: h * 0.06,
                child: _DeskFixture(width: w * 0.30, height: h * 0.22, theme: theme),
              ),

            // 캐릭터 (바닥 중앙) — 중간 크기
            Positioned(
              bottom: h * 0.30,
              left: 0, right: 0,
              child: Center(
                child: SizedBox(
                  width: 88, height: 118,
                  child: AvatarMakerAvatar(controller: widget.avatarController),
                ),
              ),
            ),
            // 배치된 소품들 (드래그 가능)
            for (final item in placed)
              _DraggableRoomItem(
                key: ValueKey(item.id),
                item: item,
                canvasWidth: w,
                canvasHeight: h,
                isSelected: _selectedId == item.id,
                position: state.roomItemPositions[item.id] ?? const Offset(0.15, 0.3),
                scale: state.roomItemScales[item.id] ?? 1.0,
                onSelect: () => setState(() => _selectedId = item.id),
                onMoved: (pos) {
                  state.moveRoomItem(item.id, pos);
                  widget.onChanged();
                },
                onScaleUpdate: (s) {
                  state.updateRoomItemScale(item.id, s);
                  widget.onChanged();
                },
                onRemove: () {
                  state.removeRoomItem(item.id);
                  setState(() => _selectedId = null);
                  widget.onChanged();
                },
              ),

            // ── 선택된 소품 크기 조절 바 ──────────────────────────────
            if (selectedItem != null)
              Positioned(
                bottom: 8, left: 0, right: 0,
                child: Center(
                  child: _ItemSizeBar(
                    name: selectedItem.name,
                    scale: state.roomItemScales[selectedItem.id] ?? 1.0,
                    onDecrease: () => _changeScale(selectedItem.id, -0.2),
                    onIncrease: () => _changeScale(selectedItem.id, 0.2),
                    onRemove: () {
                      state.removeRoomItem(selectedItem.id);
                      setState(() => _selectedId = null);
                      widget.onChanged();
                    },
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  선택된 소품 크기 조절 바
// ══════════════════════════════════════════════════════════════════════════════
class _ItemSizeBar extends StatelessWidget {
  final String name;
  final double scale;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  const _ItemSizeBar({
    required this.name,
    required this.scale,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _textMain)),
          ),
          const SizedBox(width: 8),
          _CircleBtn(icon: Icons.remove, onTap: onDecrease),
          SizedBox(
            width: 42,
            child: Text('${(scale * 100).round()}%',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _primary2)),
          ),
          _CircleBtn(icon: Icons.add, onTap: onIncrease),
          const SizedBox(width: 6),
          Container(width: 1, height: 18, color: _border),
          const SizedBox(width: 6),
          _CircleBtn(icon: Icons.delete_outline, onTap: onRemove, danger: true),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _CircleBtn({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFCE4E4) : _bgSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            size: 18, color: danger ? const Color(0xFFD9534F) : _primary2),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  드래그 가능한 소품 아이템
// ══════════════════════════════════════════════════════════════════════════════
class _DraggableRoomItem extends StatefulWidget {
  final DecoItem item;
  final double canvasWidth;
  final double canvasHeight;
  final Offset position;
  final double scale;
  final bool isSelected;
  final VoidCallback onSelect;
  final void Function(Offset) onMoved;
  final void Function(double) onScaleUpdate;
  final VoidCallback onRemove;

  const _DraggableRoomItem({
    super.key,
    required this.item,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.position,
    required this.scale,
    required this.isSelected,
    required this.onSelect,
    required this.onMoved,
    required this.onScaleUpdate,
    required this.onRemove,
  });

  @override
  State<_DraggableRoomItem> createState() => _DraggableRoomItemState();
}

class _DraggableRoomItemState extends State<_DraggableRoomItem> {
  late Offset _pos;
  late double _scale;
  bool _dragging = false;
  double _baseScale = 1.0;

  @override
  void initState() {
    super.initState();
    _pos = widget.position;
    _scale = widget.scale;
  }

  @override
  void didUpdateWidget(_DraggableRoomItem old) {
    super.didUpdateWidget(old);
    if (!_dragging) {
      _pos = widget.position;
      _scale = widget.scale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = 54.0;
    final itemSize = baseSize * _scale;
    
    final x = (_pos.dx * widget.canvasWidth).clamp(0.0, widget.canvasWidth - itemSize);
    final y = (_pos.dy * widget.canvasHeight).clamp(0.0, widget.canvasHeight - itemSize);

    final highlight = _dragging || widget.isSelected;

    return Positioned(
      left: x, top: y,
      child: GestureDetector(
        onTap: widget.onSelect,
        onScaleStart: (details) {
          widget.onSelect();
          setState(() {
            _dragging = true;
            _baseScale = _scale;
          });
        },
        onScaleUpdate: (details) {
          setState(() {
            // 위치 업데이트 (드래그)
            if (details.pointerCount == 1) {
              final nx = (_pos.dx + details.focalPointDelta.dx / widget.canvasWidth).clamp(0.0, 1.0);
              final ny = (_pos.dy + details.focalPointDelta.dy / widget.canvasHeight).clamp(0.0, 1.0);
              _pos = Offset(nx, ny);
            } 
            // 크기 업데이트 (핀치 줌)
            if (details.pointerCount == 2) {
              _scale = (_baseScale * details.scale).clamp(0.5, 3.0);
            }
          });
        },
        onScaleEnd: (_) {
          setState(() => _dragging = false);
          widget.onMoved(_pos);
          widget.onScaleUpdate(_scale);
        },
        onLongPress: widget.onRemove,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: itemSize, height: itemSize,
          decoration: BoxDecoration(
            color: highlight ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? _primary.withValues(alpha: 0.6) : Colors.transparent,
              width: highlight ? 2 : 0,
            ),
          ),
          alignment: Alignment.center,
          child: widget.item.imageUrl != null
              ? Image.network(
                    widget.item.imageUrl!,
                    width: itemSize,
                    height: itemSize,
                    fit: BoxFit.contain,
                    color: Colors.white.withValues(alpha: 0.1),
                    colorBlendMode: BlendMode.dstATop,
                    errorBuilder: (_, __, ___) => Text(widget.item.emoji, style: TextStyle(fontSize: 28 * _scale)),
                  )
              : Text(widget.item.emoji, style: TextStyle(fontSize: 28 * _scale)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  방 구조 토글 — 창문/문/책상 탈부착
// ══════════════════════════════════════════════════════════════════════════════
class _FixtureToggleRow extends StatelessWidget {
  final VoidCallback onChanged;
  const _FixtureToggleRow({required this.onChanged});

  static const _fixtures = [
    ('window', '창문', '🪟'),
    ('door', '문', '🚪'),
    ('desk', '책상', '🪑'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          for (final (id, label, emoji) in _fixtures) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  state.toggleFixture(id);
                  onChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: state.roomFixtures.contains(id) ? _bgSoft : _bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: state.roomFixtures.contains(id) ? _primary : _border,
                      width: state.roomFixtures.contains(id) ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text(label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: state.roomFixtures.contains(id)
                                ? _primary2
                                : _textSub,
                          )),
                      Text(
                        state.roomFixtures.contains(id) ? '부착됨' : '탭하여 추가',
                        style: TextStyle(
                          fontSize: 8,
                          color: state.roomFixtures.contains(id)
                              ? _primary
                              : _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  창문 고정 요소
// ══════════════════════════════════════════════════════════════════════════════
class _WindowFixture extends StatelessWidget {
  final double width;
  final double height;
  final RoomTheme theme;
  const _WindowFixture({required this.width, required this.height, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.clamp(48.0, 110.0),
      height: height.clamp(40.0, 90.0),
      decoration: BoxDecoration(
        color: theme.glass,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.frame, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 6, left: 8,
            child: Text('☁️', style: TextStyle(fontSize: 16)),
          ),
          Center(
            child: Container(
              height: 2,
              color: theme.frame.withOpacity(0.7),
            ),
          ),
          Center(
            child: Container(
              width: 2,
              color: theme.frame.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  문 고정 요소
// ══════════════════════════════════════════════════════════════════════════════
class _DoorFixture extends StatelessWidget {
  final double width;
  final double height;
  final RoomTheme theme;
  const _DoorFixture({required this.width, required this.height, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.clamp(40.0, 80.0),
      height: height.clamp(60.0, 150.0),
      decoration: BoxDecoration(
        color: theme.door,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border.all(color: theme.doorPanel, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 문 패널 인셋
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: theme.doorPanel.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // 손잡이
          Align(
            alignment: const Alignment(0.7, 0.1),
            child: Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: theme.knob,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  책상 고정 요소
// ══════════════════════════════════════════════════════════════════════════════
class _DeskFixture extends StatelessWidget {
  final double width;
  final double height;
  final RoomTheme theme;
  const _DeskFixture({required this.width, required this.height, required this.theme});

  @override
  Widget build(BuildContext context) {
    final w = width.clamp(60.0, 130.0);
    final h = height.clamp(40.0, 80.0);
    final topH = h * 0.28;
    return SizedBox(
      width: w,
      height: h,
      child: Column(
        children: [
          // 상판
          Container(
            width: w,
            height: topH,
            decoration: BoxDecoration(
              color: theme.deskTop,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: theme.frame, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // 다리
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(width: w * 0.10, color: theme.deskLeg),
                  Container(width: w * 0.10, color: theme.deskLeg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  소품 팔레트 — 탭으로 방에 추가/제거
// ══════════════════════════════════════════════════════════════════════════════
class _RoomItemPalette extends StatelessWidget {
  final VoidCallback onChanged;
  const _RoomItemPalette({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final items = state.aiDecoItems
        .where((it) => it.dimension == SelfDimension.internal)
        .toList();

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text('경험을 완료하면 방 소품이 생겨요 ✨',
            style: TextStyle(color: _textSub, fontSize: 12)),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          final placed = state.placedRoomItemIds.contains(item.id);
          return GestureDetector(
            onTap: () {
              if (placed) {
                state.removeRoomItem(item.id);
              } else {
                state.placeRoomItem(item.id);
              }
              onChanged();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 10),
              width: 66,
              decoration: BoxDecoration(
                color: placed ? _bgSoft : _bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: placed ? _primary : _border, width: placed ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.imageUrl!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(item.emoji, style: const TextStyle(fontSize: 26)),
                          ),
                        )
                      : Text(item.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 3),
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          color: placed ? _primary2 : _textSub,
                          fontWeight: placed ? FontWeight.w700 : FontWeight.normal)),
                  if (placed)
                    const Text('배치됨', style: TextStyle(fontSize: 8, color: _primary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
