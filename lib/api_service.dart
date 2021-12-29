import 'dart:io';

import 'package:dio/dio.dart';

class PresignApi {
  static const baseUrl = "https://dev-api.kofi.com.kh";
  static const fullBaseUrl = baseUrl + "/client/";
  static const presign = fullBaseUrl + "upload/presign";

  Dio _dio = Dio()
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers.addAll({"authorization": "Bearer"});
      },
    ));

  Future<PresignResponese> presignUploadApi(
      String extension, String fileName, String type) async {
    final Response response = await _dio.post(presign, data: {
      "media": [
        {"ext": extension, "type": type, "filename": fileName},
      ]
    });
    return PresignResponese.fromJson(response.data);
  }

  Future uploadFile(uploadFile, uploadUrl) async {
    List<int> imageBytes = File(uploadFile.path).readAsBytesSync();
    var file = MultipartFile.fromBytes(imageBytes).finalize();
    Response _response = await _dio.put(
      uploadUrl,
      data: file,
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Accept': "*/*",
          'Connection': 'keep-alive',
        },
      ),
    );
    if (_response.statusCode == 200) return _response;
  }
}

// ** Modal Data

class PresignResponese {
  PresignResponese({this.data});

  final List<Presign>? data;

  factory PresignResponese.fromJson(Map<String, dynamic> json) =>
      PresignResponese(
        data: List<Presign>.from(json["data"].map((x) => Presign.fromJson(x))),
      );
}

class Presign {
  Presign({
    this.uploadUrl,
    this.accessUrl,
  });

  final String? uploadUrl;
  final String? accessUrl;

  factory Presign.fromJson(Map<String, dynamic> json) => Presign(
        uploadUrl: json["uploadUrl"],
        accessUrl: json["accessUrl"],
      );
}
