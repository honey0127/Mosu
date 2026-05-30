import 'package:flutter/material.dart';
import 'package:animal_crossing_ui/animal_crossing_ui.dart';
import 'package:avatar_maker/avatar_maker.dart';
import '../../models/experience.dart';
import '../../models/app_state.dart';
import '../../models/wardrobe_item.dart';

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
            _ACHeader(points: state.points),

            // 방+캐릭터 씬 — AC 스타일 2D 룸
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: _RoomScene(state: state, avatarController: _avatarController),
            ),

            // 진행도
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProgressRow(state: state),
            ),
            const SizedBox(height: 6),

            // 탭 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ACTabBar(
                index: _tabIndex,
                tabs: const ['캐릭터', '방', '상점'],
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: 2),

            // 탭 콘텐츠
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  // 캐릭터 탭 — AvatarMakerCustomizer가 모든 커스터마이징 제공
                  _CharacterEditTab(avatarController: _avatarController),
                  _RoomEditTab(onUpdate: () => setState(() {})),
                  _ShopTab(onUpdate: () => setState(() {})),
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
  final int points;
  const _ACHeader({required this.points});

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
          ACUICard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text('${points}P',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primary2)),
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
                  : const _EmptySlotPill(label: '벽'),
            ),

            // ── 책상/가구 (바닥 왼쪽) ─────────────────────────────────
            Positioned(
              left: 14,
              bottom: 6,
              child: desk != null
                  ? _FloorFurniture(item: desk, size: 46)
                  : const _EmptySlotPill(label: '책상'),
            ),

            // ── 바닥 소품 (바닥 오른쪽) ───────────────────────────────
            Positioned(
              right: 14,
              bottom: 6,
              child: floor != null
                  ? _FloorFurniture(item: floor, size: 38)
                  : const _EmptySlotPill(label: '바닥'),
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
class _CharacterEditTab extends StatelessWidget {
  final AvatarMakerController avatarController;
  const _CharacterEditTab({required this.avatarController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              const Expanded(
                child: _ACSection(
                  emoji: '✨',
                  title: '내 캐릭터 꾸미기',
                  subtitle: '헤어·피부·눈·옷·소품을 자유롭게 바꿔보세요',
                ),
              ),
              // 저장 버튼 — 탭하면 현재 설정을 저장
              AvatarMakerSaveWidget(controller: avatarController),
            ],
          ),
        ),
        // autosave: true → 선택할 때마다 자동 저장, 위 SaveWidget은 명시적 저장용
        Expanded(
          child: AvatarMakerCustomizer(
            controller: avatarController,
            autosave: true,
          ),
        ),
      ],
    );
  }
}

// _CharacterPreviewCard 와 _OutfitRow 는 AvatarMakerCustomizer로 대체됨

// ══════════════════════════════════════════════════════════════════════════════
//                방 편집 탭 — 상단 미니 룸 미리보기 + 슬롯 목록
// ══════════════════════════════════════════════════════════════════════════════
class _RoomEditTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _RoomEditTab({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 방 미니 미리보기 ──────────────────────────────
          _RoomPreviewCard(state: state),
          const SizedBox(height: 16),

          _ACSection(
            emoji: '🏡',
            title: '내면이 어떤지',
            subtitle: '독서·명상·취미·음악·자연 경험이 방에 쌓여요',
          ),
          const SizedBox(height: 14),

          for (final slot in roomSlots) ...[
            _SlotSection(
              slotLabel: roomSlotLabels[slot]!,
              equippedId: state.roomEquipped[slot],
              items: allWardrobeItems
                  .where((it) =>
                      it.dimension == SelfDimension.internal &&
                      it.slot == slot &&
                      state.wardrobeUnlocked.contains(it.id))
                  .toList(),
              onTap: (id) {
                final cur = state.roomEquipped[slot];
                state.equipRoom(slot, cur == id ? null : id);
                onUpdate();
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ── 방 미니 미리보기 카드 ───────────────────────────────────────────────────
class _RoomPreviewCard extends StatelessWidget {
  final AppState state;
  const _RoomPreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final wall   = _findItem(state.roomEquipped['wall']);
    final desk   = _findItem(state.roomEquipped['desk']);
    final floor  = _findItem(state.roomEquipped['floor']);
    final window = _findItem(state.roomEquipped['window']);

    final wallColor = wall != null
        ? _categoryColor(wall.category)
        : _wallDefault;
    final floorColor = floor != null
        ? _categoryColor(floor.category).withOpacity(0.85)
        : _floorDefault;

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
                  child: window != null
                      ? Center(child: Text(window.emoji,
                          style: const TextStyle(fontSize: 14)))
                      : const Center(child: Text('☁️',
                          style: TextStyle(fontSize: 12))),
                ),
              ),
              // 벽 장식
              if (wall != null)
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
                      child: Text(wall.emoji,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              // 책상
              if (desk != null)
                Positioned(
                  bottom: 6, left: 14,
                  child: Text(desk.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              // 바닥 소품
              if (floor != null)
                Positioned(
                  bottom: 6, right: 14,
                  child: Text(floor.emoji,
                      style: const TextStyle(fontSize: 24)),
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
            ? [
                BoxShadow(
                  color: _primary.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
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
//                              상점 탭
// ══════════════════════════════════════════════════════════════════════════════
class _ShopTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const _ShopTab({required this.onUpdate});

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  SelfDimension _dim = SelfDimension.external;
  ExperienceCategory? _cat;

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final visible = allWardrobeItems.where((it) {
      if (it.dimension != _dim) return false;
      if (_cat != null && it.category != _cat) return false;
      return true;
    }).toList();
    final cats =
        ExperienceCategory.values.where((c) => c.dimension == _dim).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DimToggle(
            value: _dim,
            onChanged: (d) => setState(() {
              _dim = d;
              _cat = null;
            }),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: '전체',
                  selected: _cat == null,
                  onTap: () => setState(() => _cat = null),
                ),
                const SizedBox(width: 6),
                for (final c in cats) ...[
                  _FilterChip(
                    label: '${c.emoji} ${c.label}',
                    selected: _cat == c,
                    onTap: () => setState(() => _cat = c),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: ACUIEmptyState(
                icon: const Text('🛒', style: TextStyle(fontSize: 56)),
                title: '아이템 없음',
                message: '해당 카테고리에 아이템이 없어요',
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final item = visible[i];
                final isUnlocked =
                    state.wardrobeUnlocked.contains(item.id);
                final canAfford = state.points >= item.cost;
                return _ShopCard(
                  item: item,
                  isUnlocked: isUnlocked,
                  canAfford: canAfford,
                  onBuy: () =>
                      _handleBuy(context, state, item, isUnlocked),
                );
              },
            ),
        ],
      ),
    );
  }

  void _handleBuy(BuildContext context, AppState state,
      WardrobeItem item, bool isUnlocked) {
    if (isUnlocked) {
      _snack(context,
          '이미 가지고 있어요 — ${item.dimension.label} 탭에서 장착해보세요');
      return;
    }
    if (state.buyWardrobe(item)) {
      setState(() {});
      widget.onUpdate();
      _snack(context,
          '${item.emoji} ${item.name} 획득! ${item.dimension.label}에서 꾸며보세요',
          color: _primary);
    } else {
      _snack(context, '포인트가 부족해요. 경험을 더 완료해봐요!');
    }
  }

  void _snack(BuildContext context, String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//              상점 카드
// ══════════════════════════════════════════════════════════════════════════════
class _ShopCard extends StatelessWidget {
  final WardrobeItem item;
  final bool isUnlocked;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.item,
    required this.isUnlocked,
    required this.canAfford,
    required this.onBuy,
  });

  String get _slotLabel {
    final m = item.dimension == SelfDimension.external
        ? characterSlotLabels
        : roomSlotLabels;
    return m[item.slot] ?? item.slot;
  }

  @override
  Widget build(BuildContext context) {
    return ACUICard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _bgSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 24)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _bgSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_slotLabel,
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _textMain)),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                item.unlockHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, color: _textSub, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ACUIButton(
                onPressed: onBuy,
                child: Text(
                  isUnlocked ? '보유 중' : '⭐ ${item.cost}P',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
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
//              외면/내면 토글
// ══════════════════════════════════════════════════════════════════════════════
class _DimToggle extends StatelessWidget {
  final SelfDimension value;
  final ValueChanged<SelfDimension> onChanged;
  const _DimToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ACUICard(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final d in SelfDimension.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == d
                          ? _primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: value == d
                                ? Colors.white
                                : _textSub,
                          ),
                        ),
                        Text(
                          d.description,
                          style: TextStyle(
                            fontSize: 9,
                            color: value == d
                                ? Colors.white70
                                : _textSub,
                          ),
                        ),
                      ],
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
//              필터 칩
// ══════════════════════════════════════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _primary : _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _primary : _border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _textSub,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//              섹션 헤더
// ══════════════════════════════════════════════════════════════════════════════
class _ACSection extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _ACSection({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
            const SizedBox(height: 1),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: _textSub)),
          ],
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//              빈 슬롯 필
// ══════════════════════════════════════════════════════════════════════════════
class _EmptySlotPill extends StatelessWidget {
  final String label;
  const _EmptySlotPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 9, color: _textSub)),
    );
  }
}
