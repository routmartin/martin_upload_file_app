import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const baseUrl = "https://dev-api.kofi.com.kh";
const fullBaseUrl = baseUrl + "/client/";
const presign = fullBaseUrl + "upload/presign";
const _tokenKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6NywidHlwZSI6ImN1c3RvbWVyIiwiaWF0IjoxNjQxNzc5OTc0LCJleHAiOjE2NDE4NjYzNzR9.0cff0WPdAxrXuK0tYVTuyRzLttKbPc7dxEftCSFR5EY";
Dio _dio = Dio()..interceptors.add(PrettyDioLogger());

class PresignApi {
  presignUploadApi(List<Media> data) async {
    Response? response = await _dio.post(presign,
        options: Options(headers: {"authorization": "Bearer $_tokenKey"}),
        data: jsonEncode({'media': data}));
    return PresignResponese.fromJson(response.data);
  }

  Future<bool> uploadFile(XFile uploadFile, String? uploadUrl,
      Function(int) updatePercentage, CancelToken token) async {
    List<int> _imageBytes = File(uploadFile.path).readAsBytesSync();
    // Stream<List<int>> _file = MultipartFile.fromBytes(_imageBytes).finalize();

    String? _extension = extension(uploadFile.path).split('.').last;
    String _contentType = _extension == 'png' ? "image/png" : "image/jpeg";

    /// Process api request

    try {
      final Response _response = await _dio.put(
        uploadUrl!,
        cancelToken: token,
        data: _imageBytes,
        options: Options(
          headers: {
            'Content-Type': _contentType,
            'Accept': "*/*",
            'Connection': 'keep-alive',
            'Content-Length': File(uploadFile.path).lengthSync().toString(),
          },
          responseType: ResponseType.bytes,
        ),
        onSendProgress: (count, total) {
          if (total != -1) {
            updatePercentage(
                int.parse((count / total * 100).toStringAsFixed(0)));
          }
        },
      );
      return _response.statusCode == 200 ? true : false;
    } catch (e) {
      throw e;
    }
  }
}

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

class Media {
  final String ext;
  final String type;
  final String fileName;

  Media(this.ext, this.type, this.fileName);
  Map<String, dynamic> toJson() =>
      {"ext": ext, "type": type, "filename": fileName};
}

PresignApi apiService = new PresignApi();
