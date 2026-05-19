import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';

/// 내 공간 — 두 명의 동물의숲 스타일 사람 캐릭터가 방 안에 서있는 한 장면.
///
/// 핵심 컨셉:
///  • 두 캐릭터 각각 헤어·피부 등 개인 정체성을 반영해 꾸밀 수 있음
///  • 실제 경험을 완료해야 아이템(의상·소품·방 가구)이 잠금 해제됨
///  • 방과 캐릭터 둘 다 "지금까지 내가 한 경험들이 곧 나"라는 걸 시각화
class CharacterRoomScreen extends StatefulWidget {
  const CharacterRoomScreen({super.key});

  @override
  State<CharacterRoomScreen> createState() => _CharacterRoomScreenState();
}

class _CharacterRoomScreenState extends State<CharacterRoomScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF7F77DD);
  static const _bgSoft  = Color(0xFFEEEDFE);

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('내 공간',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('두 캐릭터가 함께 쌓아온 경험의 공간',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF8E8E93))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _bgSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('⭐ ${state.points}P',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF534AB7))),
                  ),
                ],
              ),
            ),

            // ── 방 + 두 아바타 통합 미리보기 ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: _RoomSceneWithAvatars(
                state: state,
                onTapChar: (i) {
                  setState(() => state.selectedCharacterIndex = i);
                  _tab.animateTo(0); // 캐릭터 탭으로 이동
                },
              ),
            ),

            // ── 진행도 (방 채움 + 캐릭터 완성도) ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniProgress(
                      label: '캐릭터',
                      emoji: '🙂',
                      ratio: state.characterFillRatio,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniProgress(
                      label: '방',
                      emoji: '🏠',
                      ratio: state.roomFillRatio,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── 탭 ────────────────────────────────────────────────
            TabBar(
              controller: _tab,
              indicatorColor: _primary,
              labelColor: _primary,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2,
              tabs: const [
                Tab(text: '캐릭터'),
                Tab(text: '방'),
                Tab(text: '상점'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _CharacterEditTab(onUpdate: () => setState(() {})),
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
//                       공유 헬퍼
// ══════════════════════════════════════════════════════════════════════════════
WardrobeItem? _findItem(String? id) {
  if (id == null) return null;
  for (final it in allWardrobeItems) {
    if (it.id == id) return it;
  }
  return null;
}

({Color fill, Color accent}) _clothingTone(WardrobeItem item) {
  switch (item.category) {
    case ExperienceCategory.cooking:
      return (fill: const Color(0xFFF5EAD2), accent: const Color(0xFFB89A5C));
    case ExperienceCategory.exercise:
      return (fill: const Color(0xFF6FA3D8), accent: const Color(0xFF34618E));
    case ExperienceCategory.travel:
      return (fill: const Color(0xFFC9A878), accent: const Color(0xFF876039));
    case ExperienceCategory.social:
      return (fill: const Color(0xFFE08FA1), accent: const Color(0xFFAA546A));
    case ExperienceCategory.creative:
      return (fill: const Color(0xFFD68C5D), accent: const Color(0xFF94531D));
    case ExperienceCategory.reading:
      return (fill: const Color(0xFFB89BD0), accent: const Color(0xFF6E548C));
    case ExperienceCategory.meditation:
      return (fill: const Color(0xFFD4C9E2), accent: const Color(0xFF7E6B9A));
    case ExperienceCategory.hobby:
      return (fill: const Color(0xFFA7C8B5), accent: const Color(0xFF537865));
    case ExperienceCategory.music:
      return (fill: const Color(0xFF8A7FB9), accent: const Color(0xFF453D6A));
    case ExperienceCategory.nature:
      return (fill: const Color(0xFFA0C57F), accent: const Color(0xFF4F783E));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                  방 안에 두 아바타가 서있는 통합 프리뷰
// ══════════════════════════════════════════════════════════════════════════════
class _RoomSceneWithAvatars extends StatelessWidget {
  final AppState state;
  final ValueChanged<int> onTapChar;

  const _RoomSceneWithAvatars({
    required this.state,
    required this.onTapChar,
  });

  @override
  Widget build(BuildContext context) {
    final wall   = _findItem(state.roomEquipped['wall']);
    final desk   = _findItem(state.roomEquipped['desk']);
    final floor  = _findItem(state.roomEquipped['floor']);
    final window = _findItem(state.roomEquipped['window']);
    final isMostlyEmpty = state.roomFillRatio < 0.25;

    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAF8F1), Color(0xFFEFE8DC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ─── 바닥선 (벽-바닥 경계)
            Positioned(
              left: 0, right: 0, bottom: 55,
              child: Container(height: 1, color: Colors.brown.withOpacity(0.12)),
            ),

            // ─── 벽 좌측 상단
            Positioned(
              top: 18, left: 22,
              child: wall != null
                  ? Text(wall.emoji, style: const TextStyle(fontSize: 46))
                  : const _EmptySlotPill(label: '벽'),
            ),

            // ─── 창문 우측 상단
            Positioned(
              top: 22, right: 26,
              child: window != null
                  ? Text(window.emoji, style: const TextStyle(fontSize: 42))
                  : const _EmptySlotPill(label: '창문'),
            ),

            // ─── 책상 좌측 하단
            Positioned(
              bottom: 14, left: 22,
              child: desk != null
                  ? Text(desk.emoji, style: const TextStyle(fontSize: 44))
                  : const _EmptySlotPill(label: '책상'),
            ),

            // ─── 바닥 소품 우측 하단
            Positioned(
              bottom: 14, right: 26,
              child: floor != null
                  ? Text(floor.emoji, style: const TextStyle(fontSize: 44))
                  : const _EmptySlotPill(label: '바닥'),
            ),

            // ─── 캐릭터 1 (좌측) — 탭하면 캐릭터 1 편집으로
            Positioned.fill(
              child: Align(
                alignment: const Alignment(-0.35, 0.75),
                child: GestureDetector(
                  onTap: () => onTapChar(0),
                  child: _buildCharWidget(state.characters[0], scale: 0.62,
                      isSelected: state.selectedCharacterIndex == 0),
                ),
              ),
            ),

            // ─── 캐릭터 2 (우측) — 탭하면 캐릭터 2 편집으로
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0.36, 0.60),
                child: GestureDetector(
                  onTap: () => onTapChar(1),
                  child: _buildCharWidget(state.characters[1], scale: 0.58,
                      isSelected: state.selectedCharacterIndex == 1),
                ),
              ),
            ),

            // ─── 텅 빈 방 안내
            if (isMostlyEmpty)
              Positioned(
                top: 10, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '아직 텅 빈 방 — 경험으로 채워보세요',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharWidget(CharacterProfile profile, {
    required double scale,
    required bool isSelected,
  }) {
    final hat = _findItem(profile.equipped['hat']);
    final top = _findItem(profile.equipped['top']);
    final bot = _findItem(profile.equipped['bottom']);
    final acc = _findItem(profile.equipped['accessory']);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이름 태그 (선택된 경우 강조)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7F77DD)
                : Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            profile.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _HumanAvatar(
          profile: profile,
          hat: hat, top: top, bottom: bot, accessory: acc,
          scale: scale,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//   캐릭터 이미지 아바타 — 실제 PNG 이미지 위에 모자·소품 오버레이
// ══════════════════════════════════════════════════════════════════════════════
class _HumanAvatar extends StatelessWidget {
  final CharacterProfile profile;
  final WardrobeItem? hat;
  final WardrobeItem? top;
  final WardrobeItem? bottom;
  final WardrobeItem? accessory;
  final double scale;

  const _HumanAvatar({
    required this.profile,
    required this.hat,
    required this.top,
    required this.bottom,
    required this.accessory,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final imgH   = 160.0 * scale;
    final hatFs  = imgH * 0.20;
    final accFs  = imgH * 0.14;
    final itemFs = imgH * 0.14; // 상의·하의 뱃지

    return SizedBox(
      height: imgH + hatFs * 0.6, // 모자 공간 확보
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ── 캐릭터 이미지 (male.png / female.png) ─────────────
          Positioned(
            bottom: 0,
            child: Image.asset(
              profile.gender.assetPath,
              height: imgH,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _CharacterPlaceholder(
                gender: profile.gender,
                height: imgH,
              ),
            ),
          ),

          // ── 모자 (머리 위 영역 — 이미지 상단 약 18% 지점) ────
          if (hat != null)
            Positioned(
              top: 0,
              child: Text(hat!.emoji,
                  style: TextStyle(fontSize: hatFs, height: 1.0)),
            ),

          // ── 상의 아이템 배지 (좌측 상단) ─────────────────────
          if (top != null)
            Positioned(
              top: imgH * 0.30,
              left: 0,
              child: _ItemBadge(emoji: top!.emoji, size: itemFs),
            ),

          // ── 하의 아이템 배지 (좌측 하단) ─────────────────────
          if (bottom != null)
            Positioned(
              bottom: imgH * 0.08,
              left: 0,
              child: _ItemBadge(emoji: bottom!.emoji, size: itemFs),
            ),

          // ── 소품 (우측 손 높이) ───────────────────────────────
          if (accessory != null)
            Positioned(
              bottom: imgH * 0.25,
              right: 0,
              child: _ItemBadge(emoji: accessory!.emoji, size: accFs),
            ),
        ],
      ),
    );
  }
}

/// 이미지 로드 실패 시 표시할 심플 placeholder
class _CharacterPlaceholder extends StatelessWidget {
  final CharacterGender gender;
  final double height;
  const _CharacterPlaceholder({required this.gender, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: height * 0.6,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0CCEE), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            gender == CharacterGender.female ? '👧' : '👦',
            style: TextStyle(fontSize: height * 0.28),
          ),
          const SizedBox(height: 6),
          Text(
            '이미지를\nassets에\n추가해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: height * 0.07,
              color: const Color(0xFF8E8E93),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 아이템 오버레이 배지 (흰 동그라미 배경 위 emoji)
class _ItemBadge extends StatelessWidget {
  final String emoji;
  final double size;
  const _ItemBadge({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.4,
      height: size * 1.4,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: TextStyle(fontSize: size, height: 1.0)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                        빈 슬롯 알약 레이블
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
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                            진행도 미니 바
// ══════════════════════════════════════════════════════════════════════════════
class _MiniProgress extends StatelessWidget {
  final String label;
  final String emoji;
  final double ratio;
  const _MiniProgress({
    required this.label, required this.emoji, required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${(ratio * 100).round()}%',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7F77DD)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                            캐릭터 편집 탭
// ══════════════════════════════════════════════════════════════════════════════
class _CharacterEditTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const _CharacterEditTab({required this.onUpdate});

  @override
  State<_CharacterEditTab> createState() => _CharacterEditTabState();
}

class _CharacterEditTabState extends State<_CharacterEditTab> {
  @override
  Widget build(BuildContext context) {
    final state      = AppState.i;
    final charIndex  = state.selectedCharacterIndex;
    final profile    = state.characters[charIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── 캐릭터 선택 ─────────────────────────────────────
          _CharacterSelector(
            selectedIndex: charIndex,
            characters:    state.characters,
            onSelect: (i) {
              setState(() => state.selectedCharacterIndex = i);
              widget.onUpdate();
            },
          ),
          const SizedBox(height: 22),

          // ── 정체성 섹션 ─────────────────────────────────────
          const _SectionHeader(
            title: '정체성',
            sub:   '나를 표현하는 외형을 꾸며요',
          ),
          const SizedBox(height: 14),

          // 성별 선택
          _IdentityRow(
            label: '성별',
            child: _GenderPicker(
              selected: profile.gender,
              onSelect: (g) {
                setState(() => profile.gender = g);
                widget.onUpdate();
              },
            ),
          ),
          const SizedBox(height: 14),

          // 이름 편집
          _IdentityRow(
            label: '이름',
            child: _NameEditor(
              name: profile.name,
              onChanged: (v) {
                setState(() => profile.name = v);
                widget.onUpdate();
              },
            ),
          ),
          const SizedBox(height: 14),

          // 헤어 스타일
          _IdentityRow(
            label: '헤어 스타일',
            child: _HairStylePicker(
              selected: profile.hairStyle,
              onSelect: (s) {
                setState(() => profile.hairStyle = s);
                widget.onUpdate();
              },
            ),
          ),
          const SizedBox(height: 14),

          // 머리 색
          _IdentityRow(
            label: '머리 색',
            child: _ColorSwatchPicker(
              colors: allHairColors
                  .map((h) => (id: h.id, label: h.label, color: h.color))
                  .toList(),
              selectedId: profile.hairColorId,
              onSelect: (id) {
                setState(() => profile.hairColorId = id);
                widget.onUpdate();
              },
            ),
          ),
          const SizedBox(height: 14),

          // 피부 톤
          _IdentityRow(
            label: '피부 톤',
            child: _ColorSwatchPicker(
              colors: allSkinColors
                  .map((s) => (id: s.id, label: s.label, color: s.color))
                  .toList(),
              selectedId: profile.skinColorId,
              onSelect: (id) {
                setState(() => profile.skinColorId = id);
                widget.onUpdate();
              },
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── 경험 아이템 섹션 ─────────────────────────────────
          const _SectionHeader(
            title: '경험으로 얻은 아이템',
            sub:   '완료한 경험에 따라 의상·소품이 잠금 해제돼요',
          ),
          const SizedBox(height: 18),

          for (final slot in characterSlots) ...[
            _SlotItemRow(
              slotLabel:  characterSlotLabels[slot]!,
              equippedId: profile.equipped[slot],
              items: allWardrobeItems
                  .where((it) =>
                      it.dimension == SelfDimension.external &&
                      it.slot == slot &&
                      state.wardrobeUnlocked.contains(it.id))
                  .toList(),
              onTap: (id) {
                final current = profile.equipped[slot];
                state.equipCharacter(charIndex, slot, current == id ? null : id);
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                 정체성 커스터마이징 UI 위젯들
// ══════════════════════════════════════════════════════════════════════════════

/// 캐릭터 1 / 2 선택 토글
class _CharacterSelector extends StatelessWidget {
  final int selectedIndex;
  final List<CharacterProfile> characters;
  final ValueChanged<int> onSelect;

  const _CharacterSelector({
    required this.selectedIndex,
    required this.characters,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(characters.length, (i) {
          final isSelected = selectedIndex == i;
          final c = characters[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4, offset: const Offset(0, 1))]
                      : null,
                ),
                child: Column(
                  children: [
                    // 미니 아바타 미리보기 (피부+머리 색 원)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: c.skinColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF7F77DD)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          child: Container(
                            width: 22, height: 11,
                            decoration: BoxDecoration(
                              color: c.hairColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF534AB7)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;
  final String sub;
  const _SectionHeader({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7F77DD),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(sub,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
      ],
    );
  }
}

/// 레이블 + 자식 위젯 행
class _IdentityRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _IdentityRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// 이름 편집 인라인 TextField
class _NameEditor extends StatefulWidget {
  final String name;
  final ValueChanged<String> onChanged;
  const _NameEditor({required this.name, required this.onChanged});

  @override
  State<_NameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<_NameEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        maxLength: 8,
        decoration: InputDecoration(
          counterText: '',
          hintText: '캐릭터 이름',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF7F77DD), width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// 헤어 스타일 선택기
class _HairStylePicker extends StatelessWidget {
  final HairStyle selected;
  final ValueChanged<HairStyle> onSelect;
  const _HairStylePicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HairStyle.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final style      = HairStyle.values[i];
          final isSelected = selected == style;
          return GestureDetector(
            onTap: () => onSelect(style),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEEEDFE)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7F77DD)
                      : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(style.emoji,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(style.label,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 색상 스와치 선택기 (머리색 / 피부색 공용)
class _ColorSwatchPicker extends StatelessWidget {
  final List<({String id, String label, Color color})> colors;
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ColorSwatchPicker({
    required this.colors,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c          = colors[i];
          final isSelected = selectedId == c.id;
          return Tooltip(
            message: c.label,
            child: GestureDetector(
              onTap: () => onSelect(c.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: c.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7F77DD)
                        : Colors.grey.shade300,
                    width: isSelected ? 3.0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: const Color(0xFF7F77DD).withOpacity(0.40),
                          blurRadius: 6, spreadRadius: 1)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 18)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 성별 선택 토글 (여자 / 남자)
class _GenderPicker extends StatelessWidget {
  final CharacterGender selected;
  final ValueChanged<CharacterGender> onSelect;
  const _GenderPicker({required this.selected, required this.onSelect});

  static const _primary    = Color(0xFF7F77DD);
  static const _primaryBg  = Color(0xFFEEEDFE);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: CharacterGender.values.map((g) {
        final isSelected = selected == g;
        final emoji = g == CharacterGender.female ? '👧' : '👦';
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onSelect(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _primaryBg : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _primary : Colors.grey.shade200,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: _primary.withOpacity(0.18),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 7),
                  Text(
                    g.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _primary : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                            슬롯별 아이템 가로 행
// ══════════════════════════════════════════════════════════════════════════════
class _SlotItemRow extends StatelessWidget {
  final String slotLabel;
  final String? equippedId;
  final List<WardrobeItem> items;
  final void Function(String id) onTap;

  const _SlotItemRow({
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
        Row(children: [
          Text(slotLabel,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('· ${items.length}개',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade400)),
          const Spacer(),
          if (equippedId != null)
            Text('탭하면 해제',
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade400)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: items.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '아직 잠금 해제된 아이템이 없어요 — 상점에서 확인해보세요',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final it         = items[i];
                    final isEquipped = equippedId == it.id;
                    return GestureDetector(
                      onTap: () => onTap(it.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 78,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isEquipped
                              ? const Color(0xFFEEEDFE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEquipped
                                ? const Color(0xFF7F77DD)
                                : Colors.grey.shade200,
                            width: isEquipped ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(it.emoji,
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 2),
                            Text(it.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
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
//                                방 편집 탭
// ══════════════════════════════════════════════════════════════════════════════
class _RoomEditTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _RoomEditTab({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: '내면이 어떤지',
            sub:   '독서·명상·취미·음악·자연 경험이 방에 쌓여요',
          ),
          const SizedBox(height: 18),

          for (final slot in roomSlots) ...[
            _SlotItemRow(
              slotLabel:  roomSlotLabels[slot]!,
              equippedId: state.roomEquipped[slot],
              items: allWardrobeItems
                  .where((it) =>
                      it.dimension == SelfDimension.internal &&
                      it.slot == slot &&
                      state.wardrobeUnlocked.contains(it.id))
                  .toList(),
              onTap: (id) {
                final current = state.roomEquipped[slot];
                state.equipRoom(slot, current == id ? null : id);
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

// ══════════════════════════════════════════════════════════════════════════════
//                                  상점 탭
// ══════════════════════════════════════════════════════════════════════════════
class _ShopTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const _ShopTab({required this.onUpdate});

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  SelfDimension _dimension      = SelfDimension.external;
  ExperienceCategory? _category; // null = 전체

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    final visible = allWardrobeItems.where((it) {
      if (it.dimension != _dimension) return false;
      if (_category != null && it.category != _category) return false;
      return true;
    }).toList();

    final cats = ExperienceCategory.values
        .where((c) => c.dimension == _dimension)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 외/내 토글
          _DimensionToggle(
            value: _dimension,
            onChanged: (d) => setState(() {
              _dimension = d;
              _category  = null;
            }),
          ),

          const SizedBox(height: 18),

          // 카테고리 안내
          Text(
            _dimension == SelfDimension.external
                ? '어떤 경험으로 캐릭터 아이템을 얻을지 골라보세요'
                : '어떤 경험으로 방 아이템을 얻을지 골라보세요',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // 카테고리 칩
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: '전체',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                const SizedBox(width: 6),
                for (final c in cats) ...[
                  _CategoryChip(
                    label: '${c.emoji} ${c.label}',
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('해당 카테고리의 아이템이 없어요',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final item       = visible[i];
                final isUnlocked = state.wardrobeUnlocked.contains(item.id);
                final canAfford  = state.points >= item.cost;
                return _ShopCard(
                  item:       item,
                  isUnlocked: isUnlocked,
                  canAfford:  canAfford,
                  onBuy: () {
                    if (isUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '이미 보유 중이에요 — ${item.dimension.label} 탭에서 장착해보세요'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                      return;
                    }
                    if (state.buyWardrobe(item)) {
                      setState(() {});
                      widget.onUpdate();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            '${item.emoji} ${item.name} 획득! ${item.dimension.label}에서 꾸며보세요'),
                        backgroundColor: const Color(0xFF7F77DD),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('포인트가 부족해요. 경험을 더 완료해봐요!'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DimensionToggle extends StatelessWidget {
  final SelfDimension value;
  final ValueChanged<SelfDimension> onChanged;
  const _DimensionToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final d in SelfDimension.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(d),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        value == d ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: value == d
                        ? [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4, offset: const Offset(0, 1))]
                        : null,
                  ),
                  child: Column(children: [
                    Text(d.label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: value == d
                                ? const Color(0xFF534AB7)
                                : Colors.grey)),
                    const SizedBox(height: 2),
                    Text(d.description,
                        style: TextStyle(
                            fontSize: 10,
                            color: value == d
                                ? Colors.grey.shade600
                                : Colors.grey.shade400)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7F77DD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? const Color(0xFF7F77DD)
                  : Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F4FE),
                borderRadius: BorderRadius.circular(10),
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_slotLabel,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(item.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(item.unlockHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  height: 1.3)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isUnlocked
                    ? Colors.grey.shade100
                    : (canAfford
                        ? const Color(0xFF7F77DD)
                        : Colors.grey.shade200),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              onPressed: onBuy,
              child: Text(
                isUnlocked ? '보유 중' : '⭐ ${item.cost}P',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isUnlocked
                      ? Colors.grey.shade600
                      : (canAfford ? Colors.white : Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
