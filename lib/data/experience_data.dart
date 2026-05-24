import '../models/experience.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  경험 데이터 풀 (42개)
//  isFit: true  → 조용하고 익숙한 취향형 경험 (Fit 카드)
//  isFit: false → 낯설고 도전적인 색다른 경험 (Dare 카드)
// ═══════════════════════════════════════════════════════════════════════════

final List<Experience> allExperiences = [

  // ───────────────────────────── 쉬움 · 취향형 ─────────────────────────────
  const Experience(
    id: 'exp_e01', isFit: true,
    title: '동네 대중목욕탕 사우나',
    subtitle: '뜨끈하게 지지고 바나나우유 마시기',
    matchedKeywords: ['혼자', '실내', '따뜻한', '저녁', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e02', isFit: true,
    title: 'SPA 브랜드 과감한 옷 피팅만 해보기',
    subtitle: '평소라면 절대 안 입을 스타일, 피팅만',
    matchedKeywords: ['혼자', '도심', '실내', '처음 해보는'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e03', isFit: true,
    title: '평소와 다른 골목길 루트 걷기',
    subtitle: '안 가본 골목을 따라 출퇴근해보기',
    matchedKeywords: ['혼자', '걷기', '골목', '처음 해보는', '무계획'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e04', isFit: true,
    title: '편의점 신상 간식 시식회 열기',
    subtitle: '수입 맥주 4캔과 신상 간식 종류별로',
    matchedKeywords: ['혼자', '실내', '먹는', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e05', isFit: true,
    title: '나만을 위한 꽃 한 송이 사기',
    subtitle: '꽃집에서 골라 책상 위에 꽂아두기',
    matchedKeywords: ['혼자', '도심', '느린', '따뜻한'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e06', isFit: true,
    title: '밤 동네 무작정 1시간 산책',
    subtitle: '좋아하는 팟캐스트 틀고 골목 누비기',
    matchedKeywords: ['혼자', '걷기', '밤', '골목', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e07', isFit: true,
    title: '스마트폰 앨범 추억 여행',
    subtitle: '깊숙이 묻힌 옛날 사진들 쭉 훑어보기',
    matchedKeywords: ['혼자', '실내', '느린', '조용한'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e08', isFit: true,
    title: '전통시장 호떡+떡볶이 투어',
    subtitle: '갓 구운 호떡과 활기찬 시장 소음 즐기기',
    matchedKeywords: ['낮', '실외', '먹는', '소란스러운', '도심'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e09', isFit: true,
    title: '한강공원 편의점 라면',
    subtitle: '둥둥 짜글이 끓여주는 라면 먹기',
    matchedKeywords: ['공원', '실외', '먹는', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e10', isFit: true,
    title: '아무 버스나 타고 종점까지',
    subtitle: '지도 없이 처음 가는 동네 발견하기',
    matchedKeywords: ['무계획', '처음 해보는', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e11', isFit: true,
    title: '비 오는 날 카페 창가 하루 독서',
    subtitle: '카페 창가에 앉아 하루 종일 책 읽기',
    matchedKeywords: ['혼자', '카페', '실내', '조용한', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e12', isFit: true,
    title: '문구점에서 귀여운 물건 1만원 지름',
    subtitle: '쓸모없지만 귀여운 소품 사기',
    matchedKeywords: ['혼자', '도심', '실내', '느린'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),
  const Experience(
    id: 'exp_e13', isFit: true,
    title: '금요일 밤 영화 시리즈 정주행',
    subtitle: '알람 끄고 암막 커튼 치고 밤새 정주행',
    matchedKeywords: ['혼자', '밤', '실내', '느린', '조용한'],
    difficulty: Difficulty.easy, energy: 1, courage: 1, cost: 1,
  ),

  // ───────────────────────────── 쉬움 · 색다른형 ────────────────────────────
  const Experience(
    id: 'exp_e14', isFit: false,
    title: '코인노래방 목이 쉴 때까지',
    subtitle: '혼자 최애곡 메들리 불러보기',
    matchedKeywords: ['혼자', '실내', '소란스러운', '도전적'],
    difficulty: Difficulty.easy, energy: 2, courage: 2, cost: 1,
  ),

  // ───────────────────────────── 보통 · 취향형 ─────────────────────────────
  const Experience(
    id: 'exp_m01', isFit: true,
    title: '바에 혼자 가서 위스키 한 잔',
    subtitle: '바텐더에게 추천 위스키 주문하고 음미하기',
    matchedKeywords: ['혼자', '저녁', '도심', '처음 해보는', '두근두근'],
    difficulty: Difficulty.medium, energy: 1, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_m02', isFit: true,
    title: '독립영화관 정보 없이 관람',
    subtitle: '포스터만 보고 낯선 예술영화 한 편',
    matchedKeywords: ['혼자', '도심', '실내', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 1, courage: 1, cost: 2,
  ),
  const Experience(
    id: 'exp_m03', isFit: true,
    title: '3코스 요리 스스로에게 대접하기',
    subtitle: '에피타이저·메인·디저트 직접 만들어 차리기',
    matchedKeywords: ['혼자', '실내', '만들기', '따뜻한', '느린'],
    difficulty: Difficulty.medium, energy: 2, courage: 1, cost: 2,
  ),
  const Experience(
    id: 'exp_m04', isFit: true,
    title: '평일 낮 미술관/박물관 혼자 거닐기',
    subtitle: '텅 빈 전시장을 여유롭게 혼자 관람',
    matchedKeywords: ['혼자', '낮', '실내', '도심', '조용한'],
    difficulty: Difficulty.medium, energy: 1, courage: 1, cost: 2,
  ),
  const Experience(
    id: 'exp_m05', isFit: true,
    title: '독립서점 표지만 보고 책 구매',
    subtitle: '오직 표지 디자인만 보고 책이나 LP 고르기',
    matchedKeywords: ['혼자', '도심', '실내', '처음 해보는', '느린'],
    difficulty: Difficulty.medium, energy: 1, courage: 1, cost: 2,
  ),

  // ───────────────────────────── 보통 · 색다른형 ────────────────────────────
  const Experience(
    id: 'exp_m06', isFit: false,
    title: '새벽 수산시장/번개시장 구경',
    subtitle: '새벽 5시 시장의 활기찬 아침 활력 만끽',
    matchedKeywords: ['새벽', '소란스러운', '실외', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 2, courage: 2, cost: 1,
  ),
  const Experience(
    id: 'exp_m07', isFit: false,
    title: '스케이트보드/롱보드 배우기',
    subtitle: '사서 중심 잡기부터 차근차근 연습',
    matchedKeywords: ['혼자', '실외', '몸쓰는', '배우기', '도전적'],
    difficulty: Difficulty.medium, energy: 3, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_m08', isFit: false,
    title: '숏폼 댄스 한 구간 마스터하기',
    subtitle: '유튜브 영상 보고 안무 완벽하게 따라하기',
    matchedKeywords: ['혼자', '실내', '배우기', '도전적', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 2, courage: 2, cost: 1,
  ),
  const Experience(
    id: 'exp_m09', isFit: false,
    title: '혼자 고깃집에서 혼밥하기',
    subtitle: '패밀리 레스토랑 당당하게 혼자 입장',
    matchedKeywords: ['혼자', '저녁', '도심', '먹는', '두근두근'],
    difficulty: Difficulty.medium, energy: 1, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_m10', isFit: false,
    title: '주말 24시간 디지털 디톡스',
    subtitle: '스마트폰과 인터넷 완전히 끄고 지내기',
    matchedKeywords: ['혼자', '도전적', '느린', '조용한'],
    difficulty: Difficulty.medium, energy: 1, courage: 3, cost: 1,
  ),
  const Experience(
    id: 'exp_m11', isFit: false,
    title: '새벽 기차 타고 정동진 일출',
    subtitle: '밤샘 기차로 무작정 정동진으로',
    matchedKeywords: ['새벽', '실외', '처음 해보는', '두근두근'],
    difficulty: Difficulty.medium, energy: 2, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_m12', isFit: false,
    title: '산사 템플스테이 1박 2일',
    subtitle: '조용한 산사에서 새벽 예불 드려보기',
    matchedKeywords: ['산', '조용한', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 1, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_m13', isFit: false,
    title: '한옥 게스트하우스 여행자와 대화',
    subtitle: '모르는 여행자들과 밤새 도란도란',
    matchedKeywords: ['낯선 사람', '함께', '밤', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 1, courage: 3, cost: 2,
  ),
  const Experience(
    id: 'exp_m14', isFit: false,
    title: '도자기/가죽 원데이 클래스',
    subtitle: '처음 만나는 사람들과 함께 만들기',
    matchedKeywords: ['함께', '실내', '만들기', '배우기', '처음 해보는'],
    difficulty: Difficulty.medium, energy: 2, courage: 2, cost: 2,
  ),

  // ───────────────────────────── 어려움 · 취향형 ────────────────────────────
  const Experience(
    id: 'exp_h01', isFit: true,
    title: '단편소설/에세이 A4 3장 창작',
    subtitle: '내 이야기를 글로 완성해보기',
    matchedKeywords: ['혼자', '실내', '조용한', '느린', '만들기'],
    difficulty: Difficulty.hard, energy: 2, courage: 2, cost: 1,
  ),

  // ───────────────────────────── 어려움 · 색다른형 ──────────────────────────
  const Experience(
    id: 'exp_h02', isFit: false,
    title: '야간/새벽 산행',
    subtitle: '랜턴 하나에 의지해 산에 올라 야경 보기',
    matchedKeywords: ['새벽', '산', '실외', '몸쓰는', '도전적', '두근두근'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 1,
  ),
  const Experience(
    id: 'exp_h03', isFit: false,
    title: '클라이밍 센터 최고 난이도 깨기',
    subtitle: '손에 굳은살이 박이도록 어려운 코스 도전',
    matchedKeywords: ['혼자', '실내', '몸쓰는', '도전적', '처음 해보는'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_h04', isFit: false,
    title: '콘서트/페스티벌 밤새 뛰기',
    subtitle: '좋아하는 아티스트와 목이 터져라 떼창',
    matchedKeywords: ['함께', '밤', '소란스러운', '도전적', '두근두근'],
    difficulty: Difficulty.hard, energy: 3, courage: 1, cost: 3,
  ),
  const Experience(
    id: 'exp_h05', isFit: false,
    title: '바디프로필/컨셉 프로필 촬영',
    subtitle: '전문 스튜디오에서 나의 가장 멋진 순간 남기기',
    matchedKeywords: ['혼자', '도전적', '처음 해보는', '두근두근'],
    difficulty: Difficulty.hard, energy: 3, courage: 3, cost: 3,
  ),
  const Experience(
    id: 'exp_h06', isFit: false,
    title: '서핑 도전 (양양/부산)',
    subtitle: '보드 위에서 파도 서핑 성공하기',
    matchedKeywords: ['바닷가', '실외', '몸쓰는', '도전적', '처음 해보는'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 3,
  ),
  const Experience(
    id: 'exp_h07', isFit: false,
    title: '일주일 자연식/생식 챌린지',
    subtitle: '가공식품과 배달 완전히 끊고 자연식으로',
    matchedKeywords: ['혼자', '도전적', '느린'],
    difficulty: Difficulty.hard, energy: 2, courage: 3, cost: 2,
  ),
  const Experience(
    id: 'exp_h08', isFit: false,
    title: '패러글라이딩',
    subtitle: '높은 활공장에서 바람 타고 날아오르기',
    matchedKeywords: ['실외', '몸쓰는', '도전적', '두근두근', '처음 해보는'],
    difficulty: Difficulty.hard, energy: 2, courage: 3, cost: 3,
  ),
  const Experience(
    id: 'exp_h09', isFit: false,
    title: '번지점프',
    subtitle: '카운트다운에 맞춰 망설임 없이 뛰어내리기',
    matchedKeywords: ['실외', '도전적', '두근두근', '처음 해보는', '몸쓰는'],
    difficulty: Difficulty.hard, energy: 1, courage: 3, cost: 2,
  ),
  const Experience(
    id: 'exp_h10', isFit: false,
    title: '한라산/지리산 정상 완등',
    subtitle: '내 발로 백록담·천왕봉 정상까지',
    matchedKeywords: ['산', '실외', '몸쓰는', '도전적', '처음 해보는'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 2,
  ),
  const Experience(
    id: 'exp_h11', isFit: false,
    title: '아는 사람 없는 도시 보름 살기',
    subtitle: '연고 없는 국내 도시에서 홀로 보름 살아보기',
    matchedKeywords: ['혼자', '무계획', '처음 해보는', '도전적'],
    difficulty: Difficulty.hard, energy: 2, courage: 3, cost: 3,
  ),
  const Experience(
    id: 'exp_h12', isFit: false,
    title: '버스킹/작은 무대 공연',
    subtitle: '몇 달 연습 후 관객 앞에서 공연해보기',
    matchedKeywords: ['소란스러운', '함께', '도전적', '두근두근', '처음 해보는'],
    difficulty: Difficulty.hard, energy: 2, courage: 3, cost: 2,
  ),
  const Experience(
    id: 'exp_h13', isFit: false,
    title: '스쿠버다이빙 오픈워터 자격증',
    subtitle: '깊은 바닷속 세계 탐험하기',
    matchedKeywords: ['바닷가', '실외', '몸쓰는', '배우기', '처음 해보는', '도전적'],
    difficulty: Difficulty.hard, energy: 3, courage: 2, cost: 3,
  ),
  const Experience(
    id: 'exp_h14', isFit: false,
    title: '아마추어 연극 극단 참여',
    subtitle: '관객들 앞에서 직접 연기해보기',
    matchedKeywords: ['함께', '낯선 사람', '도전적', '처음 해보는', '두근두근'],
    difficulty: Difficulty.hard, energy: 2, courage: 3, cost: 1,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  주간 추천 엔진
//  - 같은 주(week)에는 항상 동일한 결과 반환
//  - 미완료 경험 우선 → 키워드 겹침 점수 → 주차 시드 타이브레이크
// ═══════════════════════════════════════════════════════════════════════════

/// 이번 주 추천 경험 쌍을 반환합니다.
///
/// [preferredKeywords]: 사용자가 선택한 키워드 레이블 목록
/// [completedIds]     : 이미 완료한 경험 ID Set
///
/// Fit  = 키워드 겹침이 가장 많은 경험 (내 취향에 맞는)
/// Dare = 키워드 겹침이 가장 적은 경험 (완전히 다른)
(Experience fitExp, Experience dareExp) getWeeklyPair({
  required List<String> preferredKeywords,
  required Set<String> completedIds,
}) {
  final now = DateTime.now();
  final weekNum = now.difference(DateTime(now.year, 1, 1)).inDays ~/ 7;
  final weekSeed = now.year * 100 + weekNum;

  // 키워드 겹침 점수
  int overlap(Experience e) => preferredKeywords.isEmpty
      ? 0
      : e.matchedKeywords.where(preferredKeywords.contains).length;

  // 주차 시드 기반 타이브레이크 (같은 주엔 순서 고정)
  int seeded(Experience e) => e.id.hashCode ^ weekSeed;

  // Fit 풀: isFit=true → 미완료 우선, 겹침 높은 것 우선
  final fits = allExperiences.where((e) => e.isFit).toList()
    ..sort((a, b) {
      final aD = completedIds.contains(a.id) ? 1 : 0;
      final bD = completedIds.contains(b.id) ? 1 : 0;
      if (aD != bD) return aD - bD;
      final s = overlap(b) - overlap(a);
      return s != 0 ? s : seeded(a).compareTo(seeded(b));
    });

  // Dare 풀: isFit=false → 미완료 우선, 겹침 낮은 것 우선 (가장 다른 경험)
  final dares = allExperiences.where((e) => !e.isFit).toList()
    ..sort((a, b) {
      final aD = completedIds.contains(a.id) ? 1 : 0;
      final bD = completedIds.contains(b.id) ? 1 : 0;
      if (aD != bD) return aD - bD;
      final s = overlap(a) - overlap(b); // 낮은 겹침 우선 (reversed)
      return s != 0 ? s : seeded(a).compareTo(seeded(b));
    });

  return (fits.first, dares.first);
}

/// 현재 주차 번호 (1년 기준)
int get currentWeekNum {
  final now = DateTime.now();
  return now.difference(DateTime(now.year, 1, 1)).inDays ~/ 7 + 1;
}
