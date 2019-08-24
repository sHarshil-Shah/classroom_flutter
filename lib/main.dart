import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
//import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(new MaterialApp(
    home: new HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> {
  List data;

  Future<String> getData() async {
    String url =
        'https://5cldfzpz5a.execute-api.ap-south-1.amazonaws.com/dev/getAllFiles';
    final response =
        await http.get(url, headers: {"Accept": "application/json"});
    return json.decode(response.body);
  }

  Future uploadToS3(String pathString) async {
    String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
      pathString, "s3bucketclass", "ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737", "ap-south-1");

    print(uploadedImageUrl);
  }

  //save the result of gallery file
  File galleryFile;

  @override
  Widget build(BuildContext context) {
    imageSelectorGallery() async {
      galleryFile = await ImagePicker.pickImage(
        source: ImageSource.gallery,
        // maxHeight: 50.0,
        // maxWidth: 50.0,
      );
      print("You selected gallery image : " + galleryFile.path);
      uploadToS3(galleryFile.path.toString());

      setState(() {});
    }

    fileSelector() async {
      Map<String,String> filesPaths;
      filesPaths = await FilePicker.getMultiFilePath(); // will let you pick multiple files of any format at once
//      filesPaths = await FilePicker.getMultiFilePath(fileExtension: 'pdf'); // will let you pick multiple pdf files at once
//      filesPaths = await FilePicker.getMultiFilePath(type: FileType.IMAGE); // will let you pick multiple image files at once
      print(filesPaths);
      Iterable<String> allNames = filesPaths.keys; // List of all file names
      Iterable<String> allPaths = filesPaths.values; // List of all paths

      for (var path in allPaths) {
//      print(value);
        String someFilePath = path; // Access a file path directly by its name (matching a key)
        print("You selected File: " + someFilePath);
        uploadToS3(someFilePath.toString());
      }
      setState(() {});
    }



    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Share and Care'),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new RaisedButton(
                child: new Text('Select file'),
                onPressed: fileSelector,
              ),
            ],
          );
        },
      ),
    );
  }
}
