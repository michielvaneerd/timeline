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
        // FOREIGN KEY (host_id) REFERENCES hosts (id) ON DELETE CASCADE ON UPDATE NO ACTION
        await db.execute(
            'CREATE TABLE timelines (id INTEGER PRIMARY KEY, term_id INTEGER, name TEXT, description TEXT, host_id INT)');
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

  static Future putActiveTimelineId(int timelineId) async {
    await database!.transaction((txn) async {
      await txn.delete('settings',
          where: 'key = ?', whereArgs: [keySettingsActiveTimelineId]);
      await txn.insert('settings',
          {'key': keySettingsActiveTimelineId, 'value': timelineId});
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

  static Future<List<Timeline>> getTimelines(int? timelineHostId) async {
    final rows = await database!.query('timelines',
        where: timelineHostId != null ? 'host_id = ?' : null,
        whereArgs: timelineHostId != null ? [timelineHostId] : null,
        orderBy: 'name ASC');
    return rows.map((e) => Timeline.fromMap(e)).toList();
  }

  static Future putTimelinesFromResponse(
      List<Map<String, dynamic>> timelines, int timelineHostId) async {
    await database!.transaction((txn) async {
      final batch = txn.batch();
      txn.delete('timelines',
          where: 'host_id = ?', whereArgs: [timelineHostId]);
      for (final timeline in timelines) {
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

  static Future<String> get _localPath async {
    final directory = await path_provider.getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<List<TimelineItem>> getTimelineItems(
      int timelineHostId, int timelineId) async {
    final dir = await _localPath;
    final file = File(path.join(dir, '$timelineHostId-$timelineId.json'));
    if (!await file.exists()) {
      return [];
    }
    final contents = await file.readAsString();
    final json = convert.jsonDecode(contents);
    return (json['items'] as List).map((e) => TimelineItem.fromMap(e)).toList();
  }

  static Future putTimelineItems(
      int timelineHostId, int timelineId, String contents) async {
    final dir = await _localPath;
    final file = File(path.join(dir, '$timelineHostId-$timelineId.json'));
    await file.writeAsString(contents);
  }
}
