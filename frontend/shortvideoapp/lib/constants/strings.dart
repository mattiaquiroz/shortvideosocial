class AppStrings {
  static const String language = "it";

  // Tab titles
  static const String following = language == "en" ? "Following" : "Seguiti";
  static const String forYou = language == "en" ? "For You" : "Per te";

  // Feed names
  static const String followingFeed = language == "en"
      ? "Following Feed"
      : "Feed seguendo";
  static const String forYouFeed = language == "en"
      ? "For You Feed"
      : "Feed per te";

  // Action buttons
  static const String share = language == "en" ? "Share" : "Condividi";
  static const String likes = "12.5K";
  static const String comments = "1.2K";

  // Video states
  static const String loadingVideo = language == "en"
      ? "Loading video..."
      : "Caricamento video...";
  static const String videoFailedToLoad = language == "en"
      ? "Video failed to load"
      : "Video non caricato";
  static const String retry = language == "en" ? "Retry" : "Riprova";

  // Instructions
  static const String swipeOrDoubleTap = language == "en"
      ? "Swipe up or double tap for next video"
      : "Scorri verso l'alto o tocca due volte per il prossimo video";
  static const String swipeOrDoubleTapNew = language == "en"
      ? "Swipe up or double tap for new video"
      : "Scorri verso l'alto o tocca due volte per il nuovo video";

  // App titles
  static const String homePage = language == "en"
      ? "HomePage"
      : "Pagina principale";
  static const String profile = language == "en" ? "Profile" : "Profilo";
  static const String settings = language == "en" ? "Settings" : "Impostazioni";

  // Profile specific (Temporary)
  static const String userName = "John Doe";
  static const String userFollowers = "0";
  static const String userFollowing = "0";
  static const String userTotalLikes = "0";
  static const String userBio =
      "Software Programmer\nLoves tech, travel, and coding.";
  static const String userAvatarUrl = "https://i.pravatar.cc/150?img=12";

  // Profile UI
  static const String followersLabel = language == "en"
      ? "Followers"
      : "Seguiti";
  static const String followingLabel = language == "en"
      ? "Following"
      : "Seguendo";
  static const String likesLabel = language == "en" ? "Likes" : "Mi piace";
  static const String noVideosYet = language == "en"
      ? "No videos here yet."
      : "Nessun video qui ancora.";
  static const String editProfile = language == "en"
      ? "Edit Profile"
      : "Modifica profilo";

  // Debug messages
  static const String menuPressed = language == "en"
      ? "Menu pressed"
      : "Menu premuto";
  static const String settingsPressed = language == "en"
      ? "Settings pressed"
      : "Impostazioni premute";
  static const String notificationsPressed = language == "en"
      ? "Notifications pressed"
      : "Notifiche premute";
}
