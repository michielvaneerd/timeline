import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/repositories/timeline_repository.dart';
import 'package:timeline/screens/timeline_hosts_screen/timeline_hosts_screen_bloc.dart';

class TimelineHostsScreen extends StatefulWidget {
  final TimelineAll timelineAll;
  const TimelineHostsScreen({super.key, required this.timelineAll});

  @override
  State<TimelineHostsScreen> createState() => _TimelineHostsScreenState();
}

class _TimelineHostsScreenState extends State<TimelineHostsScreen> {
  final createHostController = TextEditingController();

  @override
  void dispose() {
    createHostController.dispose();
    super.dispose();
  }

  TimelineAll _getTimelineAll(TimelineHostsScreenState? state) {
    return state?.timelineAll ?? widget.timelineAll;
  }

  List<Widget> getHostTimelines(TimelineAll timelineAll, TimelineHost host) {
    final List<Widget> widgets = [Text(host.host)];
    for (final t in timelineAll.timelines) {
      if (t.hostId == host.id) {
        widgets.add(ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(t.id);
            },
            child: Text(t.name)));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryProvider.of<TimelineRepository>(context);
    return BlocProvider(
      create: (context) => TimelineHostsScreenCubit(repo),
      child: BlocConsumer<TimelineHostsScreenCubit, TimelineHostsScreenState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final cubit = BlocProvider.of<TimelineHostsScreenCubit>(context);
          final timelineAll = _getTimelineAll(state);
          final List<Widget> items = [];
          for (final h in timelineAll.timelineHosts) {
            items.addAll(getHostTimelines(timelineAll, h));
          }
          return Scaffold(
            appBar: AppBar(),
            body: Column(
              children: [
                ...items,
                TextField(
                  controller: createHostController,
                ),
                ElevatedButton(
                    onPressed: state.busy
                        ? null
                        : () {
                            cubit.addHost(
                                createHostController.text, timelineAll);
                          },
                    child: const Text('Add'))
              ],
            ),
          );
        },
      ),
    );
  }
}
