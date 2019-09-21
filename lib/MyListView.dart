import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path/path.dart' as path;

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
  final _awsUserPoolId = 'us-east-1_jNiKQfHo5';
  final _awsClientId = '74b6go2gpt8l0jsikrvbsr3f8a';
//  get username => pd.username;// "yash.sodha@gmail.com";
//  get password => pd.password;//"Password@1234";
  final _region = 'us-east-1';
  final bucketname = 'yashrstest123';
  final _host = 'yashrstest123.s3.amazonaws.com';
  final _s3Endpoint = 'https://yashrstest123.s3.amazonaws.com';
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
