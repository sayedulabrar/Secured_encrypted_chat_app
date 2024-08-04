import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_comm/models/profile.dart';
import 'package:cryp_comm/service/database_service.dart';

class UserListWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DatabaseService databaseService;

  UserListWidget({
    required this.firestore,
    required this.databaseService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No users found.'));
        }

        List<Profile> users = snapshot.data!.docs.map((doc) {
          return Profile(
            userid: doc['userid'],
            email: doc['email'],
            password: doc['password'],
            role: doc['role'],
            disabled: doc['disabled'] ?? false,
          );
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            Profile user = users[index];
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                trailing: user.role == "User"
                    ? IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirm User role'),
                          content: Text("Are you sure you want to change this user's role?"),
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Confirm'),
                              onPressed: () {
                                databaseService.toggleUserStatus(user.email);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
                    : null,
                title: Text(user.email.split('@')[0]),
                subtitle: Text(user.role),
                leading: CircleAvatar(
                  backgroundColor: user.disabled ? Colors.red : Colors.green,
                  child: Icon(
                    user.disabled ? Icons.block : Icons.check,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
