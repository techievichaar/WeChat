import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/helper/my_date_util.dart';
import 'package:wechat/models/message.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  late Size mq = MediaQuery.of(context).size;
  @override
  Widget build(BuildContext context) {
    return APIs.user.uid == widget.message.fromId
        ? _greenMessage()
        : _blueMessage();
  }

  // blue messege card means recevier messge showing in this card
  Widget _blueMessage() {
    // update last read message if sender and reciver are diffrent
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                vertical: mq.width * .04, horizontal: mq.height * .01),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.lightBlue,
                ),
                color: const Color.fromARGB(225, 221, 245, 255),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                )),
            child:
                // conditon for showing text if will be text and image for will be mage
                widget.message.type == Type.text
                    ?

                    // for sending text messege
                    Text(
                        widget.message.msg,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      )

                    /// for sending image meessge
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .03),
                        child: CachedNetworkImage(
                          imageUrl: widget.message.msg,
                          placeholder: (context, url) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.image,
                            size: 70,
                          ),
                        ),
                      ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // green messege card means sender messge showing in this card
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // send message time and double tic
        Row(
          children: [
            const SizedBox(width: 2),
            // double tic blue icon for messge read
            if (widget.message.read.isNotEmpty)
              const Icon(
                Icons.done_all_rounded,
                color: Colors.blue,
              ),

            // for adding some space
            const SizedBox(width: 2),
            // read time or read time
            Text(
              MyDateUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .02
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                vertical: mq.width * .04, horizontal: mq.height * .01),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.lightGreen,
                ),
                color: const Color.fromARGB(255, 218, 255, 176),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                )),
            child: widget.message.type == Type.text
                ? Text(
                    widget.message.msg,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .02),
                    child: CachedNetworkImage(
                      imageUrl: widget.message.msg,
                      placeholder: (context, url) => const Padding(
                        padding: EdgeInsets.all(8.0),
                        child:
                            CircularProgressIndicator.adaptive(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image,
                        size: 70,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
