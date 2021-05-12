import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
List<CameraDescription> cameras;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await  availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mask Up',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Mask Up '),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);



  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage cameraImage;
  CameraController cameraController;
  String result = "";

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController.startImageStream((imageStream) {
          cameraImage = imageStream;
          runModel();
        });
      });
    });
  }
  loadModel() async {
    await Tflite.loadModel(
        model: "assets/models/model_unquant.tflite", labels: "assets/models/labels.txt");
  }
  runModel() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);
      recognitions.forEach((element) {
        setState(() {
          result = element["label"];
          print(result);
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }
@override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(

        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'A simple face mask detector',
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height - 200,
              width: MediaQuery.of(context).size.width,
              child: !cameraController.value.isInitialized
                  ? Container()
                  : AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
          Text(
            result,
            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 25),
          )
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
