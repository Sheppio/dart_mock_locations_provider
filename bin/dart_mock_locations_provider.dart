import 'dart:async';
import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'gpx_routes.dart';
import 'location_report.dart';

void main(List<String> arguments) {
  var webSocketUri = 'ws://127.0.0.1:8080';

  var ml1 = MockLocation(
      id: "Runner_1",
      webSocketUri: webSocketUri,
      path: MockLocation.pathFromGpx(GpxRoutes.RusheyChalfontLoop),
      updateDurationSeconds: 1,
      speed: 3);
  ml1.start();

  var ml2 = MockLocation(
      id: "Runner_2",
      webSocketUri: webSocketUri,
      path: MockLocation.pathFromGpx(GpxRoutes.RusheyCustbushLoop),
      startIndex: 0,
      updateDurationSeconds: 1,
      speed: 5);
  ml2.start();

  var ml3 = MockLocation(
      id: "Runner_3",
      webSocketUri: webSocketUri,
      path: MockLocation.pathFromGpx(GpxRoutes.RadstockLoop),
      updateDurationSeconds: 1,
      speed: 10);
  ml3.start();

  // create gpx from xml string
  // var xmlGpx = GpxReader().fromString(GpxRoutes.RusheyChalfontLoop);

  // var trkPts = xmlGpx.trks[0].trksegs[0].trkpts;
  // trkPts.add(trkPts[0]);

  // var path = Path.from(
  //     trkPts.map((e) => LatLng(e.lat as double, e.lon as double)).toList());
  // var distance = path.distance;
  // var equalizedPoints = path.equalize(2.0);

  // Make route have less points if need...
  //equalizedPoints = Path.from(equalizedPoints.coordinates.take(3));

  // equalizedPoints.coordinates.forEach(((element) {
  //   print(element);
  // }));
  // print("Count: ${equalizedPoints.coordinates.length}");
  // print(distance);

  // int index = 0;

  // final channel = WebSocketChannel.connect(
  //   Uri.parse('ws://127.0.0.1:8080'),
  // );

  // channel.sink.add('Hello!');

  // Timer.periodic(Duration(seconds: 2), ((timer) {
  //   var pt = equalizedPoints.coordinates[index];
  //   //var latlng = LatLng(pt.latitude, pt.longitude);
  //   //print(latlng.toJson());
  //   //print(jsonEncode(latlng));
  //   var lr = LocationReport(
  //     timestamp: DateTime.now(),
  //     id: "Runner_1",
  //     latitude: pt.latitude,
  //     longitude: pt.longitude,
  //     // elevation: 0,
  //     accuracy: 3.0,
  //     // heading: 0,
  //     // speed: 1.0,
  //   );
  //   var messageToServer = "LOCATION_REPORT#${jsonEncode(lr)}";
  //   print(messageToServer);
  //   channel.sink.add(messageToServer);
  //   index++;
  //   index = index % equalizedPoints.coordinates.length;
  // }));
}

class MockLocation {
  static Path pathFromGpx(String gpxString) {
    var xmlGpx = GpxReader().fromString(gpxString);
    var trkPts = xmlGpx.trks[0].trksegs[0].trkpts;
    trkPts.add(trkPts[0]);
    var path = Path.from(
        trkPts.map((e) => LatLng(e.lat as double, e.lon as double)).toList());
    return path;
  }

  final String _id;
  //String _info;
  Timer? _t;
  final Path _path;
  Duration _updateDuration;
  final double _speed;
  int _index;
  final WebSocketChannel _channel;
  final Path _equalizedPoints;

  MockLocation(
      {required String id,
      required String webSocketUri,
      required Path path,
      int updateDurationSeconds = 1,
      double speed = 1.0,
      int startIndex = 0})
      : _id = id,
        _path = path,
        _updateDuration = Duration(seconds: updateDurationSeconds),
        _speed = speed,
        _index = startIndex,
        _channel = WebSocketChannel.connect(
          Uri.parse(webSocketUri),
        ),
        _equalizedPoints = path.equalize(updateDurationSeconds * speed);

  start() {
    print("MockLocation ($_id) starting");
    _t = Timer.periodic(_updateDuration, ((timer) {
      var pt = _equalizedPoints.coordinates[_index];
      var lr = LocationReport(
        timestamp: DateTime.now(),
        id: _id,
        latitude: pt.latitude,
        longitude: pt.longitude,
        // elevation: 0,
        accuracy: 3.0,
        // heading: 0,
        // speed: 1.0,
      );
      var messageToServer = "LOCATION_REPORT#${jsonEncode(lr)}";
      print(messageToServer);
      _channel.sink.add(messageToServer);
      _index++;
      _index = _index % _equalizedPoints.coordinates.length;
    }));
  }

  stop() {
    _t?.cancel();
  }
}
