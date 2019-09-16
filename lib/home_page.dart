import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import 'package:path/path.dart';
import 'package:xml/xml.dart' as xml;



import './policy.dart';

class HomePage extends StatelessWidget {
  
  static String tag = 'home-page';

  List data;
  File galleryFile;

  final _awsUserPoolId = 'us-east-1_jNiKQfHo5';
  final _awsClientId = '74b6go2gpt8l0jsikrvbsr3f8a';
//  get username => pd.username;// "yash.sodha@gmail.com";
//  get password => pd.password;//"Password@1234";
  final _region = 'us-east-1';
  final bucketname = 'yashrstest123';
  final _host = 'yashrstest123.s3.amazonaws.com';
  final _s3Endpoint = 'https://yashrstest123.s3.amazonaws.com';

  final username, password;


  HomePage({Key key, @required this.username, @required this.password}) : super(key: key);

  Future<CognitoCredentials> getCredentials() async {
    final userPool = new CognitoUserPool(_awsUserPoolId, _awsClientId);
    final cognitoUser = new CognitoUser(username, userPool);
    final authDetails =
        new AuthenticationDetails(username: username, password: password);
    CognitoUserSession session;
    try {
      session = await cognitoUser.authenticateUser(authDetails);
    } catch (e) {
      print(e);
    }

    print(session.getAccessToken().getJwtToken());

    var credentials = new CognitoCredentials(
        'us-east-1:b8e2039c-6e28-46bf-b812-1aa3d423e4d9', userPool);
    await credentials.getAwsCredentials(session.getIdToken().getJwtToken());

    return credentials;
  }

  Future cognitologintest() async {
    var credentials = await getCredentials();
    print("Access key id: " + credentials.accessKeyId);
    print("Secret Access Key: " + credentials.secretAccessKey);
    print("Session Token: " + credentials.sessionToken);
  }

