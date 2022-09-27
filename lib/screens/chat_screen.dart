import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String message;
  final textController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs.reversed) {
        // print(message.data().values);
        print(message.data()['text']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                messagesStream();
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textController,
                      onChanged: (value) {
                        message = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      textController.clear();
                      //textController.text = 'sss';
                      _firestore.collection('messagees').add({
                        'text': message,
                        'sender': loggedInUser.email,
                        'date': DateTime.now().millisecondsSinceEpoch
                      });

                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _firestore
          .collection("messagees")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.data.size != 0) {
          return Expanded(
            child: ListView.builder(
                reverse: true,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot message = snapshot.data.docs[index];

                  final messageText = message['text'];
                  final messageSender = message['sender'];
                  final date = message['date'];
                  final currentUser = loggedInUser.email;

                  return ListTile(
                      title: MessagesBubbles(
                    sender: messageSender,
                    text: messageText,
                    itsme: currentUser == messageSender,
                  ));
                }),
          );
        } else {
          return Container(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'The Messages will appear here',
                textAlign: TextAlign.center,
              ));
        }
      },
    );
  }
}

class MessagesBubbles extends StatelessWidget {
  MessagesBubbles({this.sender, this.text, this.itsme});
  final String text;
  final String sender;

  final bool itsme;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            itsme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
          Material(
            borderRadius: itsme
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 10,
            color: itsme ? Colors.white : Colors.lightBlueAccent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                text,
                style: TextStyle(
                    fontSize: 15, color: itsme ? Colors.black45 : Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
