import 'package:flutter/foundation.dart';

import '../data/models/payment_models.dart';
import '../data/repositories/payment_repository.dart';

class CreditStore extends ChangeNotifier {
  CreditStore({required PaymentRepository repository})
    // 공개 생성자에서 주입 인자 이름을 명시합니다.
    // ignore: prefer_initializing_formals
    : _repository = repository;

  factory CreditStore.preview() =>
      CreditStore(repository: PreviewPaymentRepository());

  final PaymentRepository _repository;
  bool _paying = false;
  bool _requestingCharge = false;
  bool _disposed = false;

  int get balance => _repository.balance;
  int get chargedTotal => _repository.chargedTotal;
  int get usedTotal => _repository.usedTotal;
  String get depositorName => _repository.depositorName;
  ChargeSettings get settings => _repository.settings;
  List<CreditTransaction> get transactions => _repository.transactions;
  ChargeRequest? get chargeRequest => _repository.chargeRequest;
  bool get isPreview => _repository.isPreview;

  Future<ChargeRequest> requestCharge(int amount) async {
    if (_requestingCharge) {
      throw const PaymentException(
        code: 'CHARGE_IN_PROGRESS',
        message: '충전 요청을 보내고 있어요. 잠시만 기다려 주세요.',
      );
    }
    _requestingCharge = true;
    try {
      final request = await _repository.requestCharge(amount);
      _notifyIfActive();
      return request;
    } finally {
      _requestingCharge = false;
    }
  }

  Future<ChargeRequest?> refreshCharge() async {
    final request = await _repository.refreshCharge();
    _notifyIfActive();
    return request;
  }

  Future<PaymentBooth> resolveQr(String value) => _repository.resolveQr(value);

  Future<PaymentReceipt> pay(PaymentBooth booth, List<OrderLine> items) async {
    if (_paying) {
      throw const PaymentException(
        code: 'PAYMENT_IN_PROGRESS',
        message: '결제를 처리하고 있어요. 잠시만 기다려 주세요.',
      );
    }
    _paying = true;
    final frozenItems = List<OrderLine>.unmodifiable(items);
    try {
      final receipt = await _repository.pay(booth, frozenItems);
      _notifyIfActive();
      return receipt;
    } finally {
      _paying = false;
    }
  }

  void _notifyIfActive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
