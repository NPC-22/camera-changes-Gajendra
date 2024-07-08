
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:onboarding_app/network/models/HttpReposonceHandler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as myVideoThumbNail;
import 'package:video_thumbnail/video_thumbnail.dart';

import 'controllers/GuideController/guide-controller.dart';
import 'network/repository/auth/auth_repo.dart';

class FlutterCamera extends StatefulWidget {
  final Color? color;
  final Color? iconColor;
  final Function(XFile)? onVideoRecorded;
  final Duration? animationDuration;
  final String question;

  const FlutterCamera({
    Key? key,
    this.animationDuration = const Duration(seconds: 1),
    this.onVideoRecorded,
    this.iconColor = Colors.white,
    required this.color,
    this.question = "Question Not Found Restart",
  }) : super(key: key);

  @override
  _FlutterCameraState createState() => _FlutterCameraState();
}

class _FlutterCameraState extends State<FlutterCamera> {
  late Timer _timer;
  int _start = 30;
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool _isTouchOn = false;
  bool _isFrontCamera = false;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isCameraInitialized = false;
  final GuideController? _guidecontroller = Get.put(GuideController());
  XFile? videoUrl;
  late var thumbnailPath;
  late CameraDescription frontCamera;
  late var question;
  bool isStartRecordingBtnEnabled = true;
  bool isStopRecordingBtnEnabled = false;
  bool isUploadRecordingBtnEnabled = false;
  bool isCamerStartButtonPressed = false;
  late String len;
  bool isVideoRecorded = false;
  bool isVideoRecording = false;
  String displayText = "Cancel";
  bool _isCircularIndicatorLoading = false;


  @override
  void initState() {
    super.initState();
    initCamera().then((_) {
      setCamera(1);
    });
  }
  Future<void> initCamera() async {
    cameras = await availableCameras();
    setState(() {});
  }

  void setCamera(int index) {
    controller = CameraController(cameras![index], ResolutionPreset.max);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  String updateText(int value) {
    setState(() {
      question = _guidecontroller!.quesList[value].question.toString();
      print("question $question");
    });
    return question;
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: videoView(),
    );
  }

  String displayNextQuestion() {
    var value = _guidecontroller?.changeListIndextoNext();
    return updateText(value!);
  }

