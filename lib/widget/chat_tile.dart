import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/profile.dart';

class ChatTile extends StatelessWidget {
  final Profile userProfile;
  final Function onTap;

  const ChatTile({Key? key, required this.userProfile, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onTap();
      },
      dense: false,
      title: Text(userProfile.email.split('@')[0]),
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 20.0,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: userProfile.pfpURL!,
            placeholder: (context, url) => Image.asset(
              'assets/loading.gif',
              fit: BoxFit.cover,
              width: 40.0,
              height: 40.0,
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
            fit: BoxFit.cover,
            width: 40.0,
            height: 40.0,
          ),
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: userProfile.disabled?Colors.redAccent:Colors.blue, // Example color, you can change this
        ),
        child: Text(
          userProfile.role,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}