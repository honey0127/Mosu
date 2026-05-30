📍 Nudge (넛지): 경험의 재발견"지루한 일상에 던지는 작은 균열"사용자의 취향(Fit)과 도전(Dare) 사이의 균형을 맞춘 경험 추천 및 아카이빙 플랫폼입니다.
🌟 Core Concept단순한 할 일 목록(To-do list)이 아닙니다. Spotify의 알고리즘처럼 내 취향을 저격하는 경험과, Setlog처럼 확실한 인증을 결합했습니다. 어려운 경험을 완수할수록 보상이 커지며, 이를 통해 나만의 가상 공간을 꾸며나가는 Gamification 요소가 핵심입니다.
🚀 Key Features
1. Keyword Shuffle (Discovery)랜덤 키워드 버블: 앱 진입 시 화면에 떠다니는 다양한 키워드(분위기, 장소, 난이도 등)를 랜덤하게 배치합니다.멀티 셀렉트: 사용자가 직관적으로 원하는 키워드를 5~8개 선택하여 오늘의 무드를 결정합니다
2. Double-Track RecommendationFit (맞춤형): 선택한 키워드와 높은 상관관계를 가진 안정적인 경험 추천.Dare (도전형): 취향과는 거리가 있지만 새로운 자극을 줄 수 있는 의외의 경험 추천.
3. Proof of Experience (Certification)신뢰 인증: 사진 촬영 시 메타데이터(위치, 시간)를 대조하여 실제 수행 여부를 검증합니다.숏 로그: 짧은 텍스트와 감정 태그를 통해 경험의 여운을 기록합니다.
4. Experience Room (Gamification)난이도별 포인트: '집 앞 산책'보다 '혼자 놀이공원 가기'에 더 높은 가중치를 부여합니다.마이룸 꾸미기: 획득한 포인트로 가구, 조명, 오브젝트를 구매하여 나만의 공간을 확장합니다. (경험의 성격이 가구의 디자인에 반영됨)
🛠 Tech Stack (Suggested)Frontend: Flutter (Cross-platform UI & Animations)Backend: FastAPI or Spring BootDatabase: PostgreSQL / Firebase (Real-time sync)Storage: AWS S3 or Firebase Storage (Certification Photos)
📊 Implementation Difficulty & Analysis구현 난이도는 [중상(Medium-High)] 정도로 예상됩니다.구성 요소난이도주요 이슈키워드 애니메이션보통Flutter의 CustomPainter나 Physics 관련 라이브러리 활용 필요추천 로직보통키워드 가중치 기반 필터링 (초기엔 단순 로직으로 시작 가능)인증 시스템높음이미지 메타데이터(EXIF) 추출 및 GPS 거리 계산 로직 구현꾸미기 시스템높음오브젝트 배치 좌표 저장, 레이어링 시스템, 에셋 관리 등 게임 엔진적 요소 필요Tip: 처음부터 완벽한 꾸미기 게임을 만들기보다는, 고정된 위치에 아이템이 하나씩 추가되는 방식(Collectibles)으로 시작해 점차 자유 배치형으로 고도화하는 것을 추천합니다.
📅 Roadmap[ ] Phase 1: 키워드 기반 추천 알고리즘 및 UI 프로토타이핑[ ] Phase 2: 사진 메타데이터 기반 인증 시스템 구축[ ] Phase 3: 포인트 지급 및 상점/인벤토리 기능 개발[ ] Phase 4: 소셜 피드(공유) 및 협동 경험 기능 추가
