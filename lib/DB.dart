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

  String path = "not set";

  String _heading = "From Dart:";
  Map output = {"result":"Err()", "data": "no returned value yet"};

  Map callRust(method, inputs) {
    DateTime round_trip_start = new DateTime.now();

    if (method.contains("stor")) {
      inputs.putIfAbsent("path", () => path);
    }

    String json_args = jsonEncode(inputs);

    print("~~~~~~~~~~~~");

    print("method: $method");
    print("sent to rust: \n $json_args");
    
    setState(() {
      final Future<String> returned = platform.invokeMethod(method, json_args);
      returned.then((returned_value) {
        print("returned from rust call: \n $returned_value");
        output = jsonDecode(returned_value);
        _heading = "From Rust:";
        var round_trip_end = new DateTime.now();
        var round_trip_elapsed = round_trip_end.difference(round_trip_start);
        print("${round_trip_elapsed.inMicroseconds} microseconds");

        print("~~~~~~~~~~~~");
        return output;
      });      
    });
  }

  @override
  Widget build(BuildContext context) {
    getApplicationDocumentsDirectory().then((working_directory){path = working_directory.path;});
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            TestCard(title: "init_storage", method: () { 
                callRust("init_storage", {"table": "names", "columns": "name"});
              }, padding: 50.0,
            key: ValueKey("init_storage_button")),

            TestCard(title: "delete_all", method: () {
                //cant call setState() inside build()
                callRust("search_storage", {"query": "DELETE FROM names WHERE name = ?", "data": ["TestCard"]});
              }, padding: 50.0,
            key: ValueKey("delete_storage_button")),

          ]
        ),
        Row(
          children: <Widget>[
            //the offset between message shown (via UI) and message received (via console) tends
            //to start here or the third button pushed and is accompanied xy
            TestCard(title: "store_one", method: () {              
                callRust("store", {"table": "names", "data": ["TestCard"]});
              }, padding: 50.0,
            key: ValueKey("store_one_button")),

            TestCard(title: "search_one", method: () {              
                callRust("search_storage", {"query": "SELECT * from names WHERE name = ?", "data": ["TestCard"]});              
              }, padding: 50.0,
              key: ValueKey("search_one_button")),
          ],
        ),

        Row(
          children: <Widget>[
            TestCard(title: "store_many_strings", padding: 20.0),

            TestCard(title: "search_many_strings", padding: 20.0),
          ],
        ),
        Row(
          children: <Widget>[
            TestCard(title: "store_different", padding: 35.0),
            
            TestCard(title: "search_different", padding: 35.0),
          ],
        ),
        Row(
          children: <Widget> [
            Text(_heading)
          ]
        ),
        Row(
          children: <Widget> [
              Flexible( 
              child: Text(output["result"],
                            softWrap: true,
                            key: ValueKey("result_text"))
            )

          ]
        ),
        Row(
          children: <Widget> [
            Flexible( 
              child: Text(output["data"].toString(),
                            softWrap: true,
                            key: ValueKey("data_text"))
            )

          ]
        )

      ],
    );
  }
}
//callRust("store", {"table": "name", "data": ["TestCard"]})