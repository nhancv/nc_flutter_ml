import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'image_picker_handler.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'detector_painters.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, ImagePickerListener {
  File _imageFile;
  AnimationController _controller;
  ImagePickerHandler imagePicker;
  String textRecog;

  Size _imageSize;
  dynamic _scanResults;
  Detector _currentDetector = Detector.text;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    imagePicker = ImagePickerHandler(this, _controller);
    imagePicker.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          PopupMenuButton<Detector>(
            onSelected: (Detector result) {
              _currentDetector = result;
              if (_imageFile != null) _scanImage(_imageFile);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Detector>>[
                  const PopupMenuItem<Detector>(
                    child: Text('Detect Barcode'),
                    value: Detector.barcode,
                  ),
                  const PopupMenuItem<Detector>(
                    child: Text('Detect Face'),
                    value: Detector.face,
                  ),
                  const PopupMenuItem<Detector>(
                    child: Text('Detect Label'),
                    value: Detector.label,
                  ),
                  const PopupMenuItem<Detector>(
                    child: Text('Detect Cloud Label'),
                    value: Detector.cloudLabel,
                  ),
                  const PopupMenuItem<Detector>(
                    child: Text('Detect Text'),
                    value: Detector.text,
                  ),
                ],
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => imagePicker.showDialog(context),
        child: Container(
          color: Colors.black,
          child: _imageFile == null
              ? Stack(
                  children: <Widget>[
                    Center(
                      child: Container(
                        color: const Color(0xFF778899),
                      ),
                    ),
                    Center(
                      child: Image.asset("assets/images/camera.png"),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 500,
                        child: _buildImage(),
                      ),
                      Text(
                        textRecog == null ? "--" : textRecog,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  @override
  userImage(File _image) async {
    setState(() {
      _imageFile = _image;
      _imageSize = null;
    });

    if (_imageFile != null) {
      _getImageSize(_imageFile);
      _scanImage(_imageFile);
    }
  }

  /// ML Process

  Future<void> _scanImage(File imageFile) async {
    setState(() {
      _scanResults = null;
    });

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    dynamic results;
    switch (_currentDetector) {
      case Detector.barcode:
        final BarcodeDetector detector =
            FirebaseVision.instance.barcodeDetector();
        results = await detector.detectInImage(visionImage);
        break;
      case Detector.face:
        final FaceDetector detector = FirebaseVision.instance.faceDetector();
        results = await detector.processImage(visionImage);
        break;
      case Detector.label:
        final LabelDetector detector = FirebaseVision.instance.labelDetector();
        results = await detector.detectInImage(visionImage);
        break;
      case Detector.cloudLabel:
        final CloudLabelDetector detector =
            FirebaseVision.instance.cloudLabelDetector();
        results = await detector.detectInImage(visionImage);
        break;
      case Detector.text:
        final TextRecognizer recognizer =
            FirebaseVision.instance.textRecognizer();
        results = await recognizer.processImage(visionImage);
        break;
      default:
        return;
    }

    setState(() {
      _scanResults = results;
    });
  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Image.file(_imageFile).image,
          fit: BoxFit.fill,
        ),
      ),
      child: _imageSize == null || _scanResults == null
          ? const Center(
              child: Text(
                'Scanning...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30.0,
                ),
              ),
            )
          : _buildResults(_imageSize, _scanResults),
    );
  }

  CustomPaint _buildResults(Size imageSize, dynamic results) {
    CustomPainter painter;
    String res;
    switch (_currentDetector) {
      case Detector.barcode:
        painter = BarcodeDetectorPainter(_imageSize, results);
        break;
      case Detector.face:
        painter = FaceDetectorPainter(_imageSize, results);
        break;
      case Detector.label:
        painter = LabelDetectorPainter(_imageSize, results);
        break;
      case Detector.cloudLabel:
        painter = LabelDetectorPainter(_imageSize, results);
        break;
      case Detector.text:
        painter = TextDetectorPainter(_imageSize, results);

        res = "";
        for (TextBlock block in results.blocks) {
          res += block.text + "\n\n";
        }
        break;
      default:
        break;
    }

    if (res != null) {
      setState(() {
        textRecog = res;
      });
    }

    return CustomPaint(
      painter: painter,
    );
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      (ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      },
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }
}