  Future<http.Response> getFileHelper(String S3Key) async {
    var credentials = await getCredentials();

    final host = 's3.amazonaws.com';
    final region = _region;
    final service = 's3';
    final key = bucketname + '/' + S3Key;

    final payload = SigV4.hashCanonicalRequest('');
    final datetime = SigV4.generateDatetime();
    final canonicalRequest = '''GET
    ${'/$key'.split('/').map((s) => Uri.encodeComponent(s)).join('/')}
    
    host:$host
    x-amz-content-sha256:$payload
    x-amz-date:$datetime
    x-amz-security-token:${credentials.sessionToken}
    
    host;x-amz-content-sha256;x-amz-date;x-amz-security-token
    $payload''';
    final credentialScope =
    SigV4.buildCredentialScope(datetime, region, service);
    final stringToSign = SigV4.buildStringToSign(datetime, credentialScope,
        SigV4.hashCanonicalRequest(canonicalRequest));
    final signingKey = SigV4.calculateSigningKey(
        credentials.secretAccessKey, datetime, region, service);
    final signature = SigV4.calculateSignature(signingKey, stringToSign);

    final authorization = [
      'AWS4-HMAC-SHA256 Credential=${credentials.accessKeyId}/$credentialScope',
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
        'x-amz-security-token': credentials.sessionToken,
      });
    } catch (e) {
      print(e);
    }
    return response;
  }
  Future<http.Response> deleteFileHelper(String S3Key) async {
    var credentials = await getCredentials();

    final host = 's3.amazonaws.com';
    final region = _region;
    final service = 's3';
    final key = bucketname + '/' + S3Key;

    final payload = SigV4.hashCanonicalRequest('');
    final datetime = SigV4.generateDatetime();
    final canonicalRequest = '''DELETE
${'/$key'.split('/').map((s) => Uri.encodeComponent(s)).join('/')}

host:$host
x-amz-content-sha256:$payload
x-amz-date:$datetime
x-amz-security-token:${credentials.sessionToken}

host;x-amz-content-sha256;x-amz-date;x-amz-security-token
$payload''';
    final credentialScope =
    SigV4.buildCredentialScope(datetime, region, service);
    final stringToSign = SigV4.buildStringToSign(datetime, credentialScope,
        SigV4.hashCanonicalRequest(canonicalRequest));
    final signingKey = SigV4.calculateSigningKey(
        credentials.secretAccessKey, datetime, region, service);
    final signature = SigV4.calculateSignature(signingKey, stringToSign);

    final authorization = [
      'AWS4-HMAC-SHA256 Credential=${credentials.accessKeyId}/$credentialScope',
      'SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token',
      'Signature=$signature',
    ].join(',');

    final uri = Uri.https(host, key);
    http.Response response;
    try {
      response = await http.delete(uri, headers: {
        'Authorization': authorization,
        'x-amz-content-sha256': payload,
        'x-amz-date': datetime,
        'x-amz-security-token': credentials.sessionToken,
      });
    } catch (e) {
      print(e);
    }
    return response;
  }

  Future<List> getFileNames() async {
    http.Response aa = await getFileHelper("");
    String xx = aa.body;
    print(xx);

    var document = xml.parse(xx);
    print(document.children.length);

    var files = document.findAllElements('Key');

    List fileList = new List<String>();

    for (int i = 0; i < files.length; i++) {
      var file = files.elementAt(i);
      print(file.text);
      fileList.add(file.text);
    }
    print(fileList);

    return fileList;
  }

  Future getFile() async {
    http.Response aa = await getFileHelper("yash");
    print(aa.body);
  }

  Future delFileDemo() async {
    http.Response aa = await deleteFileHelper("yash");
    print(aa.body);
  }

  Future uploadFileToS3(String pathString) async {
    var credentials = await getCredentials();

    final file = File(pathString);
    String filename = basename(file.path);

    final stream = http.ByteStream(DelegatingStream.typed(file.openRead()));
    final length = await file.length();
    print("File length: " + length.toString());
    final uri = Uri.parse(_s3Endpoint);
    final req = http.MultipartRequest("POST", uri);
    final multipartFile = http.MultipartFile('file', stream, length,
        filename: path.basename(file.path));

    final policy = Policy.fromS3PresignedPost(filename, 'yashrstest123', 15,
        credentials.accessKeyId, length, credentials.sessionToken,
        region: _region);

    final key = SigV4.calculateSigningKey(
        credentials.secretAccessKey, policy.datetime, _region, 's3');
    final signature = SigV4.calculateSignature(key, policy.encode());

    req.files.add(multipartFile);
    req.fields['key'] = policy.key;
    req.fields['acl'] = 'private';
    req.fields['X-Amz-Credential'] = policy.credential;
    req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
    req.fields['X-Amz-Date'] = policy.datetime;
    req.fields['Policy'] = policy.encode();
    req.fields['X-Amz-Signature'] = signature;
    req.fields['x-amz-security-token'] = credentials.sessionToken;

    print(req);
    print(req.fields);

    try {
      print("Sending Request");
      final res = await req.send();
      print("Request sent");
      await for (var value in res.stream.transform(utf8.decoder)) {
        print(value);
      }
    } catch (e) {
      print("Exception: ");
      print(e);
    }
  }

//  Future uploadToS3(String pathString) async {
//    String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
//        pathString,
//        "s3bucketclass",
//        "ap-south-1:b97756ef-5592-45f7-ad80-1e651d945737",
//        "ap-south-1");
//
//    print(uploadedImageUrl);
//  }

  @override
  Widget build(BuildContext context) {

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
        print("You selected File: " + path);
        uploadFileToS3(path);
      }
    }
    List data = [1, 2,23,4];

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Share and Care'),
      ),
//      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body:
          new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
          new FutureBuilder<List>(
            future: getFileNames(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              List<String> posts = snapshot.data;
              return new Flexible(child: new ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    return new ListTile(
                        title: Text(posts[index]),
                        trailing:Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(icon: Icon(Icons.cloud_download), onPressed: () {}),
                              IconButton(icon: Icon(Icons.delete_forever), onPressed: () {})
                            ]),
                    );
                  }
              ),);

            },
          ),

          new RaisedButton(
            child: new Text('Get file demo'),
            onPressed: getFile,
          ),
          new RaisedButton(
            child: new Text('Delete file demo'),
            onPressed: delFileDemo,
          ),
//              new RaisedButton(
//                child: new Text('Cognito Login Test'),
//                onPressed: cognitologintest,
//              ),
//          new RaisedButton(
//            child: new Text('GetFileList'),
//            onPressed: getFileNames,
//          ),
          new FloatingActionButton.extended(
            elevation: 20.0,
            icon: Icon(Icons.add),
            label: Text("Add Files"),
            onPressed: fileSelector,

          ),



        ],
      )

    );
  }
}
