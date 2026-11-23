import '../../../data/models/booth_detail.dart';

const BoothDetail sampleBooth = BoothDetail(
  id: 'sample',
  name: '2-3 타코야끼',
  className: '2학년 3반',
  isOpen: true,
  location: '신관 2층 복도',
  openHours: '10:00–15:00',
  operators: [
    BoothOperator(name: '김서연', role: '반장'),
    BoothOperator(name: '이도윤', role: '캐셔'),
  ],
);
