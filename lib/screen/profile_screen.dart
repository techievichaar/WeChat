import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/helper/dilogues.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screen/auth/loginscreen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Size mq = MediaQuery.of(context).size;
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  void initState() {
    super.initState();
    // Initialize APIs.me with the user data
    APIs.me = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // for hiding keyboard
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile Screen"),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: Column(
              children: [
                SizedBox(
                  width: mq.width,
                  height: mq.height * .03,
                ),
                Stack(
                  children: [
                    // profile picture
                    _image != null
                        ? // local image
                        ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.file(
                              File(_image!),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          )
                        : // image from Server
                        ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: CachedNetworkImage(
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                              imageUrl: widget.user.image,
                              // placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const CircleAvatar(
                                child: Icon(CupertinoIcons.person),
                              ),
                            ),
                          ),
                    // edit image button
                    Positioned(
                      bottom: -4,
                      right: -12,
                      child: MaterialButton(
                        elevation: 1,
                        onPressed: () {
                          _showBottomSheet();
                        },
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: mq.width,
                  height: mq.height * .03,
                ),
                // user email label
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  width: mq.width,
                  height: mq.height * .03,
                ),
                // name input field
                TextFormField(
                  initialValue: widget.user.name,
                  onSaved: (val) => APIs.me.name = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: "eg: Linkan Yadav",
                    label: const Text("Name"),
                  ),
                ),
                SizedBox(
                  width: mq.width,
                  height: mq.height * .02,
                ),
                // about input field
                TextFormField(
                  initialValue: widget.user.about,
                  onSaved: (val) => APIs.me.about = val ?? '',
                  validator: (val) =>
                      val != null && val.isNotEmpty ? null : 'Required Field',
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: "eg: Hey, I'm using WeChat",
                    label: const Text("About"),
                  ),
                ),
                SizedBox(
                  width: mq.width,
                  height: mq.height * .05,
                ),
                // update button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: Size(
                      mq.width * .5,
                      mq.height * .05,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      APIs.updateUserInfo().then((value) {
                        Dilogues.showSnacBar(
                            context, "Profile Updated Successfully:)");
                      });
                    }
                  },
                  label: const Text(
                    "Updated",
                    style: TextStyle(fontSize: 16),
                  ),
                  icon: const Icon(
                    Icons.edit,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),

        //  logout button
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              await APIs.updateActiveStatus(false);

              Dilogues.showProgressBar(context);
              await FirebaseAuth.instance.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  //for hiding progress
                  Navigator.pop(context);
                  // for moving to home screen
                  Navigator.pop(context);

                  APIs.auth = FirebaseAuth.instance;
                  // replacing homescreen to logiin screen

                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                });
              });
            },
            label: const Text("Logout"),
            icon: const Icon(Icons.logout_outlined),
          ),
        ),
      ),
    );
  }

  // show bottom sheet after click change profile picture
  void _showBottomSheet() {
    showModalBottomSheet(
        backgroundColor: Colors.white,
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        )),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            padding: EdgeInsets.only(
              top: mq.height * .03,
              bottom: mq.height * .05,
            ),
            children: [
              const Text(
                "Pick Profile Picture Using",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // cameara image picker button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        fixedSize: Size(
                          mq.width * .3,
                          mq.height * .15,
                        )),
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        setState(() {
                          _image = image.path;
                        });
                        APIs.updatePRofilePicture(File(_image!));
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset("assets/camera.png"),
                  ),
                  // galary image picker button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: const CircleBorder(),
                        fixedSize: Size(
                          mq.width * .3,
                          mq.height * .15,
                        )),
                    onPressed: () async {
                      final ImagePicker _picker = ImagePicker();
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          _image = image.path;
                        });
                        APIs.updatePRofilePicture(File(_image!));
                        Navigator.pop(context);
                      }
                    },
                    child: Image.asset("assets/galary.png"),
                  ),
                ],
              )
            ],
          );
        });
  }
}