  Widget displayQuestionsandDoVideoRecording() {
    String question = updateText(_guidecontroller!.idx.value);
    int maxLines = (question.length / 20).ceil();

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(question,
              maxLines: maxLines,
              textAlign: TextAlign.start, // Align text to the start (left)
              style: TextStyle(fontSize: 16.0, color: Colors.black)),
        ),
        body: Column(
          children: <Widget>[
            Container(
              child: ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 10), // Adjust the padding as needed
                  ),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.orange),
                ),
                child: Text('Next Question',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal)),
                onPressed: () {
                  var value = _guidecontroller?.changeListIndextoNext();
                  updateText(value!);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(left: 5, right: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text("00:" + '${_start.toString().padLeft(2, '0')}'),
                ),
              ],
            ),
            Container(
              height: 300,
              width: 300,
              child: _isCameraInitialized
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: CameraPreview(controller!),
                    )
                  : Container(
                      decoration: BoxDecoration(
                      color: Colors.white,
                    )),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 20), // Top Margin
                  child: ElevatedButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 10,
                            bottom: 10), // Adjust the padding as needed
                      ),
                      backgroundColor: isStartRecordingBtnEnabled
                          ? MaterialStateProperty.all<Color>(Colors.green)
                          : MaterialStateProperty.all<Color>(Colors.grey),
                    ),
                    child: Text(
                      'Start Recording',
                      style: isStartRecordingBtnEnabled
                          ? TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.normal)
                          : TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.normal),
                    ),
                    onPressed: () {
                      isCamerStartButtonPressed = true;
                      initCamera().then((_) {
                        setCamera(1);
                      });
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 20), // Top Margin
                  child: ElevatedButton(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 10,
                            bottom: 10), // Adjust the padding as needed
                      ),
                      backgroundColor: isStopRecordingBtnEnabled
                          ? MaterialStateProperty.all<Color>(Colors.orange)
                          : MaterialStateProperty.all<Color>(Colors.grey),
                    ),
                    child: Text('Stop Recording',
                        style: isStopRecordingBtnEnabled
                            ? TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.normal)
                            : TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.normal)),
                    onPressed: () {
                      _start = 00;
                      stopRecording();
                    },
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 20), // Top Margin
              child: ElevatedButton(
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 10), // Adjust the padding as needed
                  ),
                  backgroundColor: isUploadRecordingBtnEnabled
                      ? MaterialStateProperty.all<Color>(Colors.orange)
                      : MaterialStateProperty.all<Color>(Colors.grey),
                ),
                child: Text('Upload Video',
                    style: isUploadRecordingBtnEnabled
                        ? TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.normal)
                        : TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.normal)),
                onPressed: () {
                  uploadVideo();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void reTake() {
    setState(() {
      _start = 00;
      isVideoRecording = false;
      _isRecording = false;
      isVideoRecorded = false;
      displayText = 'Cancel';
    });
  }

  Widget videoView() {
    question = updateText(_guidecontroller!.idx.value);
    int maxLines = (question.length / 20).ceil();
    return Stack(
      key: const ValueKey(1),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: CameraPreview(controller!),
        ),
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.only(
                top: 40, bottom: 10.0, left: 7.0, right: 7.0),
            width: MediaQuery.of(context).size.width,
            color: widget.color,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          _isRecording == false
                              ? '00:00:00'
                              : "00:00:" +
                              '${_start.toString().padLeft(2, '0')}',
                          style:
                          TextStyle(color: widget.iconColor, fontSize: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 21.0,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20),
            color: widget.color,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    print("isVideoRecorded $isVideoRecorded");
                    isVideoRecorded ? reTake() : Navigator.pop(context);
                  },
                  child: _isRecording
                      ? Container()
                      : Text(displayText,
                      style: TextStyle(
                          color: widget.iconColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'VIDEO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: widget.iconColor, fontSize: 14.0),
                    ),
                    SizedBox(height: 10),
                    _isRecording
                        ? stopVideoButtonLatest2()
                        : stopAndStartVideoButtonLatest(),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    print("isVideoRecorded $isVideoRecorded");
                    isVideoRecorded ? uploadVideo() : displayNextQuestion();
                  },
                  child: isVideoRecording
                      ? Container()
                      : Text(
                    isVideoRecorded ? 'Upload\nVideo' : 'Next\nQuestion',
                    style: TextStyle(
                      color: widget.iconColor,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                ),
              ],
            ),
          ),
        )
      ],
    );
  }


  void stopAndStartVideoButton() {
    if (_isRecording == false) {
      _start = 30;
      startTimer();
      controller?.startVideoRecording();
      _isRecording = true;
    } else {
      controller?.stopVideoRecording().then((value) {
        widget.onVideoRecorded!(value);
        videoUrl = value;
      });
      _isRecording = false;
    }
    setState(() {
      isStartRecordingBtnEnabled = false;
      isStopRecordingBtnEnabled = true;
      isUploadRecordingBtnEnabled = false;
    });
  }

  Future<void> stopRecording() async {
    try {
      setState(() {
        isStartRecordingBtnEnabled = false;
        isStopRecordingBtnEnabled = false;
        isUploadRecordingBtnEnabled = true;
      });

      final videoPath = await controller?.stopVideoRecording();
      videoUrl = videoPath!;
      final path = videoUrl?.path;
      getVideoDuration(path!);
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print(e);
    }
  }

  Widget stopAndStartVideoButtonLatest() {
    print("start $isVideoRecording");
    print("_isRecording $_isRecording");
    IconData playOrPauseIcon = Icons.play_circle;
    // if (isVideoRecording = true) {
    //   playOrPauseIcon = Icons.stop_circle;
    // } else {
    //   playOrPauseIcon = Icons.play_circle;
    // }
    return IconButton(
      onPressed: () {
        isVideoRecording = true;
        if (_isRecording == false) {
          startTimer();
          controller!.startVideoRecording();
          _isRecording = true;
          playOrPauseIcon = Icons.stop_circle;
        } else {
          controller!.stopVideoRecording().then((value) {
            videoUrl = value;
            widget.onVideoRecorded!(value);
          });
          _isRecording = false;
          playOrPauseIcon = Icons.play_circle;
        }
        //   setState(() {});
      },
      icon: Icon(
        playOrPauseIcon,
        color: widget.iconColor,
        size: 50,
      ),
    );
  }

  Widget stopVideoButtonLatest2() {
    print("start stop called $isVideoRecording");

    return IconButton(
      icon: Icon(
        isVideoRecorded ? Icons.play_arrow : Icons.stop_circle,
        //  Icons.play_circle,
        color: widget.iconColor,
        size: 50,
      ),
      onPressed: () {
        isVideoRecording = false;
        isVideoRecorded = true;
        displayText = "Retake";
        print("stop called on pressed");
        print(_isRecording);
        if (_isRecording == false) {
          startTimer();
          controller!.startVideoRecording();
          _isRecording = true;
        } else {
          controller!.stopVideoRecording().then((value) {
            videoUrl = value;
            final path = videoUrl?.path;
            getVideoDuration(path!);
            // Navigator.pop(context);
            // widget.onVideoRecorded!(value);
          });
          _isRecording = false;
        }
        setState(() {});
      },
    );
  }

  Widget stopButtonLatest() {
    return IconButton(
      onPressed: () {
        if (_isRecording == true) {
          controller!.stopVideoRecording().then((value) {
            // Navigator.pop(context);
            widget.onVideoRecorded!(value);
          });
          _isRecording = false;
          setState(() {});
        }
      },
      icon: Icon(
        Icons.stop,
        color: widget.iconColor,
        size: 50,
      ),
    );
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 00) {
          setState(() {
            _isRecording = false;
            timer.cancel();
          });
        } else {
          if (mounted) {
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }

  Future<void> getVideoDuration(String videoPath) async {
    VideoPlayerController controller = VideoPlayerController.network(videoPath);
    await controller.initialize();
    Duration duration = controller.value.duration;
    len = duration.inSeconds.toString();
    controller.dispose();
  }

  Future<void> uploadVideo() async {
    _isCircularIndicatorLoading=true;
    if(_isCircularIndicatorLoading){
      CircularProgressIndicator();
    }
    var currentId = _guidecontroller?.currentId =
        _guidecontroller?.quesList[_guidecontroller!.idx.value].id ??
            "1308b0cb-5921-420c-8bec-a3a26206c9b5";
    var currentQuestion = _guidecontroller?.currentQuestion =
        _guidecontroller?.quesList[_guidecontroller!.idx.value].question ??
            "Interview Question";
    final path = videoUrl?.path;
    if (path!.contains(".mp4")) {
      setState(() {
        isStartRecordingBtnEnabled = false;
        isStopRecordingBtnEnabled = false;
        isUploadRecordingBtnEnabled = true;
        _isCircularIndicatorLoading=false;
      });
      thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: path,
        imageFormat: myVideoThumbNail.ImageFormat.PNG,
        maxHeight: 200,
        quality: 50,
      );

      HttpResponse httpResponse = await UserRepo()
          .uploadVideos(currentQuestion!, len, thumbnailPath, path, currentId!);

      if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
        print("Video Uploaded Successfully flutter camera");
        Fluttertoast.showToast(
            msg: "Video Uploaded Successfully!!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);

        setState(() {
          var value = _guidecontroller?.changeListIndextoNext();
          updateText(value!);
          _start = 30;
          videoUrl = null;
          isStartRecordingBtnEnabled = false;
          isStopRecordingBtnEnabled = false;
          isUploadRecordingBtnEnabled = false;
        });
        //  Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
            msg: "Something went wrong!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    } else {
      Fluttertoast.showToast(
          msg: "Something went wrong!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }
}


