/// 서버 시각(UTC)을 바자회 현지 시각(Asia/Seoul, UTC+9, 서머타임 없음)으로 바꾸는 도우미.
///
/// 서버는 시각을 UTC 로 주고, "오늘" · 날짜 묶음은 서울 날짜로 계산합니다(명세 공통 규칙).
/// 기기 시간대와 상관없이 같은 결과가 나오도록 `toLocal()` 대신 이 함수를 씁니다.
library;

const Duration _seoulOffset = Duration(hours: 9);

/// [time] 을 서울 벽시계 시각으로 바꿉니다. 결과의 year · month · day · hour · minute 를 그대로 읽으면 됩니다.
DateTime toSeoul(DateTime time) => time.toUtc().add(_seoulOffset);

/// [time] 이 속한 서울 날짜 (시각은 0시, UTC 로 표시).
DateTime seoulDay(DateTime time) {
  final seoul = toSeoul(time);
  return DateTime.utc(seoul.year, seoul.month, seoul.day);
}

/// `2026-10-24` 같은 날짜 문자열을 [seoulDay] 와 비교할 수 있는 값으로 읽습니다.
DateTime parseSeoulDate(String value) {
  final date = DateTime.parse(value);
  return DateTime.utc(date.year, date.month, date.day);
}

/// `HH:mm` (서울 시각)
String seoulHourMinute(DateTime time) {
  final seoul = toSeoul(time);
  final hour = seoul.hour.toString().padLeft(2, '0');
  final minute = seoul.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// `10월 24일 토요일` (서울 날짜)
String seoulDayLabel(DateTime time) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final seoul = toSeoul(time);
  return '${seoul.month}월 ${seoul.day}일 ${weekdays[seoul.weekday - 1]}요일';
}
