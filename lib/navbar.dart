import 'package:counter_flutter/signup.dart';
import 'package:flutter/material.dart';
import 'profile.dart';
import 'signup.dart';
import 'markings.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Shayaan Kashif',style: TextStyle(fontWeight: FontWeight.w800),),
            accountEmail: const Text("Shayaankashif20@gmail.com",style: TextStyle(fontWeight: FontWeight.w700)),
            currentAccountPicture: CircleAvatar(
              child: ClipOval(child: Image.asset(
                  'images/shayaan.PNG',
                width:100,
                height: 80,
                fit: BoxFit.cover,
              ),
              ),
            ),
            decoration:  const BoxDecoration(
              color: Colors.lightBlue,
              image: DecorationImage(image: AssetImage('images/mount2.jpg'), fit: BoxFit.cover,)
            ),
          ),
          ListTile(
            leading: Icon(Icons.file_upload),
            title: Text("Upload Shot"),
            onTap: () => {print("upload tapped.")},
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text("Profile"),
            onTap: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => profile_page()))
            },
          ),

          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () => {print("Settings tapped.")},
          ),

          ListTile(
            leading: Icon(Icons.message),
            title: Text("Messages"),
            onTap: () => {print("Messages tapped.")},
          ),

          ListTile(
            leading: Icon(Icons.add_chart_outlined),
            title: Text("Markings"),
            onTap: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => markings()))
            },
          ),

          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text("Sign Out"),
            onTap: () => {
              Navigator.push(context, MaterialPageRoute(builder: (context) => signUp()))
            },
          ),



        ],
      )
    );
  }
}
