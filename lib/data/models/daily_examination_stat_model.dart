import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/daily_examination_stat_entity.dart';

class DailyExaminationStatModel extends DailyExaminationStatEntity {
  const DailyExaminationStatModel({required super.date, required super.count});

  factory DailyExaminationStatModel.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date']?.toString() ?? '';
    final parsedDate = parseLocalDate(rawDate);
    if (parsedDate == null) {
      throw Exception('Dinh dang ngay thong ke 7 ngay khong hop le');
    }

    final rawCount = json['count'];
    return DailyExaminationStatModel(
      date: parsedDate,
      count: rawCount is num
          ? rawCount.toInt()
          : int.tryParse('$rawCount') ?? 0,
    );
  }
}
