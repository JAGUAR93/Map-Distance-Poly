import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:newmap/entry.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Set<Polyline> polyline = {};
  List<LatLng> route = [];
  double dist = 0;
  late String displayTime;
  late int time;
  late int lastTime;
  double speed = 0;
  double avgSpeed = 0;
  int speedCounter = 0;
  late bool loadingStatus;
  late double appendDist;
  LatLng sourceLocation = LatLng(38.432199, 27.177221);
  Position? currentPosition;
  final Completer<GoogleMapController?> controller = Completer();
  final StopWatchTimer stopWatchTimer = StopWatchTimer();
  var mapStyle;
  late StreamSubscription<Position> positionStream;

  @override
  void initState() {
    route.clear();
    polyline.clear();
    dist = 0;
    time = 0;
    lastTime = 0;
    speed = 0;
    avgSpeed = 0;
    speedCounter = 0;
    appendDist = 0;
    stopWatchTimer.onExecute.add(StopWatchExecute.reset);
    stopWatchTimer.clearPresetTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrentPosition();
    });
    stopWatchTimer.onExecute.add(StopWatchExecute.start);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    stopWatchTimer.dispose();
  }

  Future<void> getCurrentPosition() async {
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {});
    if (currentPosition != null) {
      late LocationSettings locationSettings;
      locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5);

      positionStream =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position? position) async {
        print(position == null
            ? 'Unknown'
            : '${position.latitude.toString()}, ${position.longitude.toString()}');
        currentPosition = position;

        if (route.isNotEmpty) {
          appendDist = Geolocator.distanceBetween(route.last.latitude,
              route.last.longitude, position!.latitude, position.longitude);
          dist = dist + appendDist;
          int timeDuration = (time - lastTime);

          if (lastTime != null && timeDuration != 0) {
            speed = (appendDist / (timeDuration / 100)) * 3.6;
            if (speed != 0) {
              avgSpeed = avgSpeed + speed;
              speedCounter++;
            }
          }
        }
        lastTime = time;

        if (route.isNotEmpty) {
          if (route.last != LatLng(position!.latitude, position.longitude)) {
            route.add(LatLng(position.latitude, position.longitude));

            polyline.add(Polyline(
                polylineId: PolylineId(position.toString()),
                visible: true,
                points: route,
                width: 6,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                color: Color.fromARGB(255, 72, 173, 240)));
          }
        } else {
          route.add(LatLng(position!.latitude, position.longitude));
        }

        setState(() {});
      });
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: currentPosition == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(children: [
                GoogleMap(
                  polylines: polyline,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(currentPosition!.latitude,
                          currentPosition!.longitude),
                      zoom: 17.5),
                  onMapCreated: (mapController) {
                    mapController.setMapStyle(mapStyle);
                    if (controller.isCompleted) {
                      controller.complete(mapController);
                      setState(() {});
                    }
                    setState(() {});
                  },
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                      height: 125,
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Speed (Km/Hours)",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall!
                                        .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300),
                                  ),
                                  Text(
                                    speed.toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall!
                                        .copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w300),
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Duration",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall!
                                        .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300),
                                  ),
                                  StreamBuilder<int>(
                                    stream: stopWatchTimer.rawTime,
                                    initialData: 0,
                                    builder: (context, snap) {
                                      time = snap.data!;
                                      displayTime =
                                          "${StopWatchTimer.getDisplayTimeHours(time)}:${StopWatchTimer.getDisplayTimeMinute(time)}:${StopWatchTimer.getDisplayTimeSecond(time)}";
                                      return Text(
                                        displayTime,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall!
                                            .copyWith(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w300),
                                      );
                                    },
                                  )
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Distance (Km)",
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall!
                                        .copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w300),
                                  ),
                                  Text(
                                    (dist / 1000).toStringAsFixed(2),
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall!
                                        .copyWith(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w300),
                                  )
                                ],
                              )
                            ],
                          ),
                          const Divider(),
                          InkWell(
                            child: Icon(
                              Icons.stop_circle_outlined,
                              size: 45,
                              color: Colors.redAccent,
                            ),
                            onTap: () async {
                              Entry en = Entry(
                                  date: DateFormat.yMMMMd()
                                      .format(DateTime.now()),
                                  duration: displayTime,
                                  speed: speedCounter == 0
                                      ? 0
                                      : avgSpeed / speedCounter,
                                  distance: dist);
                              //  positionStream.cancel();
                              Navigator.pop(context, en);
                            },
                          ),
                        ],
                      ),
                    ))
              ]));
  }
}
