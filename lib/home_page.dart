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

class HomePage extends StatefulWidget {
  
  static String tag = 'home-page';

  HomePage({Key key, @required this.username, @required this.password})
      : super(key: key);

  final username, password;

  @override
  State<StatefulWidget> createState() {
    return _HomePageState(username, password);
  }


//  Future uploadToS3(String pathString) async {
//    String uploadedImageUrl = await FlutterAmazonS3.uploadImage(
//        pathString,
//        "s3bucket",
//        "ap-XXXXX-X:xxxxxxxxxxxxxxxxxxxxx",
//        "ap-XX-X");
//
//    print(uploadedImageUrl);
//  }


  }

class _HomePageState extends State<HomePage> {

  final username, password;

  _HomePageState(this.username, this.password);


  List data;
  File galleryFile;

  final _awsUserPoolId = 'xxxxxx';
  final _awsClientId = 'xxxxxxxx';

//  get username => pd.username;// "yash.sodha@gmail.com";
//  get password => pd.password;//"Password@1234";
  final _region = 'xxxxxxxxxx';
  final bucketname = 'xxxxxx';
  final _host = 'xxxxxxx';
  final _s3Endpoint = 'xxxxxxxx';


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
        'xxxxxxxxxxxx', userPool);
    await credentials.getAwsCredentials(session.getIdToken().getJwtToken());

    return credentials;
  }

//  Future cognitologintest() async {
//    var credentials = await getCredentials();
//    print("Access key id: " + credentials.accessKeyId);
//    print("Secret Access Key: " + credentials.secretAccessKey);
//    print("Session Token: " + credentials.sessionToken);
//  }


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
        setState(() {

        });
      }
    } catch (e) {
      print("Exception: ");
      print(e);
    }
  }

  signOut()
  {
    
  }

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
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

    return new Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: ListView(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(username),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    '${username[0].toString().toUpperCase()}',
                    style: TextStyle(fontSize: 40.0),
                  ),
                ),
              ),
              ListTile(
                title: Text("Log out"),
                trailing: Icon(Icons.exit_to_app),
                onTap: signOut(),
              ),
//              ListTile(
//                title: Text("Item 2"),
//                trailing: Icon(Icons.arrow_forward),
//              ),
            ],
          ),
        ),
        appBar: new AppBar(
          title: new Text('Share and Care'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {

                });
              },
            ),
          ],
        ),
//      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        body:
        new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            new MyListView(username: username, password: password),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: new FloatingActionButton.extended(
                elevation: 10.0,
                icon: Icon(Icons.add),
                label: Text("Add Files"),
                onPressed: fileSelector,

              ),
            )

//              new RaisedButton(
//                child: new Text('Cognito Login Test'),
//                onPressed: cognitologintest,
//              ),
//          new RaisedButton(
//            child: new Text('GetFileList'),
//            onPressed: getFileNames,
//          ),


          ],
        )

    );
  }
}



class MyListView extends StatefulWidget {
  MyListView({Key key, @required this.username, @required this.password})
      : super(key: key);

  final username, password;

  @override
  State<StatefulWidget> createState() {
    return _MyListViewState(username, password);
  }
}

class _MyListViewState extends State<MyListView> {
  final _awsUserPoolId = 'xxxxxxx';
  final _awsClientId = 'xxxxxxxxxx';
//  get username => pd.username;// "yash.sodha@gmail.com";
//  get password => pd.password;//"Password@1234";
  final _region = 'xxxxxxxx';
  final bucketname = 'xxxxxxxx';
  final _host = 'xxxxxxxxx';
  final _s3Endpoint = 'xxxxxxxxxx';
  final username, password;

  _MyListViewState(this.username, this.password);

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
        'xxxxxxxxxxx', userPool);
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

  Future getFile(String fileName) async {
    http.Response aa = await getFileHelper(fileName);
    var folderName = '/sdcard/classroom(Prototype)/';
    new File(folderName+"sample").createSync(recursive: true);

    final file = File(path.join(folderName, fileName));

    try {
      await file.writeAsBytes(aa.bodyBytes);
    } catch (e) {
      print(e.toString());
      return;
    }
    print("Downloaded file: " + fileName);
    print('complete!');
  }

  Future delFileDemo(String fileName) async {
    http.Response aa = await deleteFileHelper(fileName);
    print("Deleted file: " + fileName);
    print(aa.body);
    setState(() {

    });
  }
  @override
  Widget build(BuildContext context) {
    return new FutureBuilder<List>(
      future: getFileNames(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        List<String> posts = snapshot.data;
        return new Flexible(
          child: new ListView.builder(
              itemCount: posts.length,
              itemBuilder: (BuildContext ctxt, int index) {
                return new ListTile(
                  title: Text(posts[index]),
                  trailing:
                  Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    IconButton(
                        icon: Icon(Icons.cloud_download),
                        onPressed: () {
                          getFile(posts[index]);
                        }),
                    IconButton(
                        icon: Icon(Icons.delete_forever),
                        onPressed: () {
                          delFileDemo(posts[index]);
                        })
                  ]),
                );
              }),
        );
      },
    );
  }
}

