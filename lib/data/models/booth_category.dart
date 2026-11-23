enum BoothCategory {
  snack('분식'),
  dessert('간식'),
  drink('음료'),
  korean('한식'),
  goods('굿즈'),
  activity('체험'),
  exhibition('전시'),
  special('특별부스');

  const BoothCategory(this.label);

  final String label;
}
