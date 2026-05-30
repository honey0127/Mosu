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
  int _subTab = 0; // 0 = 아바타, 1 = 코디

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 서브 탭 ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Expanded(child: _SubTabBtn(label: '🧑 아바타', selected: _subTab == 0, onTap: () => setState(() => _subTab = 0))),
              const SizedBox(width: 8),
              Expanded(child: _SubTabBtn(label: '👗 코디', selected: _subTab == 1, onTap: () => setState(() => _subTab = 1))),
            ],
          ),
        ),

        if (_subTab == 0)
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      const Expanded(child: Text('헤어·피부·눈·표정을 자유롭게 바꿔보세요', style: TextStyle(fontSize: 12, color: _textSub))),
                      AvatarMakerSaveWidget(controller: widget.avatarController),
                    ],
                  ),
                ),
                Expanded(
                  child: AvatarMakerCustomizer(controller: widget.avatarController, autosave: true),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: _WardrobeGrid(
              dimension: SelfDimension.external,
              slots: characterSlots,
              slotLabels: characterSlotLabels,
              equippedMap: AppState.i.characterEquipped,
              onEquip: (slot, id) => setState(() {
                final cur = AppState.i.characterEquipped[slot];
                AppState.i.equipCharacter(slot, cur == id ? null : id);
              }),
            ),
          ),
      ],
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
                child: Text('소품 추가하기',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSub)),
              ),
              _RoomItemPalette(onChanged: () => setState(() {})),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
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
//  서브 탭 버튼
// ══════════════════════════════════════════════════════════════════════════════
class _SubTabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SubTabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : _bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _primary : _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _textSub),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  워드로브 그리드 — 슬롯 탭 + 아이템 그리드 (스크롤 없음)
// ══════════════════════════════════════════════════════════════════════════════
class _WardrobeGrid extends StatefulWidget {
  final SelfDimension dimension;
  final List<String> slots;
  final Map<String, String> slotLabels;
  final Map<String, String?> equippedMap;
  final void Function(String slot, String id) onEquip;

  const _WardrobeGrid({
    required this.dimension,
    required this.slots,
    required this.slotLabels,
    required this.equippedMap,
    required this.onEquip,
  });

  @override
  State<_WardrobeGrid> createState() => _WardrobeGridState();
}

class _WardrobeGridState extends State<_WardrobeGrid> {
  late String _slot;

  @override
  void initState() {
    super.initState();
    _slot = widget.slots.first;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final equippedId = widget.equippedMap[_slot];

    // 경험으로 잠금 해제된 워드로브 아이템
    final wardrobeItems = allWardrobeItems
        .where((it) =>
            it.slot == _slot &&
            it.dimension == widget.dimension &&
            state.wardrobeUnlocked.contains(it.id))
        .toList();

    // AI 생성 아이템
    final aiItems = state.aiDecoItems
        .where((it) => it.slot == _slot && it.dimension == widget.dimension)
        .toList();

    // 통합 아이템 목록: (emoji, name, id, isAi)
    final allItems = [
      ...wardrobeItems.map((it) => (it.emoji, it.name, it.id, false)),
      ...aiItems.map((it) => (it.emoji, it.name, it.id, true)),
    ];

    return Column(
      children: [
        // ── 슬롯 탭 ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: widget.slots.map((s) {
              final sel = s == _slot;
              final count =
                  allWardrobeItems.where((it) => it.slot == s && it.dimension == widget.dimension && state.wardrobeUnlocked.contains(it.id)).length +
                  state.aiDecoItems.where((it) => it.slot == s && it.dimension == widget.dimension).length;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _slot = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _primary : _bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? _primary : _border),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.slotLabels[s]!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : _textSub)),
                        if (count > 0)
                          Text('$count', style: TextStyle(fontSize: 10,
                              color: sel ? Colors.white70 : _textSub)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── 아이템 그리드 ─────────────────────────────────────
        Expanded(
          child: allItems.isEmpty
              ? _EmptySlot(dimension: widget.dimension)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: allItems.length,
                  itemBuilder: (_, i) {
                    final (emoji, name, id, isAi) = allItems[i];
                    final isEquipped = equippedId == id;
                    return GestureDetector(
                      onTap: () => widget.onEquip(_slot, id),
                      child: _WardrobeItemCell(
                        emoji: emoji, name: name,
                        isSelected: isEquipped, isAi: isAi,
                        imageUrl: isAi ? aiItems.where((it) => it.id == id).firstOrNull?.imageUrl : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  워드로브 아이템 셀
// ══════════════════════════════════════════════════════════════════════════════
class _WardrobeItemCell extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isSelected;
  final bool isAi;
  final String? imageUrl;

  const _WardrobeItemCell({
    required this.emoji,
    required this.name,
    this.isSelected = false,
    this.isAi = false,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isSelected ? _bgSoft : _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? _primary : _border, width: isSelected ? 2 : 1),
        boxShadow: isSelected
            ? [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Text(emoji, style: const TextStyle(fontSize: 34)),
                      ),
                    )
                  : Text(emoji, style: const TextStyle(fontSize: 34)),
              if (isAi)
                Positioned(
                  right: -4, top: -4,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text('✨', style: TextStyle(fontSize: 8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: isSelected ? _primary : _textMain)),
          if (isSelected)
            const Text('착용 중', style: TextStyle(fontSize: 9, color: _primary)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  빈 슬롯 안내
// ══════════════════════════════════════════════════════════════════════════════
class _EmptySlot extends StatelessWidget {
  final SelfDimension dimension;
  const _EmptySlot({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text('아직 아이템이 없어요',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              dimension == SelfDimension.external
                  ? '경험을 완료하면\nAI가 캐릭터 아이템을 생성해줘요 ✨'
                  : '경험을 완료하면\nAI가 방 소품을 생성해줘요 ✨',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _textSub, height: 1.6),
            ),
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final placed = state.placedRoomItemIds
        .map((id) => state.aiDecoItems.where((it) => it.id == id).firstOrNull)
        .whereType<DecoItem>()
        .toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Container(
        decoration: const BoxDecoration(color: _wallDefault),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // 바닥
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: h * 0.40,
              child: Container(color: _floorDefault),
            ),
            // 바닥/벽 경계선
            Positioned(
              bottom: h * 0.40, left: 0, right: 0,
              child: Container(height: 2, color: Colors.black12),
            ),
            // 캐릭터 (바닥 중앙)
            Positioned(
              bottom: h * 0.36,
              left: 0, right: 0,
              child: Center(
                child: SizedBox(
                  width: 64, height: 84,
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
                position: state.roomItemPositions[item.id] ?? const Offset(0.15, 0.3),
                scale: state.roomItemScales[item.id] ?? 1.0,
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
                  setState(() {});
                  widget.onChanged();
                },
              ),
          ],
        ),
      );
    });
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

    return Positioned(
      left: x, top: y,
      child: GestureDetector(
        onScaleStart: (details) {
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
            color: _dragging ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _dragging ? _primary.withValues(alpha: 0.5) : Colors.transparent,
              width: _dragging ? 2 : 0,
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
