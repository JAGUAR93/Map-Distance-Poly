import 'package:flutter/material.dart';
import "entry.dart";

class EntryCard extends StatelessWidget {
  final Entry entry;
  EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.date!, style: TextStyle(fontSize: 18)),
                  Text("${(entry.distance! / 1000).toStringAsFixed(2)} km",
                      style: TextStyle(fontSize: 18)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.duration!,
                      style: TextStyle(fontSize: 14)),
                  Text("${entry.speed!.toStringAsFixed(2)} km/h",
                      style: TextStyle(fontSize: 14)),
                ],
              )
            ],
          )),
    );
  }
}