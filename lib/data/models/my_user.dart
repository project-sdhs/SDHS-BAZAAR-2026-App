class MyUser {
  const MyUser(this.json);
  final Map<String, dynamic> json;
  String get name => json['name'] as String;
  String get role => json['role'] as String;
  bool get isGuest => json['accountType'] == 'visitor';
  String get provider => json['provider'] as String? ?? '';
  String get studentNo => json['studentNo']?.toString() ?? '';
  String get depositCode => json['depositCode'] as String? ?? '';
  Map<String, dynamic> get schoolClass =>
      json['class'] as Map<String, dynamic>? ?? const {};
  List<Map<String, dynamic>> get operatingBooths =>
      (json['operatingBooths'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
  bool get canViewClass =>
      !isGuest && (role == 'class_leader' || role == 'teacher');
  bool get canOperate =>
      !isGuest &&
      (role == 'cashier' || role == 'class_leader') &&
      operatingBooths.isNotEmpty;
  String get roleLabel => isGuest
      ? '방문객'
      : switch (role) {
          'class_leader' => '반장',
          'teacher' => '선생님',
          'cashier' => '캐셔',
          _ => '학생',
        };
  String get description => isGuest
      ? '${provider == 'kakao' ? '카카오' : provider}로 로그인 · 입금 코드 $depositCode'
      : '${schoolClass['grade']}학년 ${schoolClass['number']}반 · 학번 $studentNo';
}

const mockStudent = MyUser({
  'name': '이재원',
  'role': 'class_leader',
  'accountType': 'student',
  'provider': 'school',
  'studentNo': '2205',
  'depositCode': null,
  'class': {'grade': 2, 'number': 3},
  'operatingBooths': [
    {'id': 'booth-1', 'name': '2-3 타코야끼'},
  ],
});
const mockVisitor = MyUser({
  'name': '방문객',
  'role': 'visitor',
  'accountType': 'visitor',
  'provider': 'kakao',
  'studentNo': null,
  'depositCode': 'V3071',
  'class': null,
  'operatingBooths': [],
});
