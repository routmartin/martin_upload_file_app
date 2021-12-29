import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController loadingController;

  PresignApi _uploadApiService = PresignApi();

  List<File>? _file = [];
  List<String>? _filesName = [];

  _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result != null) {
      _file = result.paths.map((String? path) => File(path!)).toList();
      _filesName = result.names.map((e) => e).cast<String>().toList();
    }
    setState(() {});
    loadingController.forward();
  }

  _uploadFunction() {}

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
                          child: Icon(
                            Iconsax.folder_open,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectFile,
                        child: DottedBorder(
                          borderType: BorderType.RRect,
                          radius: Radius.circular(10),
                          dashPattern: [10, 4],
                          strokeCap: StrokeCap.round,
                          color: Colors.blue.shade400,
                          child: Container(
                            alignment: Alignment.center,
                            height: 200,
                            child: Icon(
                              Iconsax.document_upload,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _file?.length,
                  itemBuilder: (ctx, index) =>
                      _buildUploadCard(_file?[index], _filesName?[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

_buildUploadCard(File? image, String? name) {
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
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                image!,
                width: 150,
                height: 100,
                fit: BoxFit.cover,
              )),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: TextStyle(fontSize: 13, color: Colors.black),
                ),
                SizedBox(height: 5),
                // Container(
                //     height: 5,
                //     clipBehavior: Clip.hardEdge,
                //     decoration: BoxDecoration(
                //       borderRadius: BorderRadius.circular(5),
                //       color: Colors.blue.shade50,
                //     ),
                //     child: LinearProgressIndicator(
                //       value: loadingController.value,
                //     )),
              ],
            ),
          ),
          SizedBox(width: 10),
        ],
      ));
}
