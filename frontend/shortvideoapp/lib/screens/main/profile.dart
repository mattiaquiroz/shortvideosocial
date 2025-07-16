import 'package:flutter/material.dart';
import 'package:shortvideoapp/screens/settings/settings.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/user_model.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  final ApiService _apiService = ApiService();

  User? currentUser;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // First try to get user from local storage for immediate display
      final localUser = await _apiService.getCurrentUser();
      if (localUser != null) {
        setState(() {
          currentUser = localUser;
          isLoading = false;
        });
      }

      // Then refresh from API to get latest data
      final result = await _apiService.refreshCurrentUser();
      if (result['success']) {
        setState(() {
          currentUser = result['user'];
          isLoading = false;
        });
      } else {
        // If refresh fails but we have local data, just use that
        if (localUser == null) {
          setState(() {
            errorMessage = result['message'] ?? 'Failed to load user profile';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading profile: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_nameKey.currentContext != null) {
      final RenderBox nameBox =
          _nameKey.currentContext!.findRenderObject() as RenderBox;
      final namePosition = nameBox.localToGlobal(Offset.zero);

      final shouldShowName = namePosition.dy < 75;

      if (shouldShowName != showNameInAppBar) {
        setState(() {
          showNameInAppBar = shouldShowName;
        });
      }
    }
  }

  ImageProvider _getProfileImage() {
    String profileUrl = currentUser?.profilePictureUrl ?? "";

    if (profileUrl.isEmpty) {
      final defaultUrl =
          'http://10.0.2.2:8080/assets/users/default_picture.jpg';
      return NetworkImage(defaultUrl);
    }

    // Check if it's a proper HTTP/HTTPS URL
    if (profileUrl.startsWith('http://') || profileUrl.startsWith('https://')) {
      return NetworkImage(profileUrl);
    }

    // Check if it's a file path that should be converted to a server URL
    if (profileUrl.startsWith('file:///') || profileUrl.startsWith('assets/')) {
      // Convert file path to server URL
      String cleanPath = profileUrl
          .replaceFirst('file:///', '')
          .replaceFirst('file://', '');

      // Ensure the path starts with assets/
      if (!cleanPath.startsWith('assets/')) {
        cleanPath = 'assets/$cleanPath';
      }

      final serverUrl = 'http://10.0.2.2:8080/$cleanPath';
      return NetworkImage(serverUrl);
    }

    // For any other format, use default avatar
    final defaultUrl = 'http://10.0.2.2:8080/assets/users/default_picture.jpg';
    return NetworkImage(defaultUrl);
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
                currentUser?.username ?? "null",
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserProfile,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              backgroundColor: Colors.white,
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    SizedBox(height: 16),
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _getProfileImage(),
                    ),
                    SizedBox(height: 16),
                    Row(
                      key: _nameKey,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentUser?.fullName ??
                              currentUser?.username ??
                              "null",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
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
                      "${currentUser?.followersCount ?? 0} ${AppStrings.followersLabel} | ${currentUser?.followingCount ?? 0} ${AppStrings.followingLabel} | ${AppStrings.userTotalLikes} ${AppStrings.likesLabel}",
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
                          currentUser?.bio ?? "",
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
        (i) =>
            'https://picsum.photos/id/${i + 30}/300/500', // TODO: Change to actual videos
      );
    } else if (selectedTab == 1) {
      // Private videos - empty
      images = [];
    } else {
      // Liked videos
      images = List.generate(
        4,
        (i) =>
            'https://picsum.photos/id/${i + 100}/300/500', // TODO: Change to actual videos
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
