// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'firebase_stubs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(new MyApp());
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

class MyApp extends StatelessWidget {
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
  String _name = "Guest${new Random().nextInt(1000)}";
  Color _color = Colors.accents[new Random().nextInt(Colors.accents.length)][700];
  List<ChatMessage> _messages = <ChatMessage>[];
  DatabaseReference _messagesReference = FirebaseDatabase.instance.reference();
  InputValue _currentMessage = InputValue.empty;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.signInAnonymously().then((user) {
      _messagesReference.onChildAdded.listen((Event event) {
        var val = event.snapshot.val();
        _addMessage(
          name: val['sender']['name'],
          color: new Color(val['sender']['color']),
          text: val['text'],
          imageUrl: val['imageUrl'],
          senderImageUrl: val['senderImageUrl'],
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

  void _handleMessageChanged(InputValue value) {
    setState(() {
      _currentMessage = value;
    });
  }

  void _handleMessageAdded(InputValue value) {
    setState(() {
      _currentMessage = InputValue.empty;
    });
    var message = {
      'sender': { 'name': _name, 'color': _color.value },
      'text': value.text,
    };
    _messagesReference.push().set(message);
  }

  void _addMessage({ String name, Color color, String text, String imageUrl, String senderImageUrl }) {
    AnimationController animationController = new AnimationController(
      duration: new Duration(milliseconds: 700),
      vsync: this,
    );
    ChatUser sender = new ChatUser(name: name, color: color, imageUrl: senderImageUrl);
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

  bool get _isComposing => _currentMessage.text.length > 0;

  Widget _buildTextComposer() {
    ThemeData themeData = Theme.of(context);
    return new Row(
      children: <Widget>[
        new Container(
          margin: new EdgeInsets.symmetric(horizontal: 4.0),
          child: new IconButton(
            icon: new Icon(Icons.insert_photo),
            color: themeData.accentColor,
            onPressed: () {
              int count = _messages.length;
              String url = 'http://thecatapi.com/api/images/get?format=src&type=gif&count=$count';
                var message = {
                  'sender': { 'name': _name, 'color': _color.value },
                  'imageUrl': url,
                };
                _messagesReference.push().set(message);
            }
          )
        ),
        new Flexible(
          child: new Input(
            value: _currentMessage,
            hintText: 'Enter message',
            onSubmitted: _handleMessageAdded,
            onChanged: _handleMessageChanged,
          )
        ),
        new Container(
          margin: new EdgeInsets.symmetric(horizontal: 4.0),
          child: new PlatformAdaptiveButton(
            icon: new Icon(Icons.send),
            child: new Text("Send"),
            onPressed: _isComposing ? () => _handleMessageAdded(_currentMessage) : null,
          ),
        )
      ]
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
  ChatUser({ this.name, this.color, String imageUrl })
    : networkImage = imageUrl == null ? null : new NetworkImage(imageUrl);
  final String name;
  final Color color;
  final ImageProvider networkImage;
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
                child: message.sender.networkImage == null ? new Text(message.sender.name[0]) : null,
                backgroundColor: message.sender.color,
                backgroundImage: message.sender.networkImage,
              ),
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
      return new Image.network(message.imageUrl);
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
