import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cryp_comm/service/alert_service.dart';
import '/service/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '/models/chatmessage.dart';
import '/models/profile.dart';
import '/service/auth_service.dart';
import '/service/media_service.dart';
import '/main.dart';
import '/models/chat.dart';
import '/models/message.dart';
import '/service/database_service.dart';
import '/service/storage_service.dart';
import '/models/chatuser.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;
import 'dart:typed_data';
import 'home.dart' as home;

class ChatPage extends StatefulWidget {
  final Profile chatUser;
  final String date;
  final String chatkey;
  const ChatPage({Key? key, required this.chatUser, required this.date,required this.chatkey});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final encrypt.Key encryptedkey ;
  late encrypt.Encrypter encrypter;
  bool _isOtherUserActive=false;
  late String chatId;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  ChatUser? currentUser, otherUser;
  late AuthService _authService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late PushNotificationService _pushNotificationService;
  Profile? myself;
  bool _isLoading = true;
  bool isUploading = false; // Add state variab
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool isTodayOrFuture=false;
  bool fakeuser=false;

  @override
  void initState() {
    super.initState();

    final chatKeyBytes = utf8.encode(widget.chatkey);
    final sha256 = crypto.sha256.convert(chatKeyBytes);
    final chatKey = sha256.bytes;

    encryptedkey = encrypt.Key(Uint8List.fromList(chatKey));
    encrypter = encrypt.Encrypter(encrypt.AES(encryptedkey));
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _pushNotificationService = _getIt.get<PushNotificationService>();
    _alertService = _getIt.get<AlertService>();
    Future.microtask(() async {
      await _initializeChat();

    });
    chatId =generateChatID(uid1:_authService.user!.uid,uid2: widget.chatUser.userid);

    _databaseService.enterChat(chatId, _authService.user!.uid);


    // Listen to chat updates

    
  }

  @override
  void dispose() {

    _databaseService.leaveChat(chatId, _authService.user!.uid);

    super.dispose();
  }

  Future<void> _initializeChat() async {
    myself = await _databaseService.fetchPersonalProfile();
    setState(() {
      currentUser = ChatUser(
        id: _authService.user!.uid,
        firstName: _authService.user!.displayName,
        profileImage: myself?.pfpURL,
      );
      otherUser = ChatUser(
        id: widget.chatUser.userid,
        firstName: widget.chatUser.email.split('@')[0],
        profileImage: widget.chatUser.pfpURL,
      );
      _isLoading = false;
    });
    await _databaseService.markMessagesAsRead(
      currentUser!.id,
      otherUser!.id,
    );



  }




