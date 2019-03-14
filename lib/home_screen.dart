import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'image_picker_handler.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomeScreenState createState() => new _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, ImagePickerListener {
  File _image;
  AnimationController _controller;
  ImagePickerHandler imagePicker;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    imagePicker = new ImagePickerHandler(this, _controller);
    imagePicker.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          widget.title,
          style: new TextStyle(color: Colors.white),
        ),
      ),
      body: new GestureDetector(
        onTap: () => imagePicker.showDialog(context),
        child: new Center(
          child: _image == null
              ? new Stack(
                  children: <Widget>[
                    new Center(
                      child: new Container(
                        height: 160.0,
                        width: 320.0,
                        color: const Color(0xFF778899),
                      ),
                    ),
                    new Center(
                      child: new Image.asset("assets/images/camera.png"),
                    ),
                  ],
                )
              : new Container(
                  height: 160.0,
                  width: 320.0,
                  decoration: new BoxDecoration(
                    color: const Color(0xff7c94b6),
                    image: new DecorationImage(
                      image: new ExactAssetImage(_image.path),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.red, width: 5.0),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  userImage(File _image) async {
    setState(() {
      this._image = _image;
    });
  }
}
