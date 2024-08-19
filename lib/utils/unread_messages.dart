import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../models/profile.dart';
import '../models/message.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import '../service/navigation_service.dart';
import '../widget/navigation_drawer.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart' as crypto;

import '../widget/shaking_tile.dart';
import 'chat_page.dart';

class UnreadMessages extends StatefulWidget {
  const UnreadMessages({Key? key}) : super(key: key);

  @override
  State<UnreadMessages> createState() => _UnreadMessagesState();
}

class _UnreadMessagesState extends State<UnreadMessages> {
  late final encrypt.Key encryptedkey;
  late encrypt.Encrypter encrypter;
  late NavigationService _navigationService;
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _selectedDate = DateTime.now();
    _navigationService = _getIt.get<NavigationService>();
  }

  String _formatTimeAgo(DateTime sentAt) {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showDialog(Profile userProfile) {
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate); // Display date as text

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Key"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                TextField(
                  readOnly: true,controller: _dateController,
              decoration: const InputDecoration(
                  labelText: 'Sent ',
                  border: OutlineInputBorder()),
            ),


                const SizedBox(height: 20),
                TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                      labelText: 'Encryption Key',
                      hintText: 'Must be 16 chars long',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToChatPage(userProfile);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToChatPage(Profile userProfile) {
    String date = _dateController.text;
    String key = _keyController.text;

    _keyController.clear();
    _navigationService.push(MaterialPageRoute(builder: (context) {
      return ChatPage(chatUser: userProfile, date: date, chatkey: key);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unread Messages',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green, // Set the AppBar background color
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: NavigationDrawerWidget(initialSelectedIndex: 2),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: StreamBuilder<List<Message>>(
          stream: _databaseService.getUnreadMessagesStreamForCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final messages = snapshot.data ?? [];

            return ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (context, index) => Divider(height: 1.0, color: Colors.grey[400]), // Divider between items
              itemBuilder: (context, index) {
                final message = messages[index];
                final senderId = message.senderID!;

                return FutureBuilder<Profile?>(
                  future: _databaseService.fetchProfile(senderId),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        leading: CircleAvatar(child: CircularProgressIndicator()),
                        title: Text('Loading...'),
                        subtitle: Text(
                          message.sentAt?.toDate().toString() ?? 'Unknown date',
                        ),
                      );
                    }

                    if (profileSnapshot.hasError || !profileSnapshot.hasData) {
                      return ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Unknown'),
                        subtitle: Text(
                          message.sentAt?.toDate().toString() ?? 'Unknown date',
                        ),
                      );
                    }

                    final profile = profileSnapshot.data!;
                    _selectedDate = message.sentAt?.toDate() ?? DateTime.now(); // Update selected date

                    return ShakingListTile(
                      child: ListTile(
                        style: ListTileStyle.list,
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(profile.pfpURL!),
                        ),
                        title: Text(
                          profile.email.split('@')[0],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd hh:mm a').format(message.sentAt!.toDate()),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          _formatTimeAgo(message.sentAt!.toDate()),
                          style: TextStyle(color: Colors.blue[600]),
                        ),
                        onTap: () => _showDialog(profile),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

}



  // void _showDialog(Message message) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Enter Key"),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             children: [
  //               TextField(
  //                 controller: _keyController,
  //                 decoration: const InputDecoration(
  //                   labelText: 'Encryption Key',
  //                   hintText: 'Must be 16 characters long',
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Cancel"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: const Text("OK"),
  //             onPressed: () {
  //               final key = _keyController.text;
  //               final chatKeyBytes = utf8.encode(key);
  //               final sha256 = crypto.sha256.convert(chatKeyBytes);
  //               final chatKey = encrypt.Key.fromBase64(base64Encode(sha256.bytes));
  //               final iv = encrypt.IV.fromBase64(message.iv);
  //
  //               encrypter = encrypt.Encrypter(encrypt.AES(chatKey));
  //
  //               final decryptedMessage = _generateChatMessage(message, iv);
  //               Navigator.of(context).pop();
  //               _showDecryptedMessage(decryptedMessage);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  //
  //
  // String safeDecrypt(String encryptedContent, encrypt.IV iv) {
  //   try {
  //     return encrypter.decrypt64(encryptedContent, iv: iv);
  //   } catch (e) {
  //     // Return a placeholder for corrupted message
  //
  //     return "[Encrypted Message]";
  //   }
  // }
  //
  //
  // String _generateChatMessage(Message message, encrypt.IV iv) {
  //   final decryptedContent = safeDecrypt(message.content!, iv);
  //   if (message.messageType == MessageType.Image) {
  //     return "Image: $decryptedContent";
  //   } else {
  //     return "Text: $decryptedContent";
  //   }
  // }
  //
  // void _showDecryptedMessage(String decryptedMessage) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Decrypted Message"),
  //         content: SingleChildScrollView(
  //           child: decryptedMessage.startsWith("Image:")
  //               ? CachedNetworkImage(
  //             imageUrl: decryptedMessage.replaceFirst("Image: ", ""),
  //             placeholder: (context, url) => CircularProgressIndicator(),
  //             errorWidget: (context, url, error) => Image.asset(
  //               _getRandomFallbackImage(),
  //               fit: BoxFit.cover,
  //             ),
  //             fit: BoxFit.cover,
  //           )
  //               : Text(decryptedMessage.replaceFirst("Text: ", "")),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("Close"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  //
  // String _getRandomFallbackImage() {
  //   // List of fallback image asset paths
  //   final List<String> fallbackImages = [
  //     'assets/fallback1.jpg',
  //     'assets/fallback2.jpg',
  //     'assets/fallback3.jpg',
  //     'assets/fallback4.jpg',
  //     'assets/fallback5.png',
  //     // Add more image paths as needed
  //   ];
  //
  //   // Return a random image path
  //   final randomIndex = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % fallbackImages.length;
  //   return fallbackImages[randomIndex];
  // }


