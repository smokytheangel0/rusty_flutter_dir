import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import "./main.dart" show TestCard;

class DBView extends StatefulWidget {
  DBView({Key key, this.title}) : super(key: key);
  
  final String title;

  @override
  DBViewState createState() => DBViewState();
}

class DBViewState extends State<DBView> {
  static const platform = const MethodChannel('rust');
  Map output = {"result":"Err()", "data": "no returned value yet"};
  String _heading = "From Dart:";
  //having this as a class variable seems to work albeit in an almost unacceptably spooky way
  

  void callRust(method, inputs) {
    String json_args = jsonEncode(inputs);
   
    setState(() {
      final Future<String> returned = platform.invokeMethod(method, json_args);
      returned.then((returned_value) {
        //setting this here causes it to properly change the state
        output = jsonDecode(returned_value);
        _heading = "From Rust:";
      });      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget> [
        Row(
          children: <Widget>[
            TestCard(title: "init_storage", method: () {
                callRust("init_storage", {"table": "names", "columns": "name"});
              }, padding: 1.0,
            key: ValueKey("init_storage_button")),
          ]
        ),
        Row(
          children: <Widget> [
            Text(_heading)
          ]
        ),
        Row(
          children: <Widget> [
            Text(output["result"], key: ValueKey("result_text"))
          ]
        ),
        Row(
          children: <Widget> [
            Text(output["data"].toString(), key: ValueKey("data_text"))
          ]
        )
      ]
    );
  }
}
