/// 간단한 인메모리 인증 서비스 (실제 앱에서는 Firebase/백엔드로 교체)
class AuthService {
  // 사용자 DB: { userId: { password, nickname } }
  static final Map<String, Map<String, String>> _users = {
    // 기본 테스트 계정
    'test': {'password': '123456', 'nickname': '탐험가'},
  };

  // 온보딩 완료 여부
  static final Map<String, bool> _onboardingDone = {};

  // 온보딩 키워드 저장
  static final Map<String, List<String>> _userKeywords = {};

  // 현재 로그인된 사용자
  static String? _currentUserId;

  static String? get currentUserId => _currentUserId;

  /// 로그인. 성공 시 유저 정보 Map 반환, 실패 시 null
  static Map<String, String>? login(String id, String password) {
    final user = _users[id];
    if (user == null) return null;
    if (user['password'] != password) return null;
    _currentUserId = id;
    return user;
  }

  /// 회원가입. 성공 시 true, 이미 있는 아이디면 false
  static bool register({
    required String id,
    required String password,
    required String nickname,
  }) {
    if (_users.containsKey(id)) return false;
    _users[id] = {'password': password, 'nickname': nickname};
    return true;
  }

  /// 온보딩 완료 처리
  static void completeOnboarding(String userId, List<String> keywords) {
    _onboardingDone[userId] = true;
    _userKeywords[userId] = keywords;
  }

  /// 온보딩 완료 여부 확인
  static bool hasCompletedOnboarding(String userId) {
    return _onboardingDone[userId] ?? false;
  }

  /// 저장된 키워드 가져오기
  static List<String> getUserKeywords(String userId) {
    return _userKeywords[userId] ?? [];
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