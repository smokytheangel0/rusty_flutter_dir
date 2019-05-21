import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import "./DB.dart" as db;
import "./Net.dart" as net;
import "./Misc.dart" as misc;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: MyHomePage(title: 'RustyFlutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  
  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with
  SingleTickerProviderStateMixin {
  static const platform = const MethodChannel('rust');

  TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(vsync: this, length: 3);
  }

  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: controller,
          tabs: <Tab> [
            Tab(
              text: "DB"
            ),
            Tab(
              text: "Net"
            ),
            Tab(
              text: "Misc"
            )
          ]
        )
      ),
      body: new TabBarView(
        controller: controller,
        children: <Widget> [
          db.DBView(),
          net.NetView(),
          misc.MiscView()
        ]
      )
    );
  }
}

class TestCard extends StatelessWidget {
  final String title;
  final method;
  final padding;
  final ValueKey key;

  TestCard({this.title, this.method, this.padding, this.key});
  

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(this.padding),
      child: Card(
        child: Ink(
          child: FlatButton(
            child: Text(this.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: "OpenSans",
                fontSize: 12
              )
            ),
            onPressed: this.method,
            key: this.key
          )
        )
      ),       
    );
  }
}

