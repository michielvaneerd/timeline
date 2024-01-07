import 'package:equatable/equatable.dart';

class Timeline extends Equatable {
  final int id; // auto generated on client
  final int termId; // from backend
  final int hostId;
  final String name;
  final String description;

  const Timeline(
      {required this.id,
      required this.termId,
      required this.hostId,
      required this.name,
      required this.description});

  @override
  List<Object?> get props => [id, name, description, hostId, termId];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'term_id': termId,
      'host_id': hostId,
      'name': name,
      'description': description
    };
  }

  Timeline.fromMap(Map<String, dynamic> map, {int? hostId})
      : id = map['id'],
        termId = map['term_id'],
        name = map['name'],
        hostId = hostId ??
            map['host_id'], // When we select from database, myHostId can be null, but when we fetch from API, then we need myHostId.
        description = map['description'];
}
