import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screen/view_profile.dart';

class ProfileDilogue extends StatelessWidget {
  const ProfileDilogue({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    late Size mq = MediaQuery.of(context).size;
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white.withOpacity(.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SizedBox(
        width: mq.width * .6,
        height: mq.height * .35,
        child: Stack(
          children: [
            // user profile pic
            Positioned(
              top: mq.height * 0.05,
              left: mq.width * .034,
              child: Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(125),
                  child: CachedNetworkImage(
                    width: 250,
                    fit: BoxFit.cover,
                    imageUrl: user.image,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const CircleAvatar(
                      child: Icon(CupertinoIcons.person),
                    ),
                  ),
                ),
              ),
            ),
            // user Name
            Positioned(
              top: mq.height * .01,
              left: mq.width * .035,
              width: mq.width * .55,
              child: Text(
                user.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Align(
                alignment: Alignment.topRight,
                child: MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ViewProfileScreen(user: user)));
                  },
                  minWidth: 0,
                  padding: const EdgeInsets.all(0),
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 30,
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
