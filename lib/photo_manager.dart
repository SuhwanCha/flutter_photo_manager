import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class ImageScanner {
  static const MethodChannel _channel = const MethodChannel('image_scanner');

  /// in android WRITE_EXTERNAL_STORAGE  READ_EXTERNAL_STORAGE
  ///
  /// in ios request the photo permission
  static Future<bool> requestPermission() async {
    var result = await _channel.invokeMethod("requestPermission");
    return result == 1;
  }

  /// get gallery list
  ///
  /// 获取相册"文件夹" 列表
  static Future<List<ImageParentPath>> getImagePathList() async {
    /// 获取id 列表
    List list = await _channel.invokeMethod('getGalleryIdList');
    if (list == null) {
      return [];
    }

    return _getPathList(list.map((v) => v.toString()).toList());
  }

  static void openSetting() {
    _channel.invokeMethod("openSetting");
  }

  static Future<List<ImageParentPath>> _getPathList(List<String> idList) async {
    /// 获取文件夹列表,这里主要是获取相册名称
    var list = await _channel.invokeMethod("getGalleryNameList", idList);
    List<ImageParentPath> result = [];
    for (var i = 0; i < idList.length; i++) {
      result.add(ImageParentPath(id: idList[i], name: list[i].toString()));
    }

    return result;
  }

  /// get image entity with path
  ///
  /// 获取指定相册下的所有内容
  static Future<List<ImageEntity>> _getImageList(ImageParentPath path) async {
    List list = await _channel.invokeMethod("getImageListWithPathId", path.id);
    return list.map((v) => ImageEntity(id: v.toString())).toList();
  }

  static Future<File> _getFullFileWithId(String id) async {
    if (Platform.isAndroid) {
      return File(id);
    } else if (Platform.isIOS) {
      var path = await _channel.invokeMethod("getFullFileWithId", id);
      if (path == null) {
        return null;
      }
      return File(path);
    }
    return null;
  }

  static Future<List<int>> _getDataWithId(String id) async {
    if (Platform.isAndroid) {
      return File(id).readAsBytes();
    } else if (Platform.isIOS) {
      List<dynamic> bytes = await _channel.invokeMethod("getBytesWithId", id);
      if (bytes == null) {
        return null;
      }
      List<int> l = bytes.map((v) {
        if (v is int) {
          return v;
        }
        return 0;
      }).toList();

      return l;
    }
    return null;
  }

  static Future<Uint8List> _getThumbDataWithId(String id) async {
    var result = await _channel.invokeMethod("getThumbBytesWithId", id);
    if (result is Uint8List) {
      return result;
    }
    if (result is List<dynamic>) {
      List<int> l = result.map((v) {
        if (v is int) {
          return v;
        }
        return 0;
      }).toList();
      return Uint8List.fromList(l);
    }

    return null;
  }
}

/// image entity
class ImageEntity {
  /// in android is full path
  ///
  /// in ios is asset id
  String id;

  /// thumb path
  ///
  /// you can use File(path) to use
  // Future<File> get thumb async => ImageScanner._getThumbWithId(id);

  /// if you need upload file ,then you can use the file
  Future<File> get file async => ImageScanner._getFullFileWithId(id);

  /// the image's bytes ,
  Future<List<int>> get fullData => ImageScanner._getDataWithId(id);

  /// thumb data , for display
  Future<Uint8List> get thumbData => ImageScanner._getThumbDataWithId(id);

  ImageEntity({this.id});
}

/// Gallery Id
class ImageParentPath {
  /// id
  ///
  /// in ios is localIdentifier
  ///
  /// in android is content provider database _id column
  String id;

  /// name
  ///
  /// in android is path name
  ///
  /// in ios is photos gallery name
  String name;

  ImageParentPath({this.id, this.name});

  /// the image entity list
  Future<List<ImageEntity>> get imageList => ImageScanner._getImageList(this);
}