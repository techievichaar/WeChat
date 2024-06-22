import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/models/message.dart';
import 'package:wechat/screen/chat_screen.dart';
import 'package:wechat/widgets/dilogues/profile_dilogue.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  late Size mq = MediaQuery.of(context).size;

  // last message info( if null --> no message)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(1),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: mq.width * 0.02,
        vertical: 4,
      ),
      child: InkWell(
          onTap: () {
            // chat screen
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    user: widget.user,
                  ),
                ));
          },
          child: StreamBuilder(
              stream: APIs.getLastMessage(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final list =
                    data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
                if (list.isNotEmpty) {
                  _message = list[0];
                }

                return ListTile(
                  // user name
                  title: Text(widget.user.name),
                  // user last messege
                  subtitle: Text(
                    _message != null
                        ? _message!.type == Type.image
                            ? 'Image'
                            : _message!.msg
                        : widget.user.about,
                    maxLines: 1,
                  ),
                  // user profile pic
                  // leading: const CircleAvatar(
                  //   child: Icon(CupertinoIcons.person),
                  leading: InkWell(
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (_) => ProfileDilogue(
                                user: widget.user,
                              ));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: CachedNetworkImage(
                        height: 50,
                        width: 50,
                        imageUrl: widget.user.image,
                        // placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(
                          child: Icon(CupertinoIcons.person),
                        ),
                      ),
                    ),
                  ),
                  // last messege time
                  trailing: _message == null
                      ? null
                      : _message!.read.isEmpty &&
                              _message!.fromId != APIs.user.uid
                          ? Container(
                              height: 15,
                              width: 15,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            )
                          : Text(
                              MyDateUtil.getFormattedTime(
                                  context: context, time: _message!.sent),
                              style: const TextStyle(color: Colors.black54),
                            ),
                  // trailing: const Text(
                  //   "03:03 PM",
                  //   style: TextStyle(color: Colors.black54),
                  // ),
                );
              })),
    );
  }
}
