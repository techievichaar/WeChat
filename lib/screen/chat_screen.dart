import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/models/message.dart';
import 'package:wechat/screen/view_profile.dart';
import 'package:wechat/widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        statusBarColor: Colors.white,
        statusBarIconBrightness:
            Brightness.light, // This ensures icons are visible
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  late Size mq = MediaQuery.of(context).size;

  List<Message> _list = [];
  // for handling send messge text changes
  final _textController = TextEditingController();
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (_showEmoji) {
            setState(() {
              _showEmoji = false;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
            backgroundColor: const Color.fromARGB(232, 234, 248, 255),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
              backgroundColor: Colors.white,
              elevation: 2,
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        // if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();
                        // if some or all data is loaded then show it
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          _list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                                padding: EdgeInsets.only(top: mq.height * .01),
                                reverse: true,
                                itemCount: _list.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(
                                    message: _list[index],
                                  );
                                });
                          } else {
                            return const Center(
                              child: Text(
                                "Say Hi👋",
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),
                // progress indicator when send or multiple image from galary
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: CircularProgressIndicator.adaptive(
                          strokeAlign: 2,
                        ),
                      )),
                _chatInput(),
                // emoji picker
                if (_showEmoji == true)
                  EmojiPicker(
                    textEditingController:
                        _textController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
                    config: Config(
                      height: mq.height * .35,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                      ),
                    ),
                  ),
                SizedBox(
                  height: mq.height * .02,
                )
              ],
            )),
      ),
    );
  }

  Widget _appBar() {
    return SafeArea(
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: APIs.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

            return Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black54,
                  ),
                ),
                // Add user info and other widgets here
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .03),
                  child: CachedNetworkImage(
                    width: mq.height * .05,
                    height: mq.height * .05,
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    errorWidget: (context, url, error) => const CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // chating current user name
                    Text(
                      list.isNotEmpty ? list[0].name : widget.user.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // last seen time
                    Text(
                      list.isNotEmpty
                          ? list[0].isOnline
                              ? 'Online'
                              : MyDateUtil.getLastActiveTime(
                                  context: context,
                                  lastActive: list[0].lastActive)
                          : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: widget.user.lastActive),
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: mq.height * .01,
        horizontal: mq.width * .025,
      ),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  /// emoji button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showEmoji = !_showEmoji;
                      });
                    },
                    icon: const Icon(
                      Icons.emoji_emotions,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  Expanded(
                      child: TextField(
                    onTap: () {
                      if (_showEmoji == true) {
                        setState(() {
                          _showEmoji = !_showEmoji;
                        });
                      }
                    },
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type Something...",
                        hintStyle: TextStyle(
                          color: Colors.blueAccent,
                        )),
                  )),
                  // galary image pic button for send while chatting
                  IconButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();

                      // picking multiple images
                      final List<XFile> images = await _picker.pickMultiImage(
                        imageQuality: 70,
                      );
                      // uploading and sending image one by one
                      for (var i in images) {
                        setState(() {
                          _isUploading = true;
                        });
                        await APIs.sendChatImage(widget.user, File(i.path));
                        setState(() {
                          _isUploading = false;
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.image,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  // camera button for sharing image while chating
                  IconButton(
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        setState(() {
                          _isUploading = true;
                        });
                        await APIs.sendChatImage(widget.user, File(image.path));
                        setState(() {
                          _isUploading = false;
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                  SizedBox(width: mq.width * .02)
                ],
              ),
            ),
          ),
          // send message button
          MaterialButton(
            minWidth: 0,
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 5,
              left: 10,
            ),
            elevation: 1,
            shape: const CircleBorder(),
            color: Colors.green,
            onPressed: () {
              // send message logic
              if (_textController.text.isNotEmpty) {
                APIs.sendMessage(widget.user, _textController.text, Type.text);
                _textController.text = '';
              }
            },
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );
  }
}
