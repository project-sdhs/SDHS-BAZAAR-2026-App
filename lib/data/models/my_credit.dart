class MyCredit {
  const MyCredit(this.json);
  final Map<String, dynamic> json;
  int get balance => json['balance'] as int;
  int get used => json['used'] as int;
  int get pendingChargeAmount => json['pendingChargeAmount'] as int;
}

const mockCredit = MyCredit({
  'balance': 12400,
  'used': 17600,
  'pendingChargeAmount': 0,
});
