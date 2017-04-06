// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(new FriendlychatApp());
}

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

class FriendlychatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Friendlychat",
      theme: defaultTargetPlatform == TargetPlatform.iOS ? kIOSTheme : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  List<ChatMessage> _messages = <ChatMessage>[];
  DatabaseReference _messagesReference = FirebaseDatabase.instance.reference();
  TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;
  GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    GoogleSignIn.initialize(scopes: <String>[]);
    GoogleSignIn.instance.then((GoogleSignIn instance) {
      setState(() {
        _googleSignIn = instance;
        _googleSignIn.signInSilently();
      });
    });
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _messagesReference.onChildAdded.listen((Event event) {
        var val = event.snapshot.val();
        _addMessage(
          name: val['sender']['name'],
          senderImageUrl: val['sender']['imageUrl'],
          text: val['text'],
          imageUrl: val['imageUrl'],
        );
      });
    });
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages)
      message.animationController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    _googleSignIn.signIn().then((GoogleSignInAccount user) {
      var message = {
        'sender': { 'name': user.displayName, 'imageUrl': user.photoUrl },
        'text': text,
      };
      _messagesReference.push().set(message);
    });
  }

  void _addMessage({ String name, String text, String imageUrl, String senderImageUrl }) {
    AnimationController animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );
    ChatUser sender = new ChatUser(name: name, imageUrl: senderImageUrl);
    ChatMessage message = new ChatMessage(
      sender: sender,
      text: text,
      imageUrl: imageUrl,
      animationController: animationController
    );
    setState(() {
      _messages.insert(0, message);
    });
    animationController.forward();
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Row(
        children: <Widget>[
          new Container(
            margin: new EdgeInsets.symmetric(horizontal: 4.0),
            child: new IconButton(
              icon: new Icon(Icons.photo_camera),
              onPressed: () async {
                GoogleSignInAccount account = await _googleSignIn.signIn();
                File imageFile = await ImagePicker.pickImage();
                int random = new Random().nextInt(10000);
                StorageReference ref = FirebaseStorage.instance.ref().child("image_$random.jpg");
                StorageUploadTask uploadTask = ref.put(imageFile);
                Uri downloadUrl = (await uploadTask.future).downloadUrl;
                var message = {
                  'sender': { 'name': account.displayName, 'imageUrl': account.photoUrl },
                  'imageUrl': downloadUrl.toString(),
                };
                _messagesReference.push().set(message);
              }
            )
          ),
          new Flexible(
            child: new TextField(
              controller: _textController,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.length > 0;
                });
              },
              onSubmitted: _handleSubmitted,
              decoration: new InputDecoration.collapsed(hintText: "Send a message"),
            ),
          ),
          new Container(
            margin: new EdgeInsets.symmetric(horizontal: 4.0),
            child: new PlatformAdaptiveButton(
              icon: new Icon(Icons.send),
              child: new Text("Send"),
              onPressed: _isComposing ? () => _handleSubmitted(_textController.text) : null,
            ),
          )
        ]
      )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new PlatformAdaptiveAppBar(
        title: new Text("Friendlychat"),
        platform: Theme.of(context).platform,
      ),
      body: new Container(
        child: new Column(
            children: <Widget>[
              new Flexible(
                child: new ListView(
                  padding: new EdgeInsets.all(8.0),
                  reverse: true,
                  children: _messages.map((m) => new ChatMessageListItem(m)).toList()
                )
              ),
              new Divider(height: 1.0),
              new Container(
                decoration: new BoxDecoration(backgroundColor: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ]
        ),
        decoration: new BoxDecoration(border: new Border(top: new BorderSide(color: Colors.grey[200]))),
      )
    );
  }
}

class ChatUser {
  ChatUser({ this.name, this.imageUrl });
  final String name;
  final String imageUrl;
}

class ChatMessage {
  ChatMessage({ this.sender, this.text, this.imageUrl, this.animationController });
  final ChatUser sender;
  final String text;
  final String imageUrl;
  final AnimationController animationController;
}

class ChatMessageListItem extends StatelessWidget {
  ChatMessageListItem(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
        parent: message.animationController,
        curve: Curves.easeOut
      ),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new GoogleUserCircleAvatar(message.sender.imageUrl),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(message.sender.name, style: Theme.of(context).textTheme.subhead),
                new Container(
                   margin: const EdgeInsets.only(top: 5.0),
                   child: new ChatMessageContent(message),
                 ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessageContent extends StatelessWidget {
  ChatMessageContent(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    if (message.imageUrl != null)
      return new Image.network(message.imageUrl, width: 250.0);  // TODO(jackson): Don't hard code the width
    else
      return new Text(message.text);
  }
}

/// App bar that uses iOS styling on iOS
class PlatformAdaptiveAppBar extends AppBar {
  PlatformAdaptiveAppBar({
    Key key,
    TargetPlatform platform,
    Widget title,
    Widget body,
    // TODO(jackson): other properties?
  }) : super(
    key: key,
    elevation: platform == TargetPlatform.iOS ? 0 : 4,
    title: title,
  );
}

/// Button that is Material on Android and Cupertino on iOS
/// On Android an icon button; on iOS, text is used
///
/// TODO(jackson): Move this into a reusable library
class PlatformAdaptiveButton extends StatelessWidget {
  PlatformAdaptiveButton({ Key key, this.child, this.icon, this.onPressed })
    : super(key: key);
  final Widget child;
  final Widget icon;
  final VoidCallback onPressed;

  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return new CupertinoButton(
          child: child,
          onPressed: onPressed,
      );
    } else {
      return new IconButton(
          icon: icon,
          onPressed: onPressed,
      );
    }
  }
}

class PlatformChooser extends StatelessWidget {
  PlatformChooser({ Key key, this.iosChild, this.defaultChild });
  final Widget iosChild;
  final Widget defaultChild;

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS)
      return iosChild;
    return defaultChild;
  }
}
