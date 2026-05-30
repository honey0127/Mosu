import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

class AuthService {
  // 두 브랜치의 키(Key) 값들을 모두 유지합니다.
  static const _kUsers        = 'auth_users';
  static const _kProfiles     = 'auth_profiles';
  static const _kOnboarding   = 'auth_onboarding_done';
  static const _kJoinDates    = 'auth_join_dates';
  static const _kAvatars      = 'auth_avatars';
  static const _kKeywordsDone = 'auth_keywords_done';
  static const _kUserKeywords = 'auth_user_keywords';
  static const _kCurrentUser  = 'auth_current_user'; // 자동 로그인용
  static const _kAppStates    = 'auth_app_states';   // 유저별 AppState

  /// 프로필 사진을 캐릭터(내 공간에서 만든 동물 얼굴)로 설정했을 때의 값.
  /// 이 값이 아니면서 null도 아니면 갤러리 사진 파일 경로로 해석한다.
  static const avatarAnimal = 'animal';

  // 메모리 데이터 구조도 모두 합쳐줍니다.
  static final Map<String, Map<String, String>> _users = {};
  static final Map<String, UserProfile> _userProfiles = {};
  static final Set<String> _onboardingDone = {};
  static final Map<String, DateTime> _joinDates = {};
  static final Map<String, String> _avatars = {};          // HEAD(내 브랜치) 추가분
  static final Set<String> _keywordsDone = {};             // Claude 브랜치 추가분
  static final Map<String, List<String>> _userKeywords = {}; // Claude 브랜치 추가분

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
          age: m['age'] as int,
          mbti: m['mbti'] as String,
          job: m['job'] as String,
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

    // 프로필 사진 로드 (HEAD)
    final avatarsJson = prefs.getString(_kAvatars);
    if (avatarsJson != null) {
      final Map<String, dynamic> raw = jsonDecode(avatarsJson);
      raw.forEach((id, val) {
        _avatars[id] = val as String;
      });
    }

    // 키워드 선택 완료 목록 로드 (Claude)
    final kwDoneJson = prefs.getString(_kKeywordsDone);
    if (kwDoneJson != null) {
      _keywordsDone.addAll(List<String>.from(jsonDecode(kwDoneJson)));
    }

    // 유저별 선택 키워드 로드 (Claude)
    final kwJson = prefs.getString(_kUserKeywords);
    if (kwJson != null) {
      final Map<String, dynamic> raw = jsonDecode(kwJson);
      raw.forEach((id, val) {
        _userKeywords[id] = List<String>.from(val as List);
      });
    }

