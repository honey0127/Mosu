import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kUsers        = 'auth_users';
  static const _kProfiles     = 'auth_profiles';
  static const _kOnboarding   = 'auth_onboarding_done';
  static const _kJoinDates    = 'auth_join_dates';
  static const _kKeywordsDone = 'auth_keywords_done';
  static const _kUserKeywords = 'auth_user_keywords';

  static final Map<String, Map<String, String>> _users = {};
  static final Map<String, UserProfile> _userProfiles = {};
  static final Set<String> _onboardingDone = {};
  static final Map<String, DateTime> _joinDates = {};
  static final Set<String> _keywordsDone = {};
  static final Map<String, List<String>> _userKeywords = {};

  static String? _currentUserId;
  static String? get currentUserId => _currentUserId;

  /// 앱 시작 시 한 번 호출 — SharedPreferences에서 데이터 로드
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 사용자 계정
    final usersJson = prefs.getString(_kUsers);
    if (usersJson != null) {
      final Map<String, dynamic> raw = jsonDecode(usersJson);
      raw.forEach((id, val) {
        _users[id] = Map<String, String>.from(val as Map);
      });
    }

    // 프로필
    final profilesJson = prefs.getString(_kProfiles);
    if (profilesJson != null) {
      final Map<String, dynamic> raw = jsonDecode(profilesJson);
      raw.forEach((id, val) {
        final m = val as Map<String, dynamic>;
        _userProfiles[id] = UserProfile(
          age:     m['age'] as int,
          mbti:    m['mbti'] as String,
          job:     m['job'] as String,
          hobbies: List<String>.from(m['hobbies'] as List),
        );
      });
    }

    // 온보딩 완료 목록
    final onboardingJson = prefs.getString(_kOnboarding);
    if (onboardingJson != null) {
      _onboardingDone.addAll(List<String>.from(jsonDecode(onboardingJson)));
    }

    // 가입일
    final joinJson = prefs.getString(_kJoinDates);
    if (joinJson != null) {
      final Map<String, dynamic> raw = jsonDecode(joinJson);
      raw.forEach((id, val) {
        _joinDates[id] = DateTime.parse(val as String);
      });
    }

    // 키워드 선택 완료 목록
    final kwDoneJson = prefs.getString(_kKeywordsDone);
    if (kwDoneJson != null) {
      _keywordsDone.addAll(List<String>.from(jsonDecode(kwDoneJson)));
    }

    // 유저별 선택 키워드
    final kwJson = prefs.getString(_kUserKeywords);
    if (kwJson != null) {
      final Map<String, dynamic> raw = jsonDecode(kwJson);
      raw.forEach((id, val) {
        _userKeywords[id] = List<String>.from(val as List);
      });
    }
  }

  // ── 저장 헬퍼 ─────────────────────────────────────────────────────────────

  static Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsers, jsonEncode(_users));
  }

  static Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _userProfiles.map((id, p) => MapEntry(id, {
      'age': p.age,
      'mbti': p.mbti,
      'job': p.job,
      'hobbies': p.hobbies,
    }));
    await prefs.setString(_kProfiles, jsonEncode(encoded));
  }

  static Future<void> _saveOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnboarding, jsonEncode(_onboardingDone.toList()));
  }

  static Future<void> _saveJoinDates() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _joinDates.map((id, d) => MapEntry(id, d.toIso8601String()));
    await prefs.setString(_kJoinDates, jsonEncode(encoded));
  }

  static Future<void> _saveKeywordsDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeywordsDone, jsonEncode(_keywordsDone.toList()));
  }

  static Future<void> _saveUserKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKeywords, jsonEncode(_userKeywords));
  }

  // ── 공개 API ──────────────────────────────────────────────────────────────

  /// 로그인. 성공 시 유저 정보 Map 반환, 실패 시 null
  static Map<String, String>? login(String id, String password) {
    final user = _users[id];
    if (user == null) return null;
    if (user['password'] != password) return null;
    _currentUserId = id;
    return user;
  }

  /// 회원가입. 성공 시 true, 이미 있는 아이디면 false
  static Future<bool> register({
    required String id,
    required String password,
    required String nickname,
  }) async {
    if (_users.containsKey(id)) return false;
    _users[id] = {'password': password, 'nickname': nickname};
    await _saveUsers();
    return true;
  }

  /// 프로필 저장 (나이, MBTI, 직업, 취미)
  static Future<void> saveProfile({
    required String userId,
    required int age,
    required String mbti,
    required String job,
    required List<String> hobbies,
  }) async {
    _userProfiles[userId] = UserProfile(
      age: age,
      mbti: mbti,
      job: job,
      hobbies: hobbies,
    );
    await _saveProfiles();
  }

  /// 프로필 가져오기
  static UserProfile? getProfile(String userId) => _userProfiles[userId];

  /// 프로필 입력 완료 여부
  static bool hasProfile(String userId) => _userProfiles.containsKey(userId);

  /// 온보딩 완료 처리
  static Future<void> completeOnboarding(String userId, List<String> keywords) async {
    _onboardingDone.add(userId);
    _joinDates.putIfAbsent(userId, () => DateTime.now());
    await Future.wait([_saveOnboarding(), _saveJoinDates()]);
  }

  /// 온보딩 완료 여부 확인
  static bool hasCompletedOnboarding(String userId) =>
      _onboardingDone.contains(userId);

  /// 온보딩 재설정 — 계정·경험 기록은 유지하고 프로필 입력만 초기화
  static Future<void> resetOnboarding(String userId) async {
    _onboardingDone.remove(userId);
    await _saveOnboarding();
  }

  /// 키워드 선택 저장
  static Future<void> saveKeywords(String userId, List<String> keywords) async {
    _userKeywords[userId] = keywords;
    _keywordsDone.add(userId);
    await Future.wait([_saveUserKeywords(), _saveKeywordsDone()]);
  }

  /// 키워드 선택 완료 여부
  static bool hasSelectedKeywords(String userId) =>
      _keywordsDone.contains(userId);

  /// 저장된 키워드 가져오기
  static List<String> getUserKeywords(String userId) =>
      _userKeywords[userId] ?? [];

  /// 가입일 기준 현재 몇 주차인지 반환 (1주차부터 시작)
  static int getWeekNumber(String userId) {
    final joinDate = _joinDates[userId];
    if (joinDate == null) return 1;
    final diff = DateTime.now().difference(joinDate).inDays;
    return (diff / 7).floor() + 1;
  }

  /// 가입일 직접 설정 (테스트용)
  static void setJoinDate(String userId, DateTime date) {
    _joinDates[userId] = date;
    _saveJoinDates();
  }

  /// 로그아웃
  static void logout() {
    _currentUserId = null;
  }

  /// 닉네임 가져오기
  static String getNickname(String userId) {
    return _users[userId]?['nickname'] ?? userId;
  }
}

/// 사용자 프로필 모델
class UserProfile {
  final int age;
  final String mbti;
  final String job;
  final List<String> hobbies;

  const UserProfile({
    required this.age,
    required this.mbti,
    required this.job,
    required this.hobbies,
  });

  bool get isIntrovert => mbti.startsWith('I');
  bool get isIntuitive => mbti.length > 1 && mbti[1] == 'N';

  @override
  String toString() =>
      'UserProfile(age: $age, mbti: $mbti, job: $job, hobbies: $hobbies)';
}
