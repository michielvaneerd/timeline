import 'dart:io';

import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:timeline/models/timeline.dart';
import 'package:timeline/models/timeline_host.dart';
import 'package:timeline/models/timeline_item.dart';
import 'dart:convert' as convert;

class MyStore {
  static const keySettingsActiveTimelineId = 'active_timeline_id';

  static Database? database;

  static Future init() async {
    database ??= await openDatabase(
      path.join(await getDatabasesPath(), 'timeline.sqlite'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY, key TEXT, value TEXT)');
        await db
            .execute('CREATE TABLE hosts (id INTEGER PRIMARY KEY, host TEXT)');
        await db.execute(
            'CREATE TABLE timelines (id INTEGER PRIMARY KEY, term_id INTEGER, name TEXT, description TEXT, host_id INT)');
        await db.execute(
            'CREATE TABLE items (id INTEGER PRIMARY KEY, timeline_id INTEGER, year INTEGER, intro TEXT, title TEXT, image TEXT)');
      },
    );
  }

  static Future<int?> getActiveTimelineId() async {
    final rows = await database!.query('settings',
        where: 'key = ?', whereArgs: [keySettingsActiveTimelineId], limit: 1);
    if (rows.isNotEmpty) {
      return int.parse(rows[0]['value'].toString());
    } else {
      return null;
    }
  }

  static Future putActiveTimelineId(int? timelineId) async {
    await database!.transaction((txn) async {
      await txn.delete('settings',
          where: 'key = ?', whereArgs: [keySettingsActiveTimelineId]);
      if (timelineId != null) {
        await txn.insert('settings',
            {'key': keySettingsActiveTimelineId, 'value': timelineId});
      }
    });
  }

  static Future<List<TimelineHost>> getTimelineHosts() async {
    final rows = await database!.query('hosts', orderBy: 'host ASC');
    return rows.map((e) => TimelineHost.fromMap(e)).toList();
  }

  static Future<TimelineHost> putTimelineHost(String host) async {
    final id = await database!.insert('hosts', {'host': host});
    return TimelineHost(id: id, host: host);
  }

  static String _paramQuestions(List params) {
    return params.map((e) => '?').join(',');
  }

  static Future<List<Timeline>> getTimelines({List<int>? hostIds}) async {
    final rows = await database!.query('timelines',
        where:
            hostIds != null ? 'host_id IN (${_paramQuestions(hostIds)})' : null,
        whereArgs: hostIds,
        orderBy: 'name ASC');
    return rows.map((e) => Timeline.fromMap(e)).toList();
  }

  static Future putTimelinesFromResponse(
      List<Map<String, dynamic>> response, int timelineHostId) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      txn.delete('timelines',
          where: 'host_id = ?', whereArgs: [timelineHostId]);
      for (final timeline in response) {
        txn.insert('timelines', {
          'term_id': timeline['term_taxonomy_id'],
          'name': timeline['name'],
          'description': timeline['description'],
          'host_id': timelineHostId
        });
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineHosts(List<int> hostIds) async {
    final timelines = await getTimelines(hostIds: hostIds);
    await database!.transaction((txn) async {
      for (final timeline in timelines) {
        await removeTimelineItems(timeline.id, txn: txn);
      }
      await txn.delete('timelines',
          where: 'host_id IN (${_paramQuestions(hostIds)})',
          whereArgs: hostIds);
      await txn.delete('hosts',
          where: 'id IN (${_paramQuestions(hostIds)})', whereArgs: hostIds);
    });
  }

  static Future<List<TimelineItem>> getTimelineItems(
      List<int> timelineIds) async {
    final rows = await database!.query('items',
        where: 'timeline_id IN (${_paramQuestions(timelineIds)})',
        whereArgs: timelineIds,
        orderBy: 'year ASC');
    return rows.map((e) => TimelineItem.fromMap(e)).toList();
  }

  static Future putTimelineItems(
      int timelineHostId, int timelineId, Map<String, dynamic> map) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      final items = (map['items'] as List);
      for (final item in items) {
        item['timeline_id'] = timelineId;
        txn.insert('items', item);
      }
      await batch.commit(noResult: true);
    });
  }

  static Future removeTimelineItems(int timelineId, {Transaction? txn}) async {
    // final dir = await _localPath;
    // final file = File(path.join(dir, '$timelineHostId-$timelineId.json'));
    // if (await file.exists()) {
    //   await file.delete();
    // }
    await (txn ?? database!)
        .delete('items', where: 'timeline_id = ?', whereArgs: [timelineId]);
  }
}
