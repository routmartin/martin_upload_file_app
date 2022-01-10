import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'api_service.dart';

void main() {
  runApp(const MaterialApp(
    home: HomePage(),
    debugShowCheckedModeBanner: false,
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

enum UploadingState { init, selected, uploading, error, comepleted }

class _HomePageState extends State<HomePage> {
  CancelToken _token = CancelToken();
  List<XFile>? _fileList = [];
  List<Media>? _mediaModelList = [];
  List<Presign>? _presignList = [];
  List<int>? _uploadSuccessList = [];
  UploadingState _uploadState = UploadingState.init;
  int _uploadIndex = 0;
  int _uploadPercentage = 0;

  void _updatePercentage(int percentage) {
    _uploadPercentage = percentage;
    setState(() {});
  }

  void _clearLocalStore() {
    _fileList?.clear();
    _presignList?.clear();
    _mediaModelList?.clear();
    _uploadSuccessList?.clear();
  }

  void _selectFile() async {
    _clearLocalStore();
    _uploadIndex = 0;
    _fileList = await ImagePicker().pickMultiImage();
    if (_fileList != null) {
      _uploadState = UploadingState.selected;
      _fileList!.forEach((file) {
        String? _extension = extension(file.path).split('.').last;
        String? _fileName = file.path.split('/').last;
        _mediaModelList!.add(Media(_extension, 'profile', _fileName));
      });
      setState(() {});
    }
  }

  void _uploadFunction() async {
    /// register path on server
    _uploadState = UploadingState.uploading;
    setState(() {});
    try {
      PresignResponese? _res =
          await apiService.presignUploadApi(_mediaModelList!);
      if (_res != null) {
        _presignList = _res.data;
        _putfileToServer();
      } else {
        _uploadState = UploadingState.error;
        setState(() {});
      }
    } catch (e) {
      _uploadState = UploadingState.error;
      setState(() {});
    }
  }

  void _putfileToServer() async {
    if (_uploadState == UploadingState.uploading) {
      _token = new CancelToken();
    }
    if (_uploadIndex < _fileList!.length) {
      try {
        bool _apiResponse = await apiService.uploadFile(
            _fileList![_uploadIndex],
            _presignList![_uploadIndex].uploadUrl,
            _updatePercentage,
            _token);
        if (_apiResponse) {
          _uploadSuccessList?.add(_uploadIndex);
          setState(() {});
          _uploadIndex += 1;
          _uploadPercentage = 0;
          _putfileToServer();
        } else {
          _uploadState = UploadingState.error;
          setState(() {});
        }
      } catch (e) {
        print('handle upload error here: $e');
        _uploadState = UploadingState.error;
        setState(() {});
      }
    } else {
      _uploadState = UploadingState.comepleted;
      setState(() {});
    }
  }

  void _retryUploading() {
    _uploadState = UploadingState.uploading;
    _putfileToServer();
  }

  void _removeUploading(int index) {
    _fileList!.removeAt(index);
    setState(() {});
  }

  void _pauseUploading() {
    _token.cancel();
  }

  void _actionHandler() {
    switch (_uploadState) {
      case UploadingState.init:
        return print('please select the files');
      case UploadingState.selected:
        return _uploadFunction();
      case UploadingState.comepleted:
        return _uploadFunction();
      default:
        return _retryUploading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Column(
            children: <Widget>[
              SizedBox(height: 12),
              Container(
                height: 100,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _selectFile,
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: Radius.circular(10),
                        dashPattern: [10, 4],
                        strokeCap: StrokeCap.round,
                        color: Colors.blue.shade400,
                        child: Container(
                          width: MediaQuery.of(context).size.width * .6,
                          height: 200,
                          child: _uploadState == UploadingState.init
                              ? Icon(
                                  Iconsax.folder_open,
                                  color: Colors.blue,
                                  size: 30,
                                )
                              : Center(
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      " ${_uploadSuccessList!.length} / ${_fileList!.length}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ],
                                )),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _actionHandler,
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: Radius.circular(10),
                          dashPattern: [10, 4],
                          strokeCap: StrokeCap.round,
                          color: Colors.blue.shade400,
                          child: Container(
                            alignment: Alignment.center,
                            height: 200,
                            child: _iconBuilder(),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _fileList?.length,
                    addAutomaticKeepAlives: true,
                    cacheExtent: 10,
                    itemBuilder: (ctx, index) {
                      XFile? image = _fileList?[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                                spreadRadius: 2,
                              )
                            ]),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(image!.path),
                                    width: 150,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                _onImageIconBuilder(index),
                              ],
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    image.path.split('/').last,
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.black),
                                  ),
                                  SizedBox(height: 15),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                          ],
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _onImageIconBuilder(int index) {
    Widget? _returnWidget;
    if (_uploadSuccessList!.contains(index)) {
      _returnWidget = Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(.7),
            borderRadius: BorderRadius.all(Radius.circular(40)),
            border: Border.all(color: Colors.grey.shade700)),
        child: Icon(Icons.done, color: Colors.white, size: 30),
      );
    } else if (_uploadState == UploadingState.uploading &&
        _uploadIndex == index) {
      _returnWidget = InkWell(
        onTap: _pauseUploading,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            color: Colors.black.withOpacity(.7),
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          child: Text(
            '$_uploadPercentage',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (_uploadState == UploadingState.error && _uploadIndex == index) {
      _returnWidget = InkWell(
        onTap: _retryUploading,
        child: _returnWidget = Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(.7),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              border: Border.all(color: Colors.grey.shade700)),
          child: Icon(Icons.upload_sharp, color: Colors.white, size: 30),
        ),
      );
    } else {
      _returnWidget = InkWell(
        onTap: () => _removeUploading(index),
        child: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.7),
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          child: Icon(Icons.close, color: Colors.white, size: 30),
        ),
      );
    }
    return _returnWidget;
  }

  Widget _iconBuilder() {
    switch (_uploadState) {
      case UploadingState.uploading:
        return CircularProgressIndicator(strokeWidth: .8);
      case UploadingState.error:
        return Icon(
          Iconsax.refresh_right_square,
          color: Colors.red,
          size: 30,
        );
      default:
        return Icon(
          Iconsax.document_upload,
          color: Colors.blue,
          size: 30,
        );
    }
  }
}