  void _confirmDeleteMessage(BuildContext context, ChatMessage message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Message'),
          content: Text('Are you sure you want to delete this message?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteMessage(message); // Call the delete function
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(ChatMessage message) async {
    setState(() {
      _messages.remove(message);
    });

    try {
      await _databaseService.deleteChatMessage(
        currentUser!.id,
        otherUser!.id,
        message.createdAt,
      );
    } catch (e) {
      // Handle error if necessary
      print('Error deleting message: $e');
    }
  }






  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 30.0,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.chatUser.pfpURL!,
                  placeholder: (context, url) => Image.asset(
                    'assets/loading.gif',
                    fit: BoxFit.cover,
                    width: 50.0,
                    height: 50.0,
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  fit: BoxFit.cover,
                  width: 50.0,
                  height: 50.0,
                ),
              ),
            ),
            SizedBox(
                width: 8.0), // Add some space between the avatar and the text
            Text(
              widget.chatUser.email.split('@')[0],
            ),
          ],
        ),
      ),
      body:
      _isLoading ? Center(child: CircularProgressIndicator()) : _buildUI(),
    );
  }



  Widget _buildUI() {
    DateTime selectedDate = DateTime.parse(widget.date);
    isTodayOrFuture = selectedDate.isAfter(DateTime.now().subtract(Duration(days: 1)));
    return StreamBuilder(
      stream: _databaseService.getChatDataForDate(currentUser!.id, otherUser!.id,selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text("No chat data available"));
        }

        Chat? chat = snapshot.data!;
        List<ChatMessage> messages = [];

        if (chat != null) {
          messages = _generateChatMessagesList(chat.messages);
        }

        return _buildChatUI(messages,isTodayOrFuture);
      },
    );
  }

  String _getRandomFallbackImage() {
    // List of fallback image asset paths
    final List<String> fallbackImages = [
      'assets/fallback1.jpg',
      'assets/fallback2.jpg',
      'assets/fallback3.jpg',
      'assets/fallback4.jpg',
      'assets/fallback5.png',
      // Add more image paths as needed
    ];

    // Return a random image path
    final randomIndex = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % fallbackImages.length;
    return fallbackImages[randomIndex];
  }

  Widget _buildChatUI(List<ChatMessage> messages, bool inputdetector) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isCurrentUser = message.user.id == currentUser!.id;
              final bool isRead = message.read ?? false; // Default to false if null
              return Align(
                alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Make background transparent
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (message.medias != null && message.medias!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: message.medias!.first.url,
                          placeholder: (context, url) => CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image.asset(
                            _getRandomFallbackImage(), // Replace with your method to get a random image
                            fit: BoxFit.cover,
                          ),
                          fit: BoxFit.cover,
                        ),
                      if (message.text.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCurrentUser ? Colors.blue : Colors.grey, // Different border color for current user
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            message.text,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      SizedBox(height: 5.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "${message.createdAt.year}-${message.createdAt.month.toString().padLeft(2, '0')}-${message.createdAt.day.toString().padLeft(2, '0')} ${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.black, fontSize: 10.0),
                          ),
                          Row(
                            children: [
                              SizedBox(width: 15,),
                              if (isCurrentUser) // Only show status for messages sent by the current user
                                Icon(
                                  isRead ? Icons.done_all : Icons.done,
                                  color: isRead ? Colors.blue : Colors.grey,
                                  size: 16.0,
                                ),
                              IconButton(
                                icon: Icon(Icons.delete, size: 16.0),
                                onPressed: () => _confirmDeleteMessage(context, message),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (inputdetector && !fakeuser)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async => _sendMessage(ChatMessage(
                    user: currentUser!,
                    createdAt: DateTime.now(),
                    text: _controller.text,
                    read: await _databaseService.isChatActiveUser(chatId, otherUser!.id), // Initially set to unread when sending
                  )),
                ),
                _mediaMessageButton(),
              ],
            ),
          ),
      ],
    );
  }







  Widget _mediaMessageButton() {
    return IconButton(
      onPressed: () async {

        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          String? downloadURL = await _storageService.uploadImageToChat(
              file: file,
              chatID: generateChatID(
                  uid1: _authService.user!.uid, uid2: widget.chatUser.userid));
          if (downloadURL != null) {
            ChatMessage chatMessage = ChatMessage(
              read:  await _databaseService.isChatActiveUser(chatId, otherUser!.id),
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                      url: downloadURL, fileName: "", type: MediaType.image)
                ]);
            await _sendMessage(chatMessage);
          }
        }

      },
      icon: Icon(
        color: Theme.of(context).colorScheme.primary,
        Icons.image,
      ),
    );
  }



  Future<void> _sendMessage(ChatMessage chatMessage) async {
    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        final messageUrl = chatMessage.medias?.first.url;
        final iv = encrypt.IV.fromLength(16); // Generate a new IV for each message
        final encrypted = encrypter.encrypt(messageUrl!, iv: iv);
        final encryptedString = encrypted.base64;
        final ivString = iv.base64; // Store the IV as base64
        print("printing stattus beofore........");
        print(chatMessage.read);

        Message message = Message(
          senderID: chatMessage.user.id,
          content: encryptedString,
          iv: ivString, // Store IV with the message
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
          read: chatMessage.read,
        );
        print(chatMessage.read);
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      final iv = encrypt.IV.fromLength(16); // Generate a new IV for each message
      final encrypted = encrypter.encrypt(chatMessage.text, iv: iv);
      final encryptedString = encrypted.base64;
      final ivString = iv.base64; // Store the IV as base64

      Message messageencrypt = Message(
        read: chatMessage.read,
        senderID: currentUser!.id,
        content: encryptedString,
        iv: ivString, // Store IV with the message
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );
      print(chatMessage.read);
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        messageencrypt,
      );
      _controller.text = "";
    }

      String? deviceToken =
      await _pushNotificationService.getToken(otherUser!.id);
      _pushNotificationService.sendNotificationToSelectedDriver(deviceToken!);
  }


  String safeDecrypt(String encryptedContent, encrypt.IV iv) {
    try {
      return encrypter.decrypt64(encryptedContent, iv: iv);
    } catch (e) {
      // Return a placeholder for corrupted messages

      fakeuser=true;

      _alertService.showToast(
        assetIconPath: 'assets/malicious.png',
        text: "Malicious User identified. Sending location, mobile FCM number, and ID details to the headquarter....",
      );

      return "[Encrypted Message]";
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      final iv = encrypt.IV.fromBase64(m.iv); // Retrieve IV from the message
      String decryptedContent = safeDecrypt(m.content!, iv);


      print("printing stattus during generating chat message........");
      print(m.read);
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          read: m.read,
          medias: [
            ChatMedia(
              url: decryptedContent == "[Encrypted Message]" ? "" : decryptedContent,
              fileName: "",
              type: MediaType.image,
            )
          ],
        );
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: decryptedContent,
          read: m.read,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();

    chatMessages.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt);
    });
    return chatMessages;
  }

}
