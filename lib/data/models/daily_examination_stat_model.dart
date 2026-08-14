import '../../domain/entities/daily_examination_stat_entity.dart';

class DailyExaminationStatModel extends DailyExaminationStatEntity {
  const DailyExaminationStatModel({required super.date, required super.count});

  factory DailyExaminationStatModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate == null) {
      throw Exception('Dinh dang ngay thong ke 7 ngay khong hop le');
    }

    final rawCount = json['count'];
    return DailyExaminationStatModel(
      date: DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
      count: rawCount is num
          ? rawCount.toInt()
          : int.tryParse('$rawCount') ?? 0,
    );
  }
}
