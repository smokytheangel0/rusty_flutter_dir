import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'dart:convert';

import "./main.dart" show TestCard;
class NetView extends StatefulWidget {
  NetView({Key key, this.title}) : super(key: key);
  
  final String title;

  @override
  NetViewState createState() => NetViewState();
}

class NetViewState extends State<NetView> {
  static const platform = const MethodChannel('rust');

  String _heading = "From Dart:";
  String method = "";
  String inputs = "";
  String fields = "";
  String output = "no returned value yet";
  String path = "not set";

  Null callRust(method, inputs) {
      DateTime round_trip_start = new DateTime.now();

      //instead of dealing with string pairs just use a string and a dict
      //then you have your fields and your args already to be jsonified...duh

      String json_args = jsonEncode(inputs);

      print(json_args);

    setState(() {
      //eventually when we use deserialization on this side, if the deserializeation fails
      //the returned string ought to be printed to the console is it is likely to be an error
      final Future<String> result = platform.invokeMethod(method, json_args);
      result.then((returned_value) {
        _heading = "From Rust:";
        output = returned_value;
      });
      
    });

    var round_trip_end = new DateTime.now();
    var round_trip_elapsed = round_trip_end.difference(round_trip_start);
    print(round_trip_elapsed.inMicroseconds);
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget> [
        Row(
          children: <Widget>[
            TestCard(title: "send_data", method: callRust("send", {"table": "name", "data": ["TestCard"]})),
            TestCard(title: "get_data"),
          ]
        ),
        Row(
          children: <Widget> [
            Text(output)
          ]
        )
      ]
    );
  }
}