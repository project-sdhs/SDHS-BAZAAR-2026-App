import 'package:bazaar_app/data/models/booth.dart';

Booth fixtureBooth({
  required int id,
  required String name,
  int? grade,
  int classNo = 1,
  String category = '간식',
  BoothType type = BoothType.normal,
  BoothStatus status = BoothStatus.open,
  String? location = '신관 2층 복도',
  int? minPrice = 1000,
}) => Booth(
  id: id,
  name: name,
  boothClass: grade == null
      ? null
      : BoothClass(
          id: id,
          grade: grade,
          classNo: classNo,
          name: '$grade학년 $classNo반',
        ),
  category: category,
  type: type,
  status: status,
  locationLabel: location,
  minPrice: minPrice,
  menuCount: 3,
);

/// 1학년 1곳, 2학년 2곳, 3학년 1곳, 특별부스 1곳 (2-1 은 닫힘)
List<Booth> fixtureBooths() => [
  fixtureBooth(id: 1, name: '1-2 컵밥분식', grade: 1, classNo: 2, category: '한식'),
  fixtureBooth(
    id: 2,
    name: '2-3 타코야끼',
    grade: 2,
    classNo: 3,
    location: '신관 2층 복도',
  ),
  fixtureBooth(
    id: 3,
    name: '2-1 츄러스',
    grade: 2,
    classNo: 1,
    status: BoothStatus.closed,
  ),
  fixtureBooth(
    id: 4,
    name: '3-1 로제떡볶이',
    grade: 3,
    classNo: 1,
    category: '분식',
    location: '본관 1층 로비',
    minPrice: 1500,
  ),
  fixtureBooth(
    id: 5,
    name: '학생회 포토부스',
    type: BoothType.special,
    category: '체험',
    location: '본관 1층 로비',
    minPrice: 2000,
  ),
];
