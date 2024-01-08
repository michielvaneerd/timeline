import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';

class TimelineItemsScreenState extends Equatable {
  final List<TimelineItem> items;
  final bool busy;

  const TimelineItemsScreenState({required this.items, this.busy = false});
  @override
  List<Object?> get props => [items, busy];
}

class TimelineItemsScreenCubit extends Cubit<TimelineItemsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineItemsScreenCubit(this.timelineRepository)
      : super(const TimelineItemsScreenState(items: []));

  Future getItems(TimelineHost timelineHost, Timeline timeline,
      {bool refresh = false}) async {
    emit(const TimelineItemsScreenState(items: [], busy: true));
    if (refresh) {
      await MyStore.removeTimelineItems(timelineHost.id, timeline.id);
    }
    final items =
        await timelineRepository.getTimelineItems(timelineHost, timeline);
    emit(TimelineItemsScreenState(items: items));
  }
}
