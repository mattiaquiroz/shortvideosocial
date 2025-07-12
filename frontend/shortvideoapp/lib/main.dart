import 'package:flutter/material.dart';
import 'package:shortvideoapp/create.dart';
import 'package:shortvideoapp/profile.dart';

void main() {
  runApp(const ShortVideoApp());
}

class ShortVideoApp extends StatelessWidget {
  const ShortVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShortVideoApp',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(188, 0, 0, 0),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pageIndex = 0;

  final pages = [const Home(), const Create(), const ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[pageIndex],
      bottomNavigationBar: navBar(context),
    );
  }

  Container navBar(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                pageIndex = 0;
              });
            },
            icon:
                pageIndex == 0
                    ? const Icon(
                      Icons.home_filled,
                      color: Colors.white,
                      size: 35,
                    )
                    : const Icon(
                      Icons.home_outlined,
                      color: Colors.white,
                      size: 35,
                    ),
          ),
          IconButton(
            enableFeedback: false,
            padding: const EdgeInsets.only(bottom: 0),
            onPressed: () {
              setState(() {
                pageIndex = 1;
              });
            },
            icon:
                pageIndex == 1
                    ? const Icon(
                      Icons.add_circle_outline,
                      color: Colors.red,
                      size: 60,
                    )
                    : const Icon(
                      Icons.add_circle_outline,
                      color: Colors.red,
                      size: 60,
                    ),
          ),
          IconButton(
            enableFeedback: false,
            onPressed: () {
              setState(() {
                pageIndex = 2;
              });
            },
            icon:
                pageIndex == 2
                    ? const Icon(Icons.person, color: Colors.white, size: 35)
                    : const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 35,
                    ),
          ),
        ],
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Video Content Here",
        style: TextStyle(
          color: Colors.black,
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}