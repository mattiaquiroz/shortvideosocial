import 'package:flutter/material.dart';
import 'package:shortvideoapp/settings.dart';
import 'constants/strings.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.profile,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProfilePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedTab = 0;
  bool showNameInAppBar = false;
  ScrollController _scrollController = ScrollController();
  GlobalKey _nameKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_nameKey.currentContext != null) {
      final RenderBox nameBox =
          _nameKey.currentContext!.findRenderObject() as RenderBox;
      final namePosition = nameBox.localToGlobal(Offset.zero);

      // Check if the name has scrolled past the AppBar (approximately 100 pixels from top)
      final shouldShowName = namePosition.dy < 75;

      if (shouldShowName != showNameInAppBar) {
        setState(() {
          showNameInAppBar = shouldShowName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.profile,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        flexibleSpace: SafeArea(
          child: Center(
            child: AnimatedOpacity(
              opacity: showNameInAppBar ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Text(
                AppStrings.userName,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              // Notifications functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SettingsPage(),
                  transitionDuration: Duration(milliseconds: 300),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(
                          begin: begin,
                          end: end,
                        ).chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SizedBox(height: 16),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(AppStrings.userAvatarUrl),
            ),
            SizedBox(height: 16),
            Row(
              key: _nameKey,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.userName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.edit, color: Colors.white),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Colors.black,
                    ),
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "${AppStrings.userFollowers} ${AppStrings.followersLabel} | ${AppStrings.userFollowing} ${AppStrings.followingLabel} | ${AppStrings.userTotalLikes} ${AppStrings.likesLabel}",
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Card(
              color: const Color.fromARGB(255, 248, 248, 248),
              margin: EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppStrings.userBio,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Tab selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabIcon(Icons.grid_on, 0),
                SizedBox(width: 50),
                _buildTabIcon(Icons.lock, 1),
                SizedBox(width: 50),
                _buildTabIcon(Icons.favorite, 2),
              ],
            ),

            SizedBox(height: 16),

            // Dynamic grid content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: _buildGridContent(),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Tab Icon builder
  Widget _buildTabIcon(IconData icon, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Column(
        children: [
          Icon(icon, size: 28, color: isSelected ? Colors.blue : Colors.grey),
          SizedBox(height: 4),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Grid content per tab
  Widget _buildGridContent() {
    List<String> images;

    if (selectedTab == 0) {
      // Public videos
      images = List.generate(
        26,
        (i) => 'https://picsum.photos/id/${i + 30}/300/500',
      );
    } else if (selectedTab == 1) {
      // Private videos - empty
      images = [];
    } else {
      // Liked videos
      images = List.generate(
        4,
        (i) => 'https://picsum.photos/id/${i + 100}/300/500',
      );
    }

    if (images.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            AppStrings.noVideosYet,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 14,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(images[index]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
