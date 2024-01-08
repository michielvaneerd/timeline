import 'package:equatable/equatable.dart';
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'package:timeline/my_http.dart';
import 'package:timeline/my_store.dart';

class TimelineRepository {
  final MyHttp myHttp;

  const TimelineRepository({required this.myHttp});

  Future<List<TimelineItem>> getTimelineItems(
      TimelineHost timelineHost, Timeline timeline) async {
    final itemsFromStore =
        await MyStore.getTimelineItems(timelineHost.id, timeline.id);
    if (itemsFromStore.isNotEmpty) {
      return itemsFromStore;
    }
    final uri =
        '${timelineHost.host}/wp-json/mve-timeline/v1/timelines/${timeline.termId}';
    final response = await myHttp.getAsString(uri);
    await MyStore.putTimelineItems(timelineHost.id, timeline.id, response);
    return await MyStore.getTimelineItems(timelineHost.id, timeline.id);
  }

  Future<List<Timeline>> getTimelines({TimelineHost? timelineHost}) async {
    var storedTimelines = await MyStore.getTimelines(
        timelineHost != null ? [timelineHost.id] : null);
    if (storedTimelines.isEmpty && timelineHost != null) {
      // final response = await myHttp.get(
      //     '${timelineHost.host}/wp-json/wp/v2/mve_timeline?_fields=id,name,description&hide_empty=1');
      final response = await myHttp
          .get('${timelineHost.host}/wp-json/mve-timeline/v1/timelines');
      await MyStore.putTimelinesFromResponse(
          (response['items'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
          timelineHost.id);
      storedTimelines = await MyStore.getTimelines([timelineHost.id]);
    }
    return storedTimelines;
  }

  Future<TimelineAll> getAll() async {
    final activeTimelineId = await MyStore.getActiveTimelineId();
    final timelineHosts = await MyStore.getTimelineHosts();
    final timelines = await getTimelines();
    //List<TimelineItem>? timelineItems;
    //if (activeTimelineId != null) {
    //   final timeline = timelines.firstWhere((e) => e.id == activeTimelineId);
    //   final host = timelineHosts.firstWhere((e) => e.id == timeline.hostId);
    //timelineItems = await getTimelineItems(host, timeline);
    // }
    return TimelineAll(
        activeTimelineId: activeTimelineId,
        timelineHosts: timelineHosts,
        //timelineItems: timelineItems,
        timelines: timelines);
  }
}

class TimelineAll extends Equatable {
  final int? activeTimelineId;
  final List<TimelineHost> timelineHosts;
  final List<Timeline> timelines;
  //final List<TimelineItem>? timelineItems;

  const TimelineAll(
      {required this.activeTimelineId,
      required this.timelineHosts,
      //this.timelineItems,
      required this.timelines});
  @override
  List<Object?> get props => [activeTimelineId, timelineHosts, timelines];
}
