import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wechat/api/api.dart';
import 'package:wechat/models/chat_user.dart';
import 'package:wechat/screen/profile_screen.dart';
import 'package:wechat/widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // store all users
  List<ChatUser> _list = [];
  // for storing search data
  final List<ChatUser> _searchList = [];
  // for storing search status
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    late Size mq = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      // ignore: deprecated_member_use
      child: WillPopScope(
        onWillPop: () {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    textInputAction: TextInputAction.search,
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                    // when text changes then update search list
                    onChanged: (val) {
                      _searchList.clear();
                      for (var i in _list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) ||
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                      }
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Name, Email ...',
                      border: InputBorder.none,
                    ),
                  )
                : const Text("WeChat"),
            centerTitle: true,
            leading: _isSearching
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear(); // Clear the search input
                      });
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                    ),
                  )
                : const Icon(CupertinoIcons.home),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(_isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : CupertinoIcons.search),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(user: APIs.me)));
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: StreamBuilder(
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                // if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

                // if some or all data is loaded then show it
                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  _list =
                      data?.map((e) => ChatUser.fromJson(e.data())).toList() ??
                          [];
                  if (_list.isNotEmpty) {
                    return ListView.builder(
                        padding: EdgeInsets.only(top: mq.height * .01),
                        itemCount:
                            _isSearching ? _searchList.length : _list.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ChatUserCard(
                            user: _isSearching
                                ? _searchList[index]
                                : _list[index],
                          );
                        });
                  } else {
                    return const Center(
                      child: Text("No Connection Found :("),
                    );
                  }
              }
            },
            stream: APIs.getAllUsers(),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () {},
              child: const Icon(
                Icons.add_comment_rounded,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
