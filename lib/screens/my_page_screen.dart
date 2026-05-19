import 'package:flutter/material.dart';
import '../models/models.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
      body: SafeArea(
        child: Column(
          children: [
            // ── 프로필 헤더 ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  // 아바타
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEEEDFE),
                    ),
                    child: const Center(
                        child: Text('🧭',
                            style: TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('탐험가 Lv.${state.level}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('총 ${state.completedIds.length}개 경험 완료',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                  const Spacer(),
                  // 포인트 표시
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDFE),
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

            // ── 탭 바 ──────────────────────────────────────────────────
            TabBar(
              controller: _tab,
              tabs: const [Tab(text: '내 공간'), Tab(text: '아이템 상점')],
              indicatorColor: const Color(0xFF7F77DD),
              labelColor: const Color(0xFF7F77DD),
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 2,
            ),

            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _MySpaceTab(onUpdate: () => setState(() {})),
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

// ═══════════════════════════ 내 공간 탭 ══════════════════════════════════════
class _MySpaceTab extends StatelessWidget {
  final VoidCallback onUpdate;
  const _MySpaceTab({required this.onUpdate});

  DecoItem? _find(String? id) {
    if (id == null) return null;
    try {
      return allItems.firstWhere((it) => it.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final bg = _find(state.equipped['background']);
    final s1 = _find(state.equipped['slot1']);
    final s2 = _find(state.equipped['slot2']);
    final s3 = _find(state.equipped['slot3']);
    final badge = _find(state.equipped['badge']);

    final unlockedBgs = allItems
        .where((it) =>
    it.slot == 'background' && state.unlockedIds.contains(it.id))
        .toList();
    final unlockedObjs = allItems
        .where((it) =>
    it.slot == 'object' && state.unlockedIds.contains(it.id))
        .toList();
    final unlockedBadges = allItems
        .where((it) =>
    it.slot == 'badge' && state.unlockedIds.contains(it.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 공간 미리보기 ──────────────────────────────────────────
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Stack(
              children: [
                // 배경 이모지 (크게)
                if (bg != null)
                  Positioned.fill(
                    child: Center(
                      child: Text(bg.emoji,
                          style: const TextStyle(fontSize: 90)),
                    ),
                  ),
                // 뱃지 — 우상단
                if (badge != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(badge.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(badge.name,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                // 오브젝트 슬롯 3개 — 하단
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _SlotBox(item: s1),
                      _SlotBox(item: s2),
                      _SlotBox(item: s3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 배경 선택 ─────────────────────────────────────────────
          const Text('배경',
              style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _HorizontalItemRow(
            items: unlockedBgs,
            equippedId: state.equipped['background'],
            onEquip: (id) {
              state.equip('background', id);
              onUpdate();
            },
          ),

          const SizedBox(height: 20),

          // ── 오브젝트 선택 ─────────────────────────────────────────
          const Text('오브젝트',
              style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('탭하면 빈 슬롯에 순서대로 배치돼요',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          _HorizontalItemRow(
            items: unlockedObjs,
            equippedId: state.equipped['slot1'],
            onEquip: (id) {
              // 빈 슬롯에 순차 배치, 꽉 차면 slot1부터 교체
              if (state.equipped['slot1'] == null) {
                state.equip('slot1', id);
              } else if (state.equipped['slot2'] == null) {
                state.equip('slot2', id);
              } else if (state.equipped['slot3'] == null) {
                state.equip('slot3', id);
              } else {
                state.equip('slot1', id);
              }
              onUpdate();
            },
          ),

          const SizedBox(height: 20),

          // ── 뱃지 선택 ─────────────────────────────────────────────
          const Text('뱃지',
              style:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _HorizontalItemRow(
            items: unlockedBadges,
            equippedId: state.equipped['badge'],
            onEquip: (id) {
              state.equip('badge', id);
              onUpdate();
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── 슬롯 박스 (공간 미리보기용) ─────────────────────────────────────────────
class _SlotBox extends StatelessWidget {
  final DecoItem? item;
  const _SlotBox({this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: item != null
            ? Text(item!.emoji, style: const TextStyle(fontSize: 30))
            : Icon(Icons.add, color: Colors.grey.shade300, size: 22),
      ),
    );
  }
}

// ── 가로 스크롤 아이템 행 ────────────────────────────────────────────────────
class _HorizontalItemRow extends StatelessWidget {
  final List<DecoItem> items;
  final String? equippedId;
  final void Function(String) onEquip;

  const _HorizontalItemRow(
      {required this.items,
        required this.equippedId,
        required this.onEquip});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text('잠금 해제된 아이템이 없어요. 상점에서 구매해봐요!',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isEquipped = equippedId == item.id;
          return GestureDetector(
            onTap: () => onEquip(item.id),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEquipped
                    ? const Color(0xFFEEEDFE)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isEquipped
                      ? const Color(0xFF7F77DD)
                      : Colors.grey.shade200,
                  width: isEquipped ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(item.emoji,
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(item.name,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════ 아이템 상점 탭 ═══════════════════════════════════
class _ShopTab extends StatefulWidget {
  final VoidCallback onUpdate;
  const _ShopTab({required this.onUpdate});

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  @override
  Widget build(BuildContext context) {
    final state = AppState.i;
    final locked = allItems
        .where((it) => !state.unlockedIds.contains(it.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 포인트 배너 ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F77DD), Color(0xFF534AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 포인트',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text('${state.points}P',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                const Text('경험 완료로\n포인트를 모아요 →',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.6)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('구매 가능 아이템 (${locked.length}개)',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          if (locked.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Text('🎉', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('모든 아이템을 획득했어요!',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
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
                childAspectRatio: 1.15,
              ),
              itemCount: locked.length,
              itemBuilder: (_, i) {
                final item = locked[i];
                final canAfford = state.points >= item.cost;
                return _ShopCard(
                  item: item,
                  canAfford: canAfford,
                  onBuy: () {
                    if (state.buy(item.id, item.cost)) {
                      setState(() {});
                      widget.onUpdate();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${item.emoji} ${item.name} 획득! 내 공간에서 꾸며봐요'),
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── 상점 아이템 카드 ─────────────────────────────────────────────────────────
class _ShopCard extends StatelessWidget {
  final DecoItem item;
  final bool canAfford;
  final VoidCallback onBuy;

  const _ShopCard(
      {required this.item,
        required this.canAfford,
        required this.onBuy});

  String get _slotLabel => switch (item.slot) {
    'background' => '배경',
    'object'     => '오브젝트',
    _            => '뱃지',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_slotLabel,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Text(item.hint,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade400)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF7F77DD)
                    : Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              onPressed: canAfford ? onBuy : null,
              child: Text(
                '⭐ ${item.cost}P',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: canAfford
                      ? Colors.white
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}