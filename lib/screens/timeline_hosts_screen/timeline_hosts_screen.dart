import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/my_loading_overlay.dart';
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
  var selectionMode = false;
  Map<int, bool> selectedHosts = {};
  late int timelineAllHash;
  final _loadingOverlay = LoadingOverlay();
  @override
  void dispose() {
    createHostController.dispose();
    _loadingOverlay.hide();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timelineAllHash = widget.timelineAll.hashCode;
  }

  TimelineAll _getTimelineAll(TimelineHostsScreenState? state) {
    return state?.timelineAll ?? widget.timelineAll;
  }

  bool _isSelected(int hostId) {
    return selectedHosts.containsKey(hostId) && selectedHosts[hostId]!;
  }

  List<Widget> getHostTimelines(TimelineAll timelineAll, TimelineHost host) {
    final isSelected = _isSelected(host.id);
    final List<Widget> widgets = [
      ListTile(
          onLongPress: () {
            setState(() {
              selectionMode = !selectionMode;
              selectedHosts = {host.id: true};
            });
          },
          onTap: () {
            if (selectionMode) {
              var copy = Map<int, bool>.of(selectedHosts);
              if (isSelected) {
                copy.remove(host.id);
              } else {
                copy[host.id] = true;
              }
              setState(() {
                selectedHosts = copy;
              });
            }
          },
          leading: Icon(selectionMode
              ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
              : Icons.circle),
          title:
              Text(host.host, style: Theme.of(context).textTheme.headlineSmall))
    ];
    for (final t in timelineAll.timelines) {
      if (t.hostId == host.id) {
        widgets.add(ListTile(
            onTap: () {
              Navigator.of(context).pop(t.id);
            },
            title: Text(t.name)));
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
          if (!state.busy) {
            _loadingOverlay.hide();
            setState(() {
              selectionMode = false;
              selectedHosts = {};
            });
          }
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
            appBar: AppBar(
              title: const Text('Hosts'),
              actions: selectionMode
                  ? [
                      IconButton(
                          onPressed: selectedHosts.isNotEmpty
                              ? () {
                                  _loadingOverlay.show(context);
                                  cubit
                                      .removeHosts(selectedHosts.keys.toList());
                                }
                              : null,
                          icon: const Icon(Icons.delete))
                    ]
                  : null,
            ),
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
