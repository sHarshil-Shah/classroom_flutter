import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
//import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import './policy.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';

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

  Future policyThings(String pathString) async {
    String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
      pathString, "s3bucketclass", "ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737", "ap-south-1");

    print(uploadedImageUrl);

    String uploadedImageUrl1 = await FlutterAmazonS3.uploadImage(
        pathString, "s3bucketclass", "ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737", "ap-south-1");



//    const _accessKeyId = 'AKIAQWDJ57L5WLELMJW3';
//    const _secretKeyId = '8DXVvlpPTha55inH4s2UjYWe+Z0yEv4O6EVTps5Z';
//    const _region = 'ap-south-1';
//    const _s3Endpoint =
//        'https://v0l091i3k7.execute-api.ap-south-1.amazonaws.com/dev/uploadFile';
//
//    final file = File(path.join(pathString));
//    final stream = http.ByteStream(DelegatingStream.typed(file.openRead()));
//    final length = await file.length();
//
//    final uri = Uri.parse(_s3Endpoint);
//    final req = http.MultipartRequest("POST", uri);
//    final multipartFile = http.MultipartFile('file', stream, length,
//        filename: path.basename(file.path));
//
//    final policy = Policy.fromS3PresignedPost(
//        'uploaded/scaled_20190824_000012.jpg',
//        'serverless-main-dev-serverlessdeploymentbucket-1svmzlmv8v6d3',
//        _accessKeyId,
//        15,
//        length,
//        region: _region);
//    final key =
//        SigV4.calculateSigningKey(_secretKeyId, policy.datetime, _region, 's3');
//    final signature = SigV4.calculateSignature(key, policy.encode());
//
//    req.files.add(multipartFile);
//    req.fields['key'] = policy.key;
//    req.fields['acl'] = 'public-read';
//    req.fields['X-Amz-Credential'] = policy.credential;
//    req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
//    req.fields['X-Amz-Date'] = policy.datetime;
//    req.fields['Policy'] = policy.encode();
//    req.fields['X-Amz-Signature'] = signature;
//
//    final res = await req.send();
//    await for (var value in res.stream.transform(utf8.decoder)) {
//      print(value);
//    }
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
      policyThings(galleryFile.path.toString());

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
                child: new Text('Select Image from Gallery'),
                onPressed: imageSelectorGallery,
              ),
              displaySelectedFile(galleryFile),
            ],
          );
        },
      ),
    );
  }

  Widget displaySelectedFile(File file) {
    return new SizedBox(
      height: 200.0,
      width: 300.0,
//child: new Card(child: new Text(''+galleryFile.toString())),
//child: new Image.file(galleryFile),
      child: file == null
          ? new Text('Sorry nothing selected!!')
          : new Image.file(file),
    );
  }
}
