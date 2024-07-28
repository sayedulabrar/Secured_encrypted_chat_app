import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../models/sortedprofile.dart';
import '../service/notification_service.dart';
import '../widget/navigation_drawer.dart';
import '/service/auth_service.dart';
import '/utils/chat_page.dart';
import '../models/profile.dart';
import '../widget/chat_tile.dart';
import '../service/database_service.dart';
import '../service/navigation_service.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _showOption1 = true;
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late DatabaseService _databaseService;
  late PushNotificationService _pushNotificationService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  late DateTime _selectedDate;
  final _dateController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _databaseService = _getIt.get<DatabaseService>();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();

    _pushNotificationService = _getIt.get<PushNotificationService>();
    setupFCM();
    _searchController.addListener(_updateSearchQuery);
  }

  void _updateSearchQuery() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void setupFCM() async {
    await _pushNotificationService.initialize();
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2050),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = "${_selectedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  void _showDialog(Profile userProfile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Date and Key"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                      labelText: 'Chat Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                      labelText: 'Encryption Key',
                      hintText:'must be 16 char long',
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
    // Implement your logic to navigate to the chat page based on the date and key
    String date = _dateController.text;
    String key = _keyController.text;

    _keyController.clear();
    // Example navigation to ChatPage
    _navigationService.push(MaterialPageRoute(builder: (context) {
      return ChatPage(chatUser: userProfile,date: date, chatkey: key);
    }));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),

      ),
      drawer: NavigationDrawerWidget(initialSelectedIndex: 0),
      body: _buildUI(),
    );
  }

  Widget _buildOptionSelector() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _optionButton(
            text: '     Users     ',
            isSelected: _showOption1,
            onPressed: () {
              setState(() {
                _showOption1 = true;
              });
            },
          ),
          _optionButton(
            text: 'Recent Chats',
            isSelected: !_showOption1,
            onPressed: () {
              setState(() {
                _showOption1 = false;
              });
            },
          ),
        ],
      ),
    );
  }


  Widget _optionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.black, backgroundColor: Colors.transparent, // Transparent background
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey, // Border color
          width: 2.0, // Border width
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(text),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align title to the start
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            _activeUsersList(),
            Divider(thickness: 10,),
            _buildOptionSelector(),
            // Horizontal list of active users
            Expanded( child: _showOption1 ? _usersList() : _recentchatsList(),), // Vertical list of chats taking remaining space
          ],
        ),
      ),
    );
  }


  Widget _usersList() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: _databaseService.getUserProfiles(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text("Unable to load data."),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                final users = snapshot.data!.docs
                    .map((doc) => doc.data())
                    .where((profile) {
                  final emailPrefix = profile.email.split('@')[0].toLowerCase();
                  return emailPrefix.contains(_searchQuery);
                })
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    Profile userProfile = users[index];
                    return Column(
                      children: <Widget>[
                        ChatTile(
                          userProfile: userProfile,
                          onTap: () async {
                            final chatExists = await _databaseService.checkChatExists(
                                _authService.user!.uid, userProfile.userid);
                            if (!chatExists) {
                              await _databaseService.createNewChat(
                                  _authService.user!.uid, userProfile.userid);
                            }
                            _showDialog(userProfile);
                          },
                        ),
                        Divider(), // Divider after each ChatTile
                      ],
                    );
                  },
                );
              }

              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recentchatsList() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<SortedProfilesData>(
            stream: _databaseService.getSortedUserProfiles(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return const Center(
                    child: Text("No chats found."),
                  );
                }

                final filteredUsers = users.where((profile) {
                  final emailPrefix = profile.email.split('@')[0].toLowerCase();
                  return emailPrefix.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    Profile userProfile = filteredUsers[index];
                    return Column(
                      children: <Widget>[
                        ChatTile(
                          userProfile: userProfile,
                          onTap: () async {
                            final chatExists = await _databaseService.checkChatExists(
                                _authService.user!.uid, userProfile.userid);
                            if (!chatExists) {
                              await _databaseService.createNewChat(
                                  _authService.user!.uid, userProfile.userid);
                            }
                            _showDialog(userProfile);
                          },
                        ),
                        Divider(), // Divider after each ChatTile
                      ],
                    );
                  },
                );
              }

              return const Center(
                child: Text("No data available."),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _activeUsersList() {
    return StreamBuilder(
      stream: _databaseService.getActiveUserProfilesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Unable to load active users."),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final activeUsers = snapshot.data!; // Assuming data is a list of Profile objects

          return SizedBox(
            height: 100.0, // Adjust the height as needed

            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: activeUsers.length,
              itemBuilder: (context, index) {
                Profile userProfile = activeUsers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      final chatExists = await _databaseService.checkChatExists(
                          _authService.user!.uid, userProfile.userid);
                      if (!chatExists) {
                        await _databaseService.createNewChat(
                            _authService.user!.uid, userProfile.userid);
                      }
                      _showDialog(userProfile);
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.greenAccent,
                      radius: 32.0,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: userProfile.pfpURL!,
                          placeholder: (context, url) => Image.asset(
                            'assets/loading.gif',
                            fit: BoxFit.cover,
                            width: 60.0,
                            height: 60.0,
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.error),
                          fit: BoxFit.cover,
                          width: 60.0,
                          height: 60.0,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

}