    // 마지막 로그인 유저 복원 (자동 로그인)
    final savedUser = prefs.getString(_kCurrentUser);
    if (savedUser != null && _users.containsKey(savedUser)) {
      _currentUserId = savedUser;
      await _loadAppState(savedUser);
    }
  }

  // ── 저장 헬퍼 ─────────────────────────────────────────────────────────────

  static Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUserId != null) {
      await prefs.setString(_kCurrentUser, _currentUserId!);
    } else {
      await prefs.remove(_kCurrentUser);
    }
  }

  static Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsers, jsonEncode(_users));
  }

  static Future<void> _saveProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _userProfiles.map(
          (id, p) => MapEntry(id, {
        'age': p.age,
        'mbti': p.mbti,
        'job': p.job,
        'hobbies': p.hobbies,
      }),
    );
    await prefs.setString(_kProfiles, jsonEncode(encoded));
  }

  static Future<void> _saveOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOnboarding, jsonEncode(_onboardingDone.toList()));
  }

  static Future<void> _saveJoinDates() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _joinDates.map(
          (id, d) => MapEntry(id, d.toIso8601String()),
    );
    await prefs.setString(_kJoinDates, jsonEncode(encoded));
  }

  // 아바타 저장 헬퍼 (HEAD)
  static Future<void> _saveAvatars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAvatars, jsonEncode(_avatars));
  }

  // 키워드 완료 저장 헬퍼 (Claude)
  static Future<void> _saveKeywordsDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeywordsDone, jsonEncode(_keywordsDone.toList()));
  }

  // 유저 키워드 저장 헬퍼 (Claude)
  static Future<void> _saveUserKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKeywords, jsonEncode(_userKeywords));
  }

  // 유저별 AppState 저장
  static Future<void> _saveAppState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAppStates);
    final Map<String, dynamic> all =
        raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    all[userId] = AppState.i.toJson();
    await prefs.setString(_kAppStates, jsonEncode(all));
  }

  // 유저별 AppState 불러오기
  static Future<void> _loadAppState(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAppStates);
    if (raw == null) { AppState.i.reset(); return; }
    final all = jsonDecode(raw) as Map<String, dynamic>;
    final data = all[userId];
    if (data == null) { AppState.i.reset(); return; }
    AppState.i.loadFromJson(data as Map<String, dynamic>);
  }

  // ── 공개 API ──────────────────────────────────────────────────────────────

  /// 로그인. 성공 시 유저 정보 Map 반환, 실패 시 null
  static Future<Map<String, String>?> login(String id, String password) async {
    final user = _users[id];
    if (user == null) return null;
    if (user['password'] != password) return null;
    // 다른 유저였다면 현재 상태 저장
    if (_currentUserId != null && _currentUserId != id) {
      await _saveAppState(_currentUserId!);
    }
    _currentUserId = id;
    await _saveCurrentUser();
    await _loadAppState(id);
    return user;
  }

  /// 게스트(디버그 '로그인 건너뛰기')용 입장. 현재 사용자 ID를 보장해
  /// 닉네임/프로필 사진 등이 빈칸 없이 정상 동작하게 한다.
  static const guestId = 'guest';

  static Future<void> loginAsGuest() async {
    if (!_users.containsKey(guestId)) {
      _users[guestId] = {'password': '', 'nickname': '게스트'};
      await _saveUsers();
    }
    _currentUserId = guestId;
    await _saveCurrentUser();
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
  static Future<void> completeOnboarding(
      String userId,
      List<String> keywords,
      ) async {
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

  /// 키워드 선택 저장 (Claude)
  static Future<void> saveKeywords(String userId, List<String> keywords) async {
    _userKeywords[userId] = keywords;
    _keywordsDone.add(userId);
    await Future.wait([_saveUserKeywords(), _saveKeywordsDone()]);
  }

  /// 키워드 선택 완료 여부 (Claude)
  static bool hasSelectedKeywords(String userId) =>
      _keywordsDone.contains(userId);

  /// 저장된 키워드 가져오기 (Claude)
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
  static Future<void> logout() async {
    if (_currentUserId != null) {
      await _saveAppState(_currentUserId!);
    }
    _currentUserId = null;
    AppState.i.reset();
    await _saveCurrentUser();
  }

  /// 닉네임 가져오기. 비어 있으면 친근한 기본값으로 대체해 화면에 빈칸이 보이지 않게 한다.
  static String getNickname(String userId) {
    final name = _users[userId]?['nickname']?.trim();
    if (name != null && name.isNotEmpty) return name;
    return userId.isNotEmpty ? userId : '게스트';
  }

  /// 닉네임 변경 (로컬 계정). 빈 문자열이면 무시.
  static Future<void> setNickname(String userId, String nickname) async {
    final name = nickname.trim();
    if (name.isEmpty) return;
    final user = _users[userId];
    if (user == null) return;
    user['nickname'] = name;
    await _saveUsers();
  }

  /// 프로필 사진 값 가져오기. (HEAD)
  /// null = 기본(이모지), [avatarAnimal] = 캐릭터 얼굴,
  /// 그 외 = 갤러리 사진 URL(업로드 실패 시 로컬 파일 경로)
  static String? getAvatar(String userId) => _avatars[userId];

  /// 프로필 사진 설정. value 가 null 이면 기본으로 되돌린다. (HEAD)
  static Future<void> setAvatar(String userId, String? value) async {
    if (value == null) {
      _avatars.remove(userId);
    } else {
      _avatars[userId] = value;
    }
    await _saveAvatars();
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