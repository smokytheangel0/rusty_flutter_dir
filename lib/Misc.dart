import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'dart:convert';

import "./main.dart" show TestCard;
class MiscView extends StatefulWidget {
  MiscView({Key key, this.title}) : super(key: key);
  
  final String title;

  @override
  MiscViewState createState() => MiscViewState();
}

class MiscViewState extends State<MiscView> {
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

      var input_list = inputs.split(",");
      var field_list = fields.split(",");
      var dart_args = {};
      var data_list = [];

      for (var arg in input_list) {
        if (arg.contains(".toString()")) {
          data_list.add(arg.substring(0, arg.indexOf(".toString()")));
        } else {
          int int_value = int.tryParse(arg);
          if (int_value == null) {
            double double_value = double.tryParse(arg);
            if (double_value == null) {
              data_list.add(arg);
            } else {
              data_list.add(double_value);
            }
          } else {
            data_list.add(int_value);
          }
        }
      }

      int field_data = 0;
      for (var field in field_list) {
        dart_args.putIfAbsent(field, () => data_list[field_data]);
        field_data += 1;
      }

      if (method.contains("stor")) {   
        dart_args.putIfAbsent("path", () => path);
      }

      String json_args = jsonEncode(dart_args);

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
            Text("NOT IMPLEMENTED")
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