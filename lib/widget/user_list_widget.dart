import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryp_comm/models/profile.dart';
import 'package:cryp_comm/service/database_service.dart';

import '../constant/consts.dart';

class UserListWidget extends StatelessWidget {
  final FirebaseFirestore firestore;
  final DatabaseService databaseService;

  UserListWidget({
    required this.firestore,
    required this.databaseService,
  });

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
            div: doc['div'] ?? "No Division Selected",
            unit: doc['unit'] ?? "No Unit Selected",
            appointment: doc['appointment'] ?? "No Appointment Selected",
            disabled: doc['disabled'] ?? false,
            pfpURL: doc['pfpURL'] ?? PLACEHOLDER_PFP,
          );
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            Profile user = users[index];
            return Card(
              elevation: 6,
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: user.disabled ? Colors.red : Colors.green,
                          radius: 30.0,
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 28.0,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user.pfpURL!,
                                placeholder: (context, url) => Image.asset(
                                  'assets/loading.gif',
                                  fit: BoxFit.cover,
                                  width: 56.0,
                                  height: 56.0,
                                ),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                                fit: BoxFit.cover,
                                width: 56.0,
                                height: 56.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email.split('@')[0],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.role,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        if (user.role == "User")
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Confirm Disable Status'),
                                    content: Text(
                                        "Are you sure you want to change this user's disable status?"),
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
                          ),
                      ],
                    ),
                    Divider(height: 30, color: Colors.grey[300]),
                    Text(
                      "Division: ${user.div}",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Unit: ${user.unit}",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Appointment: ${user.appointment}",
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


}
