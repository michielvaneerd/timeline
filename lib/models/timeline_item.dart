import 'package:equatable/equatable.dart';

class TimelineItem extends Equatable {
  final int id;
  final int timelineId;
  final String? image;
  final String intro;
  final int year;
  final String title;

  const TimelineItem(this.image, this.intro, this.year, this.title,
      {required this.id, required this.timelineId});

  @override
  List<Object?> get props => [id, image, intro, year, title, timelineId];

  // Can be called when we get response from server (then we don't have a timelineId)
  // or when getting from DB (in this case we HAVE a timelineId)
  TimelineItem.fromMap(Map<String, dynamic> map, {int? timelineId})
      : id = int.parse(map['id'].toString()),
        timelineId = timelineId ?? map['timeline_id'],
        image = map['image'],
        intro = map['intro'],
        year = int.parse(map['year'].toString()),
        title = map['title'];
}
