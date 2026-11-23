import 'booth.dart';

/// QR 출처 (명세 `PaymentSource`): 인쇄한 QR 인지, 메뉴판 태블릿의 QR 인지.
enum PaymentSource {
  /// 인쇄 QR (기본값)
  print,

  /// 메뉴판(태블릿) QR
  board;

  static PaymentSource parse(String value) => switch (value) {
    'print' => PaymentSource.print,
    'board' => PaymentSource.board,
    _ => throw FormatException('알 수 없는 QR 출처예요: $value'),
  };
}

/// 카메라로 읽은 QR 값에서 꺼낸 부스 코드와 출처.
///
/// 받는 모양 두 가지:
/// - 코드만: `K7Q2M9X4TB` (영숫자 10자리)
/// - 주소: `https://<아무 주소>/q/K7Q2M9X4TB?src=board` (`src` 가 없거나 모르는 값이면 `print`)
class QrPayload {
  const QrPayload(this.code, {this.source = PaymentSource.print});

  final String code;
  final PaymentSource source;

  static final RegExp _code = RegExp(r'^[A-Za-z0-9]{10}$');

  /// 바자회 QR 이 아니면 [FormatException].
  static QrPayload parse(String raw) =>
      tryParse(raw) ?? (throw FormatException('바자회 부스 QR 이 아니에요: $raw'));

  /// 바자회 QR 이 아니면 null.
  static QrPayload? tryParse(String raw) {
    final value = raw.trim();
    if (_code.hasMatch(value)) return QrPayload(value);

    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 ||
        segments.first != 'q' ||
        !_code.hasMatch(segments.last)) {
      return null;
    }
    final source = switch (uri.queryParameters['src']) {
      'board' => PaymentSource.board,
      _ => PaymentSource.print,
    };
    return QrPayload(segments.last, source: source);
  }

  @override
  bool operator ==(Object other) =>
      other is QrPayload && other.code == code && other.source == source;

  @override
  int get hashCode => Object.hash(code, source);

  @override
  String toString() => 'QrPayload($code, ${source.name})';
}

/// 결제 화면의 메뉴 한 개 (명세 `Menu`).
class PayMenu {
  const PayMenu({
    required this.id,
    required this.name,
    required this.price,
    required this.onSale,
    required this.sortOrder,
    this.description,
    this.imageUrl,
  });

  factory PayMenu.fromJson(Map<String, Object?> json) => PayMenu(
    id: json['id']! as int,
    name: json['name']! as String,
    description: json['description'] as String?,
    price: json['price']! as int,
    onSale: json['onSale']! as bool,
    sortOrder: json['sortOrder']! as int,
    imageUrl: json['imageUrl'] as String?,
  );

  final int id;
  final String name;
  final String? description;

  /// 가격 (크레딧)
  final int price;

  /// false 면 품절
  final bool onSale;
  final int sortOrder;

  /// 서버 기준 상대 경로 (예: `/files/menus/301-4c1d.webp`)
  final String? imageUrl;
}

/// QR 로 읽은 결제 화면 정보 (`GET /pay/qr/{code}`). 200 이면 주문을 받는 중입니다.
class QrPayInfo {
  QrPayInfo({
    required this.code,
    required this.source,
    required this.booth,
    required List<PayMenu> menus,
    this.balance,
  }) : menus = List.unmodifiable(menus);

  factory QrPayInfo.fromJson(Map<String, Object?> json) {
    final menus = json['menus'];
    if (menus is! List) {
      throw const FormatException('QR 결제 정보에 menus 가 없어요');
    }
    final menuList = [
      for (final menu in menus.cast<Map<String, Object?>>())
        PayMenu.fromJson(menu),
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return QrPayInfo(
      code: json['code']! as String,
      source: PaymentSource.parse(json['source'] as String? ?? 'print'),
      booth: Booth.fromJson(json['booth']! as Map<String, Object?>),
      menus: menuList,
      balance: json['balance'] as int?,
    );
  }

  final String code;
  final PaymentSource source;

  /// 부스 요약 (`GET /booths` 의 한 줄과 같은 모양)
  final Booth booth;

  /// 메뉴 (표시 순서대로)
  final List<PayMenu> menus;

  /// 조회한 순간의 내 잔액 (있을 때만)
  final int? balance;
}
