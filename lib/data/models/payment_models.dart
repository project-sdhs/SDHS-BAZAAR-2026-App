class DepositAccount {
  const DepositAccount({
    required this.bank,
    required this.accountNo,
    required this.holder,
  });

  final String bank;
  final String accountNo;
  final String holder;
}

class ChargeSettings {
  const ChargeSettings({
    required this.account,
    this.minimumAmount = 1000,
    this.maximumAmount,
    this.balanceLimit,
    this.eventEnded = false,
  });

  final DepositAccount account;
  final int minimumAmount;
  final int? maximumAmount;
  final int? balanceLimit;
  final bool eventEnded;
}

enum ChargeStatus { pending, approved, rejected, needsReview }

class ChargeRequest {
  const ChargeRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.depositorName,
    this.reason,
  });

  final int id;
  final int amount;
  final ChargeStatus status;
  final String depositorName;
  final String? reason;
}

enum TransactionType { charge, purchase, refund, adjustment }

class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.occurredAt,
    required this.status,
    required this.amount,
  });

  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final DateTime occurredAt;
  final String status;
  final int amount;
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.onSale = true,
    this.emoji = '🥟',
  });

  final int id;
  final String name;
  final int price;
  final bool onSale;
  final String emoji;
}

class PaymentBooth {
  PaymentBooth({
    required this.code,
    required this.name,
    required this.location,
    required List<MenuItem> menus,
    this.isOpen = true,
  }) : menus = List.unmodifiable(menus);

  final String code;
  final String name;
  final String location;
  final List<MenuItem> menus;
  final bool isOpen;
}

class OrderLine {
  const OrderLine({required this.menu, required this.quantity});

  final MenuItem menu;
  final int quantity;
  int get amount => menu.price * quantity;
}

class PaymentReceipt {
  PaymentReceipt({
    required this.number,
    required this.booth,
    required List<OrderLine> items,
    required this.total,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.paidAt,
  }) : items = List.unmodifiable(items);

  final int number;
  final PaymentBooth booth;
  final List<OrderLine> items;
  final int total;
  final int balanceBefore;
  final int balanceAfter;
  final DateTime paidAt;
}

class PaymentException implements Exception {
  const PaymentException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'PaymentException($code, $message)';
}
