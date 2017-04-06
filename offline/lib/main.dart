// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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

const String _name = "Your Name";

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
  TextEditingController _textController = new TextEditingController();
  bool _isComposing = false;

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
    AnimationController animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );
    ChatUser sender = new ChatUser(name: _name);
    ChatMessage message = new ChatMessage(
      sender: sender,
      text: text,
      animationController: animationController
    );
    setState(() {
      _messages.insert(0, message);
    });
    animationController.forward();
  }

  Widget _buildTextComposer() {
    VoidCallback onPressed;
    if (_isComposing)
      onPressed = () => _handleSubmitted(_textController.text);
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Row(
        children: <Widget>[
          new Container(width: 10.0),
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
            child: Theme.of(context).platform == TargetPlatform.iOS ?
              new CupertinoButton(child: new Text("Send"), onPressed: onPressed) :
              new IconButton(icon: new Icon(Icons.send), onPressed: onPressed),
          )
        ]
      )
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Friendlychat"),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0 : 4,
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
              child: new CircleAvatar(
                child: new Text(_name[0])
              ),
            ),
            new Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(_name, style: Theme.of(context).textTheme.subhead),
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
