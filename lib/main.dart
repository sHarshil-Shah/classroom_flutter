import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
//import 'package:test/test.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_amazon_s3/flutter_amazon_s3.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

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
  File galleryFile;

  Future getData() async {
//    String url =
//        'https://5cldfzpz5a.execute-api.ap-south-1.amazonaws.com/dev/getAllFiles';
//    const _awsUserPoolId = 'ap-south-1_ezMWp6Hdq';
//    const _awsClientId = '5aedttsefv2td8opmr4l9smgem';

//    final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);
    const _awsUserPoolId = 'ap-south-1_gV1VxnlpG';
    const _awsClientId = '72td7m5javu89hek30d77n0d4b';
    final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

    final _cognitoUser = CognitoUser('yash', _userPool);

    final authDetails =
        AuthenticationDetails(username: 'yash', password: 'Mypassword@12');

    final cognitoUser = new CognitoUser(
        'yash', _userPool);

    CognitoUserSession _session;
    try {
      _session = await _cognitoUser.authenticateUser(authDetails);
    } catch (e) {
      print(e);
    }

    final _identityPoolId = 'ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737';

    final _credentials = CognitoCredentials(_identityPoolId, _userPool);
    await _credentials.getAwsCredentials(_session.getIdToken().getJwtToken());

    final host = 's3.ap-south-1.amazonaws.com';
    final region = 'ap-south-1';
    final service = 's3';
    final key =
        'https://s3bucketclass.s3.ap-south-1.amazonaws.com/VID20190630131423mp4.mp4';
    final payload = SigV4.hashCanonicalRequest('');
    final datetime = SigV4.generateDatetime();
    final canonicalRequest = '''GET
      ${'/$key'.split('/').map((s) => Uri.encodeComponent(s)).join('/')}
      host:$host
      x-amz-content-sha256:$payload
      x-amz-date:$datetime
      x-amz-security-token:${_credentials.sessionToken}
      host;x-amz-content-sha256;x-amz-date;x-amz-security-token
      $payload''';

    final credentialScope =
        SigV4.buildCredentialScope(datetime, region, service);
    final stringToSign = SigV4.buildStringToSign(datetime, credentialScope,
        SigV4.hashCanonicalRequest(canonicalRequest));
    final signingKey = SigV4.calculateSigningKey(
        _credentials.secretAccessKey, datetime, region, service);
    final signature = SigV4.calculateSignature(signingKey, stringToSign);

    final authorization = [
      'AWS4-HMAC-SHA256 Credential=${_credentials.accessKeyId}/$credentialScope',
      'SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token',
      'Signature=$signature',
    ].join(',');

    final uri = Uri.https(host, key);
    http.Response response;
    try {
      response = await http.get(uri, headers: {
        'Authorization': authorization,
        'x-amz-content-sha256': payload,
        'x-amz-date': datetime,
        'x-amz-security-token': _credentials.sessionToken,
      });
    } catch (e) {
      print(e);
    }

    final file =
        File(path.join('/storage/emulated/0/', 'a.mp4'));

    try {
      await file.writeAsBytes(response.bodyBytes);
    } catch (e) {
      print(e.toString());
    }

    print('complete!');
  }

  Future uploadToS3(String pathString) async {
    String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
        pathString,
        "s3bucketclass",
        "ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737",
        "ap-south-1");

    print(uploadedImageUrl);
  }


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
      Map<String, String> filesPaths;
      filesPaths = await FilePicker
          .getMultiFilePath(); // will let you pick multiple files of any format at once
//      filesPaths = await FilePicker.getMultiFilePath(fileExtension: 'pdf'); // will let you pick multiple pdf files at once
//      filesPaths = await FilePicker.getMultiFilePath(type: FileType.IMAGE); // will let you pick multiple image files at once
      print(filesPaths);
      Iterable<String> allNames = filesPaths.keys; // List of all file names
      Iterable<String> allPaths = filesPaths.values; // List of all paths

      for (var path in allPaths) {
//      print(value);
        String someFilePath =
            path; // Access a file path directly by its name (matching a key)
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new RaisedButton(
                child: new Text('Select file'),
                onPressed: fileSelector,
              ),
              new RaisedButton(
                child: new Text('Get all files'),
                onPressed: getData,
              ),

            ],
          );
        },
      ),
    );
  }
}
