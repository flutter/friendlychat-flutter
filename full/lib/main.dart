// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

void main() {
  runApp(new FriendlychatApp());
}

class FriendlychatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Friendlychat",
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

@override
class ChatMessage extends StatelessWidget {
  ChatMessage({this.text, this.senderName, this.animationController});
  final String text;
  final String senderName;
  final AnimationController animationController;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(
          parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: new CircleAvatar(child: new Text(senderName[0])),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(senderName, style: Theme.of(context).textTheme.subhead),
                new Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: new Text(text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  GoogleSignIn _googleSignIn;
  FirebaseAnalytics _analytics = new FirebaseAnalytics();
  FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseReference _reference =
    FirebaseDatabase.instance.reference().child('messages');
  FirebaseList _messages;
  final Map<String, AnimationController> _controllers =
      <String, AnimationController>{};
  final TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    GoogleSignIn.initialize(scopes: ['']);
    GoogleSignIn.instance.then((GoogleSignIn instance) {
      setState(() {
        _googleSignIn = instance;
      });
    });
    _auth.signInAnonymously().then((_) {
      setState(() {
        _messages = new FirebaseList(_reference);
        _reference.onChildAdded.listen((Event event) async {
            // When a new message arrives after the initial load, animate it
            AnimationController controller = new AnimationController(
              duration: new Duration(milliseconds: 700),
              vsync: this,
            )..forward();
            String key = event.snapshot.key;
            assert(_controllers[key] == null);
            _controllers[key] = controller;
          });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("Friendlychat"),
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0 : 4,
          actions: _googleSignIn?.currentUser == null ? null : [
            new PopupMenuButton(
              onSelected: (_) { _googleSignIn.signOut(); },
              itemBuilder: (BuildContext context) {
                return [ new PopupMenuItem(child: const Text('Sign out')) ];
              }
            ),
          ],
        ),
        body: new Column(children: <Widget>[
          new Flexible(
            child: new RefreshIndicator(
              onRefresh: () => _reference.next(10),
              child: new StreamBuilder(
                stream: _reference.onChildAdded,
                builder: (_, __) {
                  return _messages == null ? new Container() : new ListView.builder(
                    padding: new EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (_, int i) {
                      return new ChatMessage(
                        text: _messages.delegate[i].value['text'],
                        senderName: _messages.delegate[i].value['senderName'],
                        animationController: _controllers[_messages.delegate[i].key],
                      );
                    },
                    itemCount: _messages.delegate.length,
                  );
                },
              ),
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration:
                new BoxDecoration(backgroundColor: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ]));
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _handleSubmitted,
                decoration:
                    new InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? new CupertinoButton(
                        child: new Text("Send"),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )
                    : new IconButton(
                        icon: new Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )),
          ]),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border:
                      new Border(top: new BorderSide(color: Colors.grey[200])))
              : null),
    );
  }

  Future<Null> _handleSubmitted(String text) async {
    _textController.clear();

    GoogleSignInAccount _user = _googleSignIn.currentUser;
    // Ensure that the user is logged in to send a message
    if (_user == null) {
      _user = await _googleSignIn.signInSilently();
      if (_user == null) {
        _user = await _googleSignIn.signIn();
        _analytics.logLogin();
      }
      // TODO(jackson): Implement GoogleSignInAccount.credential to ensure that
      // only authenticated users can send messages. (optional)
      // await _auth.signInWithCredential(_user.credential);
    }

    // Now that the user is authenticated, send the message
    _reference.push().set(<String, dynamic>{
      'text': text,
      'senderName': _user.displayName,
    });
    _analytics.logEvent(name: 'send_message');
  }

  @override
  void dispose() {
    for (AnimationController controller in _controllers.values)
      controller.dispose();
    _messages.dispose();
    super.dispose();
  }
}
