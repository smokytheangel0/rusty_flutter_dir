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

  //these are never altered by setState() that happens at line 46
  String _heading = "From Dart:";
  String result_text = "Err()";
  String data_text = "no returned value yet";
  

  dynamic callRust(method, inputs) {
    String json_args = jsonEncode(inputs);
    
    setState(() {
      //this all works, evidenced by prints removed to keep this minimal
      final Future<String> returned = platform.invokeMethod(method, json_args);
      returned.then((returned_value) {
        var output = jsonDecode(returned_value);
        return output;
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
                var output = callRust("init_storage", {"table": "names", "columns": "name"});
                if (output["result"] == "Ok()") {
                  setState(() {
                    //setting the class vars from here never seems to cause rebuild
                    _heading = "From Rust:";
                    result_text = output["result"];
                    data_text = output["data"];
                  });
                } else {
                  print("init storage has gone wrong");
                }        
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
            Text(result_text, key: ValueKey("result_text"))
          ]
        ),
        Row(
          children: <Widget> [
            Text(data_text, key: ValueKey("data_text"))
          ]
        )
      ]
    );
  }
}
