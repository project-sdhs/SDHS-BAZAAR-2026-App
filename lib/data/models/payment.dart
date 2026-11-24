import 'qr_pay.dart';

/// 결제할 메뉴 한 줄 (`POST /payments` 의 `items` 한 개).
class PaymentItem {
  const PaymentItem({required this.menuId, required this.quantity});

  final int menuId;
  final int quantity;

  Map<String, Object?> toJson() => {'menuId': menuId, 'quantity': quantity};
}

/// 결제 요청 본문 (`POST /payments`).
class PaymentRequest {
  PaymentRequest({
    required this.qrCode,
    required this.source,
    required List<PaymentItem> items,
    required this.clientTotal,
  }) : items = List.unmodifiable(items);

  /// 스캔한 QR 코드
  final String qrCode;
  final PaymentSource source;

  /// 같은 메뉴는 한 번만
  final List<PaymentItem> items;

  /// 화면에 보여 준 합계. 서버 계산과 다르면 409 `MENU_CHANGED`.
  final int clientTotal;

  Map<String, Object?> toJson() => {
    'qrCode': qrCode,
    'source': source.name,
    'items': [for (final item in items) item.toJson()],
    'clientTotal': clientTotal,
  };
}

/// 결제한 부스 (id · 이름만)
class BoothRef {
  const BoothRef({required this.id, required this.name});

  factory BoothRef.fromJson(Map<String, Object?> json) =>
      BoothRef(id: json['id']! as int, name: json['name']! as String);

  final int id;
  final String name;
}

/// 결제한 메뉴 한 줄 (결제 당시 이름 · 단가 복사본).
class PaymentLine {
  const PaymentLine({
    required this.menuId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
  });

  factory PaymentLine.fromJson(Map<String, Object?> json) => PaymentLine(
    menuId: json['menuId']! as int,
    name: json['name']! as String,
    unitPrice: json['unitPrice']! as int,
    quantity: json['quantity']! as int,
    amount: json['amount']! as int,
  );

  final int menuId;
  final String name;
  final int unitPrice;
  final int quantity;

  /// unitPrice × quantity
  final int amount;
}

/// 결제 완료 영수증 (`POST /payments` 200). 서버가 커밋한 뒤에만 옵니다.
class PaymentReceipt {
  PaymentReceipt({
    required this.id,
    required this.no,
    required this.booth,
    required this.total,
    required this.balanceBefore,
    required this.balanceAfter,
    required List<PaymentLine> items,
    required this.paidAt,
  }) : items = List.unmodifiable(items);

  factory PaymentReceipt.fromJson(Map<String, Object?> json) => PaymentReceipt(
    id: json['id']! as int,
    no: json['no']! as int,
    booth: BoothRef.fromJson(json['booth']! as Map<String, Object?>),
    total: json['total']! as int,
    balanceBefore: json['balanceBefore']! as int,
    balanceAfter: json['balanceAfter']! as int,
    items: [
      for (final item in (json['items']! as List).cast<Map<String, Object?>>())
        PaymentLine.fromJson(item),
    ],
    paidAt: DateTime.parse(json['paidAt']! as String),
  );

  /// 결제 id
  final int id;

  /// 부스 결제 번호 (손님 호출용)
  final int no;
  final BoothRef booth;
  final int total;
  final int balanceBefore;
  final int balanceAfter;
  final List<PaymentLine> items;
  final DateTime paidAt;
}
