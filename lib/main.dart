import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:newmap/entry.dart';
import 'package:newmap/map_page.dart';
import 'package:newmap/widgets.dart';
import 'db.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late List<Entry> _data;
  List<EntryCard> _cards = [];
  late DB db;

  void initState() {
    db = DB();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      db.init().then((value) => _fetchEntries());
    });
    super.initState();
  }

  void _fetchEntries() async {
    _cards = [];

    try {
      List<Map<String, dynamic>> _results = await db.query(Entry.table);
      _data = _results.map((item) => Entry.fromMap(item)).toList();
      _data.forEach((element) => _cards.add(EntryCard(entry: element)));
      setState(() {});
    } catch (e) {
      print(e.toString());
    }
  }

  void _addEntries(Entry en) async {
    db.insert(Entry.table, en);
    _fetchEntries();
  }


  Future<Position?> getPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    Position? position = await Geolocator.getLastKnownPosition();
    {
      if (position != null) {
        return position;
      } else {
        return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      }
    }
  }

// Alert dialog opening when getPermission() return null
  Future<void> showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attention'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Please Open Your Location'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 3,
                  child: FloatingActionButton(
                    onPressed: () async {
                      Position? pos = await getPermission();
                      if (pos != null) {
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const MapPage()))
                            .then((value) => _addEntries(value));
                      } else {
                        showMyDialog();
                      }
                    },
                    backgroundColor: Colors.greenAccent,
                    child: Column(
                      children: [
                        Icon(
                          Icons.add,
                          size: 32,
                        ),
                        Text("Add New")
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  "History :",
                  style: TextStyle(fontSize: 20),
                ),
                _cards.isEmpty
                    ? Text("No Previous Track Record!!!")
                    : Expanded(
                        // height: 300,
                        child: ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: _cards.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                elevation: 5,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _cards[index]
                                                  .entry
                                                  .date
                                                  .toString(),
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                                "Duration : ${_cards[index].entry.duration}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                "Distance (Km) : ${(_cards[index].entry.distance! / 1000).toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                                "Speed (Km/Hours) : ${_cards[index].entry.speed!.toStringAsFixed(2)}",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      ),
              ]),
        ),
      ),
    );
  }
}
