import 'dart:io';

import 'package:fakeingbar/config.dart';
import 'package:fakeingbar/controller/theme_controller.dart';
import 'package:fakeingbar/data/local_database.dart/database_controller.dart';
import 'package:fakeingbar/models/chat_list_model.dart';
import 'package:fakeingbar/models/gruop_user_list_model.dart';
import 'package:fakeingbar/variables/theme_data.dart';
import 'package:fakeingbar/widgets/chat_appbar.dart';
import 'package:fakeingbar/widgets/chat_bubble.dart';
import 'package:fakeingbar/widgets/custom_circle_avatar.dart';
import 'package:fakeingbar/widgets/k_chat_dialog.dart';
import 'package:fakeingbar/widgets/k_dialog.dart';
import 'package:fakeingbar/widgets/k_filled_button.dart';
import 'package:fakeingbar/widgets/k_voice_msg_sending_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class Chat extends StatefulWidget {
  const Chat({
    Key? key,
  }) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final ThemeController _themeController = Get.find();

  final ScrollController _scrollController = ScrollController();
  // final ItemScrollController _itemScrollController = ItemScrollController();

  final _textBox = "".obs;
  final TextEditingController _textEditingController = TextEditingController();
  final TextEditingController _welcomeMsgController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  late int userId;

  List<GroupUserListModel> groupMembers = [];
  String memberID = '';
  RxString block = "Block".obs;

  @override
  void initState() {
    // _animateToIndex(0);
    // scrollDown();

    Future.delayed(const Duration(milliseconds: 500)).then((_) => scrollDown());

    super.initState();
  }

  FocusNode ftext = FocusNode();

  @override
  void dispose() {
    ftext.dispose();
    super.dispose();
  }

  scrollDown() {
    final double end = _scrollController.position.maxScrollExtent + 500;
    _scrollController.animateTo(end,
        duration: const Duration(microseconds: 1), curve: Curves.bounceOut);
  }

  final RxBool _isfocus = true.obs;

  _autoUnfocus() {
    if (MediaQuery.of(context).viewInsets.bottom == 0) {
      ftext.unfocus();
      _isfocus(false);
    } else {
      scrollDown();
      _isfocus(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _autoUnfocus();
    return GetBuilder<DatabaseController>(
      builder: (_databaseController) {
        print("ChatList: ${_databaseController.currentUserChats}");
        userId = _databaseController.currentUser.value.id!;
        if (_databaseController.currentUser.value.hasGroup!) {
          groupMembers = _databaseController.groupUserList
              .where((g) =>
                  g.friendListID == _databaseController.currentUser.value.id!)
              .toList();
        }
        if (_databaseController.currentUser.value.isBlock == true) {
          block("Unblock");
        }

        return WillPopScope(
          onWillPop: () async {
            _databaseController.currentUserChats.clear();
            debugPrint("${_databaseController.currentUserChats.length}");
            return true;
          },
          child: Scaffold(
            body: Column(
              children: <Widget>[
                _buildAppBar(),
                _buildChat(),
                _buildBottomChat(),
              ],
            ),
          ),
        );
      },
    );
  }

  _buildChat() {
    return GetBuilder<DatabaseController>(
      builder: (_databaseController) {
        return Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: GestureDetector(
              onTap: () {
                if (ftext.hasFocus) {
                  ftext.unfocus();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomeCircleAvatar(
                    user: _databaseController.currentUser.value,
                    picRadius: 50,
                    onlineDotSize: 0,
                  ),
                  SizedBox(
                    height: customWidth(.03),
                  ),
                  Text(
                    _databaseController.currentUser.value.name!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: customWidth(.065),
                      color: _themeController.textColor,
                    ),
                  ),
                  SizedBox(
                    height: customWidth(.015),
                  ),
                  !_databaseController.currentUser.value.hasGroup!
                      ? GestureDetector(
                          onTap: () {
                            showEditChatDialog(_databaseController);
                          },
                          child: Text(
                            _databaseController
                                .currentUser.value.welcomeMessage!,
                            style: TextStyle(
                              color: _themeController.textColor,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  SizedBox(
                    height: customWidth(.015),
                  ),
                  !_databaseController.currentUser.value.hasGroup!
                      ? GestureDetector(
                          onTap: () => showEditChatDialog(_databaseController),
                          child: Text(
                            "Lives in ${_databaseController.currentUser.value.address}",
                            style: TextStyle(
                              color: _themeController.darkenTextColor,
                            ),
                          ),
                        )
                      : const SizedBox(),
                  SizedBox(
                    height: customWidth(.03),
                  ),
                  Obx(
                    () => ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      // itemScrollController: _itemScrollController,

                      physics: const ClampingScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        print("new: $index old: ${_databaseController.isNew}");
                        print("Member id.........: $memberID ");
                        return ChatBubble(
                          // chatList: _databaseController.currentUserChats[index],
                          chatId:
                              _databaseController.currentUserChats[index].id!,
                          user: _databaseController.currentUser,
                          chatIndex: index,
                        );
                      },
                      itemCount: _databaseController.currentUserChats.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  _buildAppBar() {
    return GetBuilder<DatabaseController>(
      builder: (_databaseController) {
        return GestureDetector(
          onTap: () {
            if (ftext.hasFocus) {
              ftext.unfocus();
            }
          },
          child: ChatAppBarAction(
            isBack: true,
            isOnline: _databaseController.currentUser.value.isOnline!,
            title: _databaseController
                .currentUser.value.name!, //widget.friendItem!.name,
            imageUrl: _databaseController.currentUser.value
                .imageUrl!, //widget.friendItem!.imageAvatarUrl,
            subTitle: _databaseController.currentUser.value.isOnline == true
                ? 'Active now'
                : _databaseController.currentUser.value.inactiveTime != null
                    ? "Active ${_databaseController.currentUser.value.inactiveTime}"
                    : "offline",
            color: SThemeData
                .chatColors[_databaseController.currentUser.value.chatColor!],
          ),
        );
      },
    );
  }

  _buildBottomChat() {
    return GetBuilder<DatabaseController>(
      builder: (_databaseController) {
        return _databaseController.currentUser.value.isBlock == false
            ? Container(
                decoration: BoxDecoration(
                    color: _themeController.scaffoldBackgroundColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 1,
                        offset: Offset(0, -1),
                        spreadRadius: .5,
                      )
                    ]),
                padding: EdgeInsets.only(
                  top: 5.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom == 0
                      ? customWidth(.06)
                      : customWidth(.02),
                  left: 10,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(
                        left: customWidth(.02),
                        right: ftext.hasFocus ? customWidth(.02) : 0,
                      ),
                      child: _isfocus.isTrue
                          ? Icon(
                              Icons.arrow_forward_ios,
                              color: SThemeData.chatColors[_databaseController
                                  .currentUser.value.chatColor!],
                              size: customWidth(.06),
                            )
                          : SvgPicture.asset(
                              'assets/svg/image2vector.svg',
                              fit: BoxFit.scaleDown,
                              height: customWidth(.06),
                              width: customWidth(.06),
                              color: SThemeData.chatColors[_databaseController
                                  .currentUser.value.chatColor!],
                            ),
                    ),
                    _isfocus.isTrue
                        ? const SizedBox()
                        : Expanded(
                            flex: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  FontAwesomeIcons.camera,
                                  size: 20.0,
                                  color: SThemeData.chatColors[
                                      _databaseController
                                          .currentUser.value.chatColor!],
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await getImageForMessage(
                                        _databaseController);
                                  },
                                  child: Icon(
                                    CupertinoIcons.photo,
                                    size: 20.0,
                                    color: SThemeData.chatColors[
                                        _databaseController
                                            .currentUser.value.chatColor!],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showVoiceMessageDialog(),
                                  child: Icon(
                                    CupertinoIcons.mic_solid,
                                    size: 20.0,
                                    color: SThemeData.chatColors[
                                        _databaseController
                                            .currentUser.value.chatColor!],
                                  ),
                                ),
                              ],
                            ),
                          ),
                    //text field
                    Expanded(
                      flex: 50,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        height: MediaQuery.of(context).size.width * .11,
                        child: TextField(
                          focusNode: ftext,
                          autofocus: false,
                          controller: _textEditingController,
                          onChanged: (value) {
                            _textBox(value);
                          },
                          onTap: () async => await Future.delayed(
                                  const Duration(milliseconds: 2005))
                              .then((_) => scrollDown()),
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(10.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  width: 0,
                                  style: BorderStyle.none,
                                ),
                              ),
                              hintText: 'Aa',
                              filled: true,
                              hintStyle: TextStyle(
                                color: _themeController.darkenTextColor,
                              ),
                              suffixIcon: Icon(
                                FontAwesomeIcons.solidSmileBeam,
                                size: 22.0,
                                color: SThemeData.chatColors[_databaseController
                                    .currentUser.value.chatColor!],
                              )),
                        ),
                      ),
                    ),
                    //Send Button
                    Padding(
                      padding: EdgeInsets.only(
                        right: customWidth(0.03),
                        left: customWidth(0.03),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          RxBool isThumup = false.obs;
                          if (_textBox.isEmpty &&
                              _textEditingController.text.trim().isEmpty) {
                            isThumup(true);
                          }
                          if (!DateTime.now().isBlank!) {
                            if (_databaseController
                                .currentUser.value.hasGroup!) {
                              await _hasGroup(_databaseController);
                              if (memberID.trim().isEmpty) {
                                return;
                              }
                            }
                            String reply = "Don't understand what you say!!😒";

                            for (var chat
                                in _databaseController.trainerChatList) {
                              if (chat.question ==
                                  _textEditingController.text.trim()) {
                                print(
                                    "question: ${chat.question}, answer: ${chat.answer}");
                                reply = chat.answer!;
                              }
                            }
                            await _databaseController.insertChat(ChatListModel(
                                friendListID:
                                    _databaseController.currentUser.value.id,
                                sendMessage: _textEditingController.text.trim(),
                                memberID: memberID,
                                messageType:
                                    isThumup.isTrue ? "thumsUp" : "text",
                                receiveMessage: reply,
                                senderTime: DateTime.now(),
                                receiveTime: DateTime.now(),
                                isReceived: "received"));
                            await _databaseController.updateUser(
                              _databaseController.currentUser.value.copyWith(
                                  lastMessage: isThumup.isTrue
                                      ? "👍"
                                      : _textEditingController.text.trim(),
                                  lastMessageTime: DateTime.now()),
                              _databaseController.currentUser.value.id!,
                            );
                            _databaseController.updateCurrentUser(userId);

                            _textBox.value = '';
                            _textEditingController.clear();
                            setState(() {
                              memberID = "";
                            });

                            _databaseController.isNew(true);
                            // _scrollToIndex(
                            //     _databaseController.currentUserChats.length +
                            //         1);
                            scrollDown();

                            await Future.delayed(
                                    const Duration(milliseconds: 2005))
                                .then((_) => scrollDown());
                          }
                        },
                        child: Obx(
                          () => _textBox.isEmpty
                              ? Icon(
                                  FontAwesomeIcons.solidThumbsUp,
                                  size: 22.0,
                                  color: SThemeData.chatColors[
                                      _databaseController
                                          .currentUser.value.chatColor!],
                                )
                              : Icon(
                                  Icons.send,
                                  size: 22.0,
                                  color: SThemeData.chatColors[
                                      _databaseController
                                          .currentUser.value.chatColor!],
                                ),
                        ),
                      ),
                    ),
                  ],
                ))
            //user block
            : Container(
                height: customWidth(.175),
                width: double.infinity,
                color: SThemeData.lightThemeColor,
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.only(top: 5.0, bottom: 20.0, left: 10),
                child: RichText(
                  text: const TextSpan(
                    text: "You can't reply to this conversation.",
                    style: TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                        text: "Learn More",
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              );
      },
    );
  }

  _hasGroup(DatabaseController _databaseController) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  groupMembers.isEmpty
                      ? const Text("Add Member...")
                      : const SizedBox(),
                  ...groupMembers.map((group) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: FileImage(File(group.imageUrl!)),
                      ),
                      title: Text(group.name!),
                      onTap: () => setState(() {
                        memberID = group.id!.toString();
                        Navigator.pop(context);
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> getImageForMessage(
      DatabaseController _databaseController) async {
    File? image = await _databaseController.pickImage();
    if (image != null) {
      if (!DateTime.now().isBlank!) {
        if (_databaseController.currentUser.value.hasGroup!) {
          await _hasGroup(_databaseController);
          if (memberID.trim().isEmpty) {
            return;
          }
        }
        await _databaseController.insertChat(ChatListModel(
            friendListID: _databaseController.currentUser.value.id,
            sendMessage: image.path,
            memberID: memberID,
            messageType: "image",
            receiveMessage: "hi",
            senderTime: DateTime.now(),
            receiveTime: DateTime.now(),
            isReceived: "received"));
        _databaseController.updateUser(
          _databaseController.currentUser.value.copyWith(
              lastMessage: "You sent an Image",
              lastMessageTime: DateTime.now()),
          _databaseController.currentUser.value.id!,
        );
        _databaseController.updateCurrentUser(userId);

        _textBox.value = '';
        _textEditingController.clear();
        setState(() {
          memberID = "";
        });
      }
    }
  }

  Future<dynamic> _showVoiceMessageDialog() {
    return showDialog(
        context: context,
        builder: (context) {
          return GetBuilder<DatabaseController>(
            builder: (_databaseController) {
              return KVoiceMsgSendingDialog(
                time: _timeController,
                hintText: "Set Time",
                btnText: "Send",
                onPressed: () async {
                  if (_timeController.text.trim().isNotEmpty) {
                    if (!DateTime.now().isBlank!) {
                      if (_databaseController.currentUser.value.hasGroup!) {
                        await _hasGroup(_databaseController);
                        if (memberID.trim().isEmpty) {
                          return;
                        }
                      }
                      await _databaseController.insertChat(ChatListModel(
                          friendListID:
                              _databaseController.currentUser.value.id,
                          sendMessage: _timeController.text.trim(),
                          memberID: memberID,
                          messageType: "voice",
                          receiveMessage: "hi",
                          senderTime: DateTime.now(),
                          receiveTime: DateTime.now(),
                          isReceived: "received"));
                      await _databaseController.updateUser(
                        _databaseController.currentUser.value.copyWith(
                            lastMessage: "You sent a Voice",
                            lastMessageTime: DateTime.now()),
                        _databaseController.currentUser.value.id!,
                      );

                      _databaseController.updateCurrentUser(userId);

                      _timeController.clear();
                      setState(() {
                        memberID = "";
                      });

                      Navigator.pop(context);
                    }
                  }
                },
              );
            },
          );
        });
  }

  Future<dynamic> showEditChatDialog(DatabaseController _databaseController) {
    return showDialog(
      context: context,
      builder: (context) => KChatDialog(
        firstText: _welcomeMsgController,
        secondText: _addressController,
        name: "Edit Chat",
        hintText1: _databaseController.currentUser.value.welcomeMessage!,
        hintText2: _databaseController.currentUser.value.address!,
        btnText: "Save",
        onPressed: () async {
          await _databaseController.updateUser(
              _databaseController.currentUser.value.copyWith(
                welcomeMessage: _welcomeMsgController.text.trim().isNotEmpty
                    ? _welcomeMsgController.text.trim()
                    : _databaseController.currentUser.value.welcomeMessage,
                address: _addressController.text.trim().isNotEmpty
                    ? _addressController.text.trim()
                    : _databaseController.currentUser.value.address,
              ),
              userId);

          _databaseController.updateCurrentUser(userId);
          Navigator.pop(context);
        },
      ),
    );
  }
}
