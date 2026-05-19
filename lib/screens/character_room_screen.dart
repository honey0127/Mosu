import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'animal_picker_screen.dart';

/// 내 공간 — 캐릭터(외면)가 방(내면) 안에 서있는 한 장면.
///
/// 화면 구성:
///   상단: 방 + 아바타 통합 미리보기
///   하단: 탭(캐릭터 꾸미기 / 방 꾸미기 / 상점)으로 슬롯 조작
///
/// 핵심 컨셉: 방과 캐릭터 둘 다 실제 경험으로만 채워지고,
/// 한 장면에 함께 보여 "지금까지 내가 한 경험들이 곧 나"라는 걸 시각화한다.
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

    // 동물 미선택 상태면 첫 프레임 후 picker 띄움
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && AppState.i.selectedAnimalId == null) {
        _openAnimalPicker(firstTime: true);
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _openAnimalPicker({bool firstTime = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnimalPickerScreen(isFirstTime: firstTime),
        fullscreenDialog: firstTime,
      ),
    );
    if (mounted) setState(() {});
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
                      Text('밖에서 어떤 사람인지(캐릭터) · 내면이 어떤지(방)',
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

            // ── 방 + 아바타 통합 미리보기 ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: _RoomSceneWithAvatar(
                state: state,
                onChangeAnimal: () => _openAnimalPicker(),
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
//                  공유 헬퍼 — id로 아이템 찾기
// ══════════════════════════════════════════════════════════════════════════════
WardrobeItem? _findItem(String? id) {
  if (id == null) return null;
  for (final it in allWardrobeItems) {
    if (it.id == id) return it;
  }
  return null;
}

// ── 옷 색깔 (카테고리 기반) ──────────────────────────────────────────────────
// AC 스타일 컬러 패치를 그릴 때 사용. 같은 카테고리 옷은 톤이 통일됨.
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
//                  방 안에 아바타가 서있는 통합 프리뷰
// ══════════════════════════════════════════════════════════════════════════════
class _RoomSceneWithAvatar extends StatelessWidget {
  final AppState state;
  final VoidCallback onChangeAnimal;
  const _RoomSceneWithAvatar({
    required this.state,
    required this.onChangeAnimal,
  });

  @override
  Widget build(BuildContext context) {
    // 방 아이템
    final wall   = _findItem(state.roomEquipped['wall']);
    final desk   = _findItem(state.roomEquipped['desk']);
    final floor  = _findItem(state.roomEquipped['floor']);
    final window = _findItem(state.roomEquipped['window']);

    // 캐릭터 아이템
    final hat   = _findItem(state.characterEquipped['hat']);
    final top   = _findItem(state.characterEquipped['top']);
    final bot   = _findItem(state.characterEquipped['bottom']);
    final acc   = _findItem(state.characterEquipped['accessory']);

    final animal = state.selectedAnimal;

    final isMostlyEmpty = state.roomFillRatio < 0.25;

    return Container(
      width: double.infinity,
      height: 320,
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
            // ─── 바닥선 (벽-바닥 경계) ───────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: Container(
                height: 1,
                color: Colors.brown.withOpacity(0.12),
              ),
            ),

            // ─── 벽 — 좌측 상단 ─────────────────────────────────
            Positioned(
              top: 20,
              left: 24,
              child: wall != null
                  ? Text(wall.emoji, style: const TextStyle(fontSize: 48))
                  : const _EmptySlotPill(label: '벽'),
            ),

            // ─── 창문 — 우측 상단 ───────────────────────────────
            Positioned(
              top: 24,
              right: 28,
              child: window != null
                  ? Text(window.emoji, style: const TextStyle(fontSize: 44))
                  : const _EmptySlotPill(label: '창문'),
            ),

            // ─── 책상 — 좌측 하단 (바닥 위) ─────────────────────
            Positioned(
              bottom: 18,
              left: 24,
              child: desk != null
                  ? Text(desk.emoji, style: const TextStyle(fontSize: 46))
                  : const _EmptySlotPill(label: '책상'),
            ),

            // ─── 바닥 소품 — 우측 하단 ──────────────────────────
            Positioned(
              bottom: 18,
              right: 28,
              child: floor != null
                  ? Text(floor.emoji, style: const TextStyle(fontSize: 46))
                  : const _EmptySlotPill(label: '바닥'),
            ),

            // ─── 캐릭터 — 가운데, 방 안에 서있음 ────────────────
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, 0.55),
                child: animal != null
                    ? _AnimalAvatar(
                        animal: animal,
                        hat: hat,
                        top: top,
                        bottom: bot,
                        accessory: acc,
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            // ─── 동물 바꾸기 칩 — 우측 상단 ─────────────────────
            if (animal != null)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onChangeAnimal,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cached,
                              size: 13, color: Color(0xFF7F77DD)),
                          const SizedBox(width: 4),
                          Text(animal.emoji,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 4),
                          const Text('바꾸기',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF534AB7),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ─── 텅 빈 방 안내 ──────────────────────────────────
            if (isMostlyEmpty)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '아직 텅 빈 방 — 경험으로 채워보세요',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
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
//             동물의숲 풍 의인화 아바타 — 선택한 동물 + 옷 레이어
// ══════════════════════════════════════════════════════════════════════════════
/// 베이스 동물 위에 의상을 입혀 표현하는 캐릭터 위젯.
///
/// 신체 구조(아래→위 z-order):
///   1. 바닥 그림자
///   2. 다리 두 개 (몸통 아래)
///   3. 발 두 개 (다리 아래, 약간 넓게)
///   4. 팔 두 개 (어깨에서 손목까지, 살짝 바깥으로 회전)
///   5. 손/발바닥 (팔 끝, 둥근 점)
///   6. 몸통 (둥근 사다리꼴 — 어깨가 넓고 허리는 살짝 좁음)
///   7. 하의 emoji (다리 위로 입혀짐)
///   8. 상의 emoji (몸통 위로 입혀짐, 몸통 폭에 맞춰 크게)
///   9. 동물 머리 (몸통 위에 살짝 겹쳐서)
///  10. 모자 (머리 위)
///  11. 소품 (우측 떠있는 칩)
class _AnimalAvatar extends StatelessWidget {
  final Animal animal;
  final WardrobeItem? hat;
  final WardrobeItem? top;
  final WardrobeItem? bottom;
  final WardrobeItem? accessory;
  final double scale;

  const _AnimalAvatar({
    required this.animal,
    required this.hat,
    required this.top,
    required this.bottom,
    required this.accessory,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // ─── 동물별 비율 적용 ───────────────────────────────────
    // s : 전체 크기 배율 (외부 scale × 동물 고유 bodyScale)
    final s = scale * animal.bodyScale;

    // ── AC 스타일 비율: 머리 크고 몸은 작음 ──
    final headFs = 116.0 * animal.headSize * s; // 머리 emoji (크게)
    final torsoW = 72.0 * animal.torsoAspect * s;
    final torsoH = 74.0 * s;
    final legW   = 22.0 * s;
    final legH   = 40.0 * animal.legLengthRatio * s;
    final armW   = 17.0 * s;
    final armH   = 54.0 * s;
    final handD  = 19.0 * s;
    final footW  = 32.0 * s;
    final footH  = 14.0 * s;

    // ── Y 좌표 ──
    // 머리 emoji 박스는 0~headFs. 실제 그림은 약 0.10~0.88 범위.
    // 몸통은 머리 그림 바닥 직후에 시작해서 머리와 살짝만 겹치게.
    final torsoTopY = headFs * 0.78;
    final torsoBotY = torsoTopY + torsoH;
    final legTopY   = torsoBotY - 8 * s;
    final legBotY   = legTopY + legH;
    final feetTopY  = legBotY - 4 * s;

    // ── 전체 위젯 크기 ──
    final totalH = feetTopY + footH + 4 * s;
    final totalW = math.max(180.0 * s, torsoW + armW * 2.6 + 16.0 * s);
    final cx = totalW / 2;

    // ── X 좌표 ──
    final legGap = math.max(2.0 * s, torsoW * 0.08);
    final leftLegX  = cx - legW - legGap / 2;
    final rightLegX = cx + legGap / 2;
    final leftFootX  = leftLegX  - (footW - legW) / 2;
    final rightFootX = rightLegX - (footW - legW) / 2;

    // 어깨 — 토르소 측면 살짝 안쪽
    final shoulderInsetX = 4 * s;
    final leftShoulderX  = cx - torsoW / 2 + shoulderInsetX;
    final rightShoulderX = cx + torsoW / 2 - shoulderInsetX;
    final leftArmX  = leftShoulderX  - armW / 2;
    final rightArmX = rightShoulderX - armW / 2;
    final armTopY   = torsoTopY + 10 * s;
    final handTopY  = armTopY + armH - 8 * s;
    final leftHandX  = leftArmX  + 5 * s;
    final rightHandX = rightArmX + armW - handD - 5 * s;

    // ── 모자·소품 크기 ──
    final hatFs = headFs * 0.58;
    final accFs = headFs * 0.26;

    // ── 동물 색상 ──
    final fur = animal.furColor;
    final belly = animal.bellyColor ?? animal.furColor;
    final stroke = animal.furAccent.withOpacity(0.65);
    final strokeW = 1.5 * s;

    // ── 옷 색상 (카테고리 톤) ──
    final topTone = top != null ? _clothingTone(top!) : null;
    final bottomTone = bottom != null ? _clothingTone(bottom!) : null;
    // 팔: 상의 있으면 위 55%를 상의 색으로 (반팔 길이)
    final sleeveColor = topTone?.fill;
    const sleeveRatio = 0.55;
    // 다리: 하의 있으면 위 65%를 하의 색으로 (반바지~7부)
    final pantsColor = bottomTone?.fill;
    const pantsRatio = 0.65;

    return SizedBox(
      width: totalW,
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. 바닥 그림자 ────────────────────────────────
          Positioned(
            top: feetTopY + footH - 2 * s,
            left: cx - (footW + legGap / 2) * 0.95,
            width: (footW + legGap / 2) * 1.9,
            height: 9 * s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.13),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // ── 2. 다리 (좌/우) ───────────────────────────────
          Positioned(
            top: legTopY,
            left: leftLegX,
            child: _BodyPart(
              width: legW, height: legH,
              color: fur,
              upperColor: pantsColor,
              upperRatio: pantsColor != null ? pantsRatio : 0.0,
              borderColor: stroke, borderWidth: strokeW,
              topRadius: legW * 0.42,
              bottomRadius: legW * 0.5,
            ),
          ),
          Positioned(
            top: legTopY,
            left: rightLegX,
            child: _BodyPart(
              width: legW, height: legH,
              color: fur,
              upperColor: pantsColor,
              upperRatio: pantsColor != null ? pantsRatio : 0.0,
              borderColor: stroke, borderWidth: strokeW,
              topRadius: legW * 0.42,
              bottomRadius: legW * 0.5,
            ),
          ),

          // ── 3. 발 ──────────────────────────────────────────
          Positioned(
            top: feetTopY,
            left: leftFootX,
            child: _Paw(
              width: footW, height: footH,
              color: fur, borderColor: stroke, borderWidth: strokeW,
            ),
          ),
          Positioned(
            top: feetTopY,
            left: rightFootX,
            child: _Paw(
              width: footW, height: footH,
              color: fur, borderColor: stroke, borderWidth: strokeW,
            ),
          ),

          // ── 4. 팔 (어깨에서 손까지, 바깥으로 살짝 회전) ────
          Positioned(
            top: armTopY,
            left: leftArmX,
            child: Transform.rotate(
              angle: 0.18, // CW: 손 끝이 안쪽으로 (resting pose)
              alignment: Alignment.topCenter,
              child: _BodyPart(
                width: armW, height: armH,
                color: fur,
                upperColor: sleeveColor,
                upperRatio: sleeveColor != null ? sleeveRatio : 0.0,
                borderColor: stroke, borderWidth: strokeW,
                topRadius: armW * 0.5,
                bottomRadius: armW * 0.5,
              ),
            ),
          ),
          Positioned(
            top: armTopY,
            left: rightArmX,
            child: Transform.rotate(
              angle: -0.18,
              alignment: Alignment.topCenter,
              child: _BodyPart(
                width: armW, height: armH,
                color: fur,
                upperColor: sleeveColor,
                upperRatio: sleeveColor != null ? sleeveRatio : 0.0,
                borderColor: stroke, borderWidth: strokeW,
                topRadius: armW * 0.5,
                bottomRadius: armW * 0.5,
              ),
            ),
          ),

          // ── 5. 손 (팔 끝, 둥근 원) ────────────────────────
          Positioned(
            top: handTopY,
            left: leftHandX,
            child: _Paw(
              width: handD, height: handD,
              color: fur, borderColor: stroke, borderWidth: strokeW,
              circle: true,
            ),
          ),
          Positioned(
            top: handTopY,
            left: rightHandX,
            child: _Paw(
              width: handD, height: handD,
              color: fur, borderColor: stroke, borderWidth: strokeW,
              circle: true,
            ),
          ),

          // ── 6. 몸통 — 어깨 넓고 허리 좁은 옹기형, 배 하이라이트 ─
          Positioned(
            top: torsoTopY,
            left: cx - torsoW / 2,
            child: CustomPaint(
              size: Size(torsoW, torsoH),
              painter: _TorsoPainter(
                fill: fur,
                belly: belly,
                stroke: stroke,
                strokeWidth: strokeW,
                shirtFill: topTone?.fill,
                shirtAccent: topTone?.accent.withOpacity(0.7),
              ),
            ),
          ),

          // ── 7. 하의 (다리 위로 입혀짐) ────────────────────
          // 하의는 다리(_BodyPart)에 직접 칠해지므로 여기서는 비움

          // ── 8. 상의 (몸통 위로 입혀짐, 토르소 폭에 맞게) ───
          // 상의는 _TorsoPainter 내부에 V넥 셔츠로 통합 렌더링되므로 비움

          // ── 9. 동물 머리 ───────────────────────────────────
          Positioned(
            top: 0,
            left: cx - headFs / 2,
            width: headFs,
            height: headFs,
            child: Center(
              child: Text(
                animal.emoji,
                style: TextStyle(fontSize: headFs, height: 1.0),
              ),
            ),
          ),

          // ── 10. 모자 (머리 위로 살짝 겹침) ────────────────
          if (hat != null)
            Positioned(
              top: headFs * 0.02 - hatFs * 0.45,
              left: cx - hatFs / 2,
              width: hatFs,
              height: hatFs,
              child: Center(
                child: Text(
                  hat!.emoji,
                  style: TextStyle(fontSize: hatFs, height: 1.0),
                ),
              ),
            ),

          // ── 11. 소품 (우측 둥근 칩) ───────────────────────
          if (accessory != null)
            Positioned(
              top: handTopY - accFs * 0.15,
              right: -accFs * 0.30,
              child: Container(
                padding: EdgeInsets.all(4 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: animal.furAccent.withOpacity(0.6),
                      width: 1.5 * s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  accessory!.emoji,
                  style: TextStyle(fontSize: accFs, height: 1.0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 둥근 사각형 신체 부위 (팔/다리/몸통 후보 등)
class _BodyPart extends StatelessWidget {
  final double width;
  final double height;
  final Color color;          // 신체 본래 털색 (lower 영역)
  final Color? upperColor;    // 옷 색 (sleeve/pants 영역). null이면 옷 없음
  final double upperRatio;    // 옷이 차지하는 비율 (0.0~1.0). 위에서부터 차오름
  final Color borderColor;
  final double borderWidth;
  final double topRadius;
  final double bottomRadius;
  const _BodyPart({
    required this.width,
    required this.height,
    required this.color,
    this.upperColor,
    this.upperRatio = 0.0,
    required this.borderColor,
    required this.borderWidth,
    required this.topRadius,
    required this.bottomRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _BodyPartPainter(
        color: color,
        upperColor: upperColor,
        upperRatio: upperRatio,
        borderColor: borderColor,
        borderWidth: borderWidth,
        topRadius: topRadius,
        bottomRadius: bottomRadius,
      ),
    );
  }
}

/// 신체 부위(팔/다리)를 한 번에 칠하는 painter.
/// upperColor가 지정되면 위쪽 upperRatio 만큼을 옷 색으로 덮어서 sleeve/pants 효과.
class _BodyPartPainter extends CustomPainter {
  final Color color;
  final Color? upperColor;
  final double upperRatio;
  final Color borderColor;
  final double borderWidth;
  final double topRadius;
  final double bottomRadius;
  _BodyPartPainter({
    required this.color,
    required this.upperColor,
    required this.upperRatio,
    required this.borderColor,
    required this.borderWidth,
    required this.topRadius,
    required this.bottomRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outer = Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, w, h),
        topLeft: Radius.circular(topRadius),
        topRight: Radius.circular(topRadius),
        bottomLeft: Radius.circular(bottomRadius),
        bottomRight: Radius.circular(bottomRadius),
      ));

    // 1) lower 영역(털) 채우기
    canvas.drawPath(outer, Paint()..color = color);

    // 2) upper 영역(옷) — outer로 clip 한 채 위에서부터 비율 만큼 채움
    if (upperColor != null && upperRatio > 0) {
      canvas.save();
      canvas.clipPath(outer);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * upperRatio),
        Paint()..color = upperColor!,
      );
      canvas.restore();
    }

    // 3) 윤곽선
    canvas.drawPath(
      outer,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPartPainter old) =>
      old.color != color ||
      old.upperColor != upperColor ||
      old.upperRatio != upperRatio ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.topRadius != topRadius ||
      old.bottomRadius != bottomRadius;
}

/// 손/발바닥 — oval 또는 원
class _Paw extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool circle;
  const _Paw({
    required this.width,
    required this.height,
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            circle ? null : BorderRadius.circular(width / 2),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
    );
  }
}

/// 어깨가 넓고 허리가 약간 좁은 몸통 — CustomPainter로 부드러운 곡선 실루엣.
/// 셔츠(top)가 지정되면 몸통 영역에 V넥 셔츠 모양으로 옷 색을 채워 넣음.
/// 배 부분에 더 밝은 톤(belly)을 oval로 깔아서 입체감을 살림.
class _TorsoPainter extends CustomPainter {
  final Color fill;          // 털색
  final Color belly;         // 배(밝은 톤)
  final Color stroke;        // 윤곽선
  final double strokeWidth;
  final Color? shirtFill;    // 셔츠 본 색 (null이면 옷 없음)
  final Color? shirtAccent;  // 셔츠 네크라인 강조
  _TorsoPainter({
    required this.fill,
    required this.belly,
    required this.stroke,
    required this.strokeWidth,
    this.shirtFill,
    this.shirtAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 옹기형 몸통 (어깨 넓고 허리 좁음) ──
    final shoulderInset = w * 0.05;
    final waistInset = w * 0.16;

    final outerPath = Path()
      ..moveTo(shoulderInset, h * 0.10)
      ..quadraticBezierTo(w * 0.50, -h * 0.05, w - shoulderInset, h * 0.10)
      ..quadraticBezierTo(
          w - shoulderInset * 0.5, h * 0.55, w - waistInset, h * 0.95)
      ..quadraticBezierTo(w * 0.50, h * 1.06, waistInset, h * 0.95)
      ..quadraticBezierTo(
          shoulderInset * 0.5, h * 0.55, shoulderInset, h * 0.10)
      ..close();

    final fillPaint = Paint()..color = fill;
    final bellyPaint = Paint()..color = belly;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    // 1) 털 채우기
    canvas.drawPath(outerPath, fillPaint);

    // 2) 배 하이라이트 (몸통 안쪽 oval)
    final bellyRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.62),
      width: w * 0.62,
      height: h * 0.62,
    );
    canvas.save();
    canvas.clipPath(outerPath);
    canvas.drawOval(bellyRect, bellyPaint);
    canvas.restore();

    // 3) 셔츠 — 몸통 outer 안쪽에 V넥 절개로 그림
    if (shirtFill != null) {
      final neckWidth = w * 0.30;
      final neckDepth = h * 0.26; // V넥 깊이

      // 셔츠 경로 = 몸통 외곽 - V넥 컷
      final shirtPath = Path()
        // 좌측 어깨 시작
        ..moveTo(shoulderInset, h * 0.10)
        // 윗변 (목 좌측까지)
        ..lineTo(w * 0.50 - neckWidth / 2, h * 0.10)
        // V넥 컷 — 가운데로 깊이 들어갔다가 다시 올라옴
        ..quadraticBezierTo(
            w * 0.50, neckDepth, w * 0.50 + neckWidth / 2, h * 0.10)
        // 우측 어깨까지 윗변
        ..lineTo(w - shoulderInset, h * 0.10)
        // 우측 옆선 (몸통과 동일)
        ..quadraticBezierTo(
            w - shoulderInset * 0.5, h * 0.55, w - waistInset, h * 0.95)
        // 하단 변
        ..quadraticBezierTo(w * 0.50, h * 1.06, waistInset, h * 0.95)
        // 좌측 옆선
        ..quadraticBezierTo(
            shoulderInset * 0.5, h * 0.55, shoulderInset, h * 0.10)
        ..close();

      canvas.save();
      canvas.clipPath(outerPath);
      canvas.drawPath(shirtPath, Paint()..color = shirtFill!);
      // 네크라인 강조 — V컷 따라 살짝 더 진한 선
      if (shirtAccent != null) {
        final neckLine = Path()
          ..moveTo(w * 0.50 - neckWidth / 2, h * 0.10)
          ..quadraticBezierTo(
              w * 0.50, neckDepth, w * 0.50 + neckWidth / 2, h * 0.10);
        canvas.drawPath(
          neckLine,
          Paint()
            ..color = shirtAccent!
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth * 1.2
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }

    // 4) 몸통 윤곽선 (가장 마지막)
    canvas.drawPath(outerPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TorsoPainter old) =>
      old.fill != fill ||
      old.belly != belly ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.shirtFill != shirtFill ||
      old.shirtAccent != shirtAccent;
}

// (옛 _ShirtPatch / _PantsPatch는 _TorsoPainter / _BodyPart에 통합되어 삭제됨)
// ══════════════════════════════════════════════════════════════════════════════
//                       (제거됨) 옷 패치 — 상의 / 하의
// ══════════════════════════════════════════════════════════════════════════════
/// 상의 패치 — 어깨에서 허리까지 fit되는 셔츠 모양 + 작은 emoji 아이콘.
/// emoji가 둥둥 떠다니지 않게 카테고리 컬러로 몸에 실제로 입혀진 형태로 렌더링.
class _ShirtPatch extends StatelessWidget {
  final double centerX;
  final double topY;
  final double width;
  final double height;
  final ({Color fill, Color accent}) tone;
  final String emoji;
  final double strokeW;
  const _ShirtPatch({
    required this.centerX,
    required this.topY,
    required this.width,
    required this.height,
    required this.tone,
    required this.emoji,
    required this.strokeW,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topY,
      left: centerX - width / 2,
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _ShirtPainter(
              fill: tone.fill,
              stroke: tone.accent.withOpacity(0.75),
              strokeWidth: strokeW,
            ),
          ),
          // 옷 식별용 작은 emoji 아이콘
          Text(emoji,
              style: TextStyle(fontSize: width * 0.42, height: 1.0)),
        ],
      ),
    );
  }
}

class _ShirtPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  _ShirtPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shoulderInset = w * 0.04;
    final neckWidth = w * 0.28;
    final neckDepth = h * 0.20;

    final path = Path()
      // 좌측 어깨
      ..moveTo(shoulderInset, h * 0.10)
      // 어깨선 → 목 좌측
      ..lineTo(w * 0.50 - neckWidth / 2, h * 0.10)
      // V넥 컷
      ..quadraticBezierTo(
          w * 0.50, neckDepth, w * 0.50 + neckWidth / 2, h * 0.10)
      // 어깨선 → 우측 어깨
      ..lineTo(w - shoulderInset, h * 0.10)
      // 우측 옆선 (어깨 → 허리, 살짝 펴짐)
      ..quadraticBezierTo(w * 1.02, h * 0.55, w * 0.92, h * 0.97)
      // 밑단 (둥근)
      ..quadraticBezierTo(w * 0.50, h * 1.06, w * 0.08, h * 0.97)
      // 좌측 옆선
      ..quadraticBezierTo(-w * 0.02, h * 0.55, shoulderInset, h * 0.10)
      ..close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ShirtPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth;
}

/// 하의 패치 — 두 다리에 fit되는 반바지/팬츠 형태 + 작은 emoji 아이콘.
class _PantsPatch extends StatelessWidget {
  final double centerX;
  final double topY;
  final double width;
  final double height;
  final double legGap;
  final ({Color fill, Color accent}) tone;
  final String emoji;
  final double strokeW;
  const _PantsPatch({
    required this.centerX,
    required this.topY,
    required this.width,
    required this.height,
    required this.legGap,
    required this.tone,
    required this.emoji,
    required this.strokeW,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: topY,
      left: centerX - width / 2,
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: _PantsPainter(
              fill: tone.fill,
              stroke: tone.accent.withOpacity(0.75),
              strokeWidth: strokeW,
              legGap: legGap,
            ),
          ),
          // 옷 식별용 작은 emoji 아이콘 (윗쪽 가까이)
          Align(
            alignment: const Alignment(0, -0.45),
            child: Text(emoji,
                style: TextStyle(fontSize: width * 0.34, height: 1.0)),
          ),
        ],
      ),
    );
  }
}

class _PantsPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final double legGap;
  _PantsPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.legGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // 가랑이 폭은 다리 간격에 비례
    final crotchHalf = (legGap / w).clamp(0.05, 0.18) * w / 2;

    final path = Path()
      // 좌상 (허리 좌측)
      ..moveTo(w * 0.05, h * 0.12)
      // 허리 윗변
      ..quadraticBezierTo(w * 0.50, -h * 0.06, w * 0.95, h * 0.12)
      // 우측 옆선
      ..lineTo(w * 0.92, h * 0.92)
      // 우측 다리 바닥 바깥쪽
      ..quadraticBezierTo(w * 0.88, h * 1.02, w * 0.72, h * 1.00)
      // 우측 다리 안쪽 (가랑이로 올라감)
      ..lineTo(w * 0.50 + crotchHalf, h * 0.96)
      // 가랑이 V (위로 들어감)
      ..quadraticBezierTo(
          w * 0.50, h * 0.55, w * 0.50 - crotchHalf, h * 0.96)
      // 좌측 다리 안쪽
      ..lineTo(w * 0.28, h * 1.00)
      // 좌측 다리 바닥 바깥쪽
      ..quadraticBezierTo(w * 0.12, h * 1.02, w * 0.08, h * 0.92)
      // 좌측 옆선 → 시작점으로
      ..close();

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PantsPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.legGap != legGap;
}

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
//                          진행도 미니 바
// ══════════════════════════════════════════════════════════════════════════════
class _MiniProgress extends StatelessWidget {
  final String label;
  final String emoji;
  final double ratio;
  const _MiniProgress({
    required this.label,
    required this.emoji,
    required this.ratio,
  });

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
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${(ratio * 100).round()}%',
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                const AlwaysStoppedAnimation(Color(0xFF7F77DD)),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//                              캐릭터 편집 탭
// ══════════════════════════════════════════════════════════════════════════════
class _CharacterEditTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _CharacterEditTab({required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('밖에서 어떤 사람인지',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F77DD),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('요리·운동·여행·만남·창작 경험이 캐릭터에 쌓여요',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 18),

          for (final slot in characterSlots) ...[
            _SlotItemRow(
              slotLabel: characterSlotLabels[slot]!,
              equippedId: state.characterEquipped[slot],
              items: allWardrobeItems
                  .where((it) =>
                      it.dimension == SelfDimension.external &&
                      it.slot == slot &&
                      state.wardrobeUnlocked.contains(it.id))
                  .toList(),
              onTap: (id) {
                final current = state.characterEquipped[slot];
                state.equipCharacter(slot, current == id ? null : id);
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
          const Text('내면이 어떤지',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7F77DD),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('독서·명상·취미·음악·자연 경험이 방에 쌓여요',
              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 18),

          for (final slot in roomSlots) ...[
            _SlotItemRow(
              slotLabel: roomSlotLabels[slot]!,
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
//                            슬롯별 아이템 가로 행 (공유)
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
        Row(
          children: [
            Text(slotLabel,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            Text('· ${items.length}개',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            const Spacer(),
            if (equippedId != null)
              Text('탭하면 해제',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: items.isEmpty
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '아직 잠금 해제된 아이템이 없어요 — 상점에서 어떤 경험으로 얻는지 확인해보세요',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                      child: Container(
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
//                                  상점 탭
// ══════════════════════════════════════════════════════════════════════════════
class _ShopTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const _ShopTab({required this.onUpdate});

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  SelfDimension _dimension = SelfDimension.external;
  ExperienceCategory? _categoryFilter; // null이면 전체

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;

    final visible = allWardrobeItems.where((it) {
      if (it.dimension != _dimension) return false;
      if (_categoryFilter != null && it.category != _categoryFilter) {
        return false;
      }
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
              _categoryFilter = null;
            }),
          ),

          const SizedBox(height: 18),

          // 카테고리 칩
          Text(
            _dimension == SelfDimension.external
                ? '어떤 경험으로 캐릭터 아이템을 얻을지 골라보세요'
                : '어떤 경험으로 방 아이템을 얻을지 골라보세요',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: '전체',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 6),
                for (final c in cats) ...[
                  _CategoryChip(
                    label: '${c.emoji} ${c.label}',
                    selected: _categoryFilter == c,
                    onTap: () => setState(() => _categoryFilter = c),
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
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final item = visible[i];
                final isUnlocked = state.wardrobeUnlocked.contains(item.id);
                final canAfford = state.points >= item.cost;
                return _ShopCard(
                  item: item,
                  isUnlocked: isUnlocked,
                  canAfford: canAfford,
                  onBuy: () {
                    if (isUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '이미 가지고 있어요 — ${item.dimension.label} 탭에서 장착해보세요'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      return;
                    }
                    if (state.buyWardrobe(item)) {
                      setState(() {});
                      widget.onUpdate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${item.emoji} ${item.name} 획득! ${item.dimension.label}에서 꾸며보세요'),
                          backgroundColor: const Color(0xFF7F77DD),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              '포인트가 부족해요. 경험을 더 완료해봐요!'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
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
                    color: value == d ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: value == d
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
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
                    ],
                  ),
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
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
              color: selected ? const Color(0xFF7F77DD) : Colors.grey.shade200),
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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_slotLabel,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(item.unlockHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500, height: 1.3)),
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
