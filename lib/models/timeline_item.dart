import 'package:equatable/equatable.dart';

class TimelineItem extends Equatable {
  final int id;
  final String? image;
  final String intro;
  final int year;
  final String title;

  const TimelineItem(this.image, this.intro, this.year, this.title,
      {required this.id});

  @override
  List<Object?> get props => [id, image, intro, year, title];

  TimelineItem.fromMap(Map<String, dynamic> map)
      : id = int.parse(map['id']),
        image = map['image'],
        intro = map['intro'],
        year = int.parse(map['year']),
        title = map['title'];
}
