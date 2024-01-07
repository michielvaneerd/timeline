import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/my_store.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:collection/collection.dart';

class TimelineHostsScreenState extends Equatable {
  final String? error;
  final bool busy;
  final TimelineAll? timelineAll;

  const TimelineHostsScreenState(
      {this.error, this.busy = false, this.timelineAll});

  @override
  List<Object?> get props => [error, busy, timelineAll];
}

class TimelineHostsScreenCubit extends Cubit<TimelineHostsScreenState> {
  final TimelineRepository timelineRepository;
  TimelineHostsScreenCubit(this.timelineRepository)
      : super(const TimelineHostsScreenState());

  void addHost(String host, TimelineAll timelineAll) async {
    emit(const TimelineHostsScreenState(busy: true));
    final currentHosts = await MyStore.getTimelineHosts();
    final existingHost =
        currentHosts.firstWhereOrNull((element) => element.host == host);
    if (existingHost != null) {
      emit(TimelineHostsScreenState(
          error: 'Host already exists', timelineAll: timelineAll));
      return;
    }
    final timelineHost = await MyStore.putTimelineHost(host);
    await timelineRepository.getTimelines(timelineHost: timelineHost);
    final all = await timelineRepository.getAll();
    emit(TimelineHostsScreenState(timelineAll: all));
  }
}
