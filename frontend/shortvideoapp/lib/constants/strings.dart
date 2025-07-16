import 'package:shortvideoapp/services/localization_service.dart';

class AppStrings {
  // Tab titles
  static String get following => LocalizationService.translate({
        AppLanguage.english: "Following",
        AppLanguage.italian: "Seguiti",
        AppLanguage.french: "Abonnés",
      });

  static String get forYou => LocalizationService.translate({
        AppLanguage.english: "For You",
        AppLanguage.italian: "Per te",
        AppLanguage.french: "Pour toi",
      });

  // Feed names
  static String get followingFeed => LocalizationService.translate({
        AppLanguage.english: "Following Feed",
        AppLanguage.italian: "Feed seguendo",
        AppLanguage.french: "Feed des abonnés",
      });

  static String get forYouFeed => LocalizationService.translate({
        AppLanguage.english: "For You Feed",
        AppLanguage.italian: "Feed per te",
        AppLanguage.french: "Feed pour toi",
      });

  // Action buttons
  static String get share => LocalizationService.translate({
        AppLanguage.english: "Share",
        AppLanguage.italian: "Condividi",
        AppLanguage.french: "Partager",
      });

  // Comments
  static String get addComment => LocalizationService.translate({
        AppLanguage.english: "Add a comment...",
        AppLanguage.italian: "Aggiungi un commento...",
        AppLanguage.french: "Ajouter un commentaire...",
      });

  static String get postComment => LocalizationService.translate({
        AppLanguage.english: "Post",
        AppLanguage.italian: "Pubblica",
        AppLanguage.french: "Publier",
      });

  static String get noCommentsYet => LocalizationService.translate({
        AppLanguage.english: "No comments yet",
        AppLanguage.italian: "Nessun commento ancora",
        AppLanguage.french: "Pas encore de commentaires",
      });

  static String get reply => LocalizationService.translate({
        AppLanguage.english: "Reply",
        AppLanguage.italian: "Rispondi",
        AppLanguage.french: "Répondre",
      });

  static String get comments => LocalizationService.translate({
        AppLanguage.english: "Comments",
        AppLanguage.italian: "Commenti",
        AppLanguage.french: "Commentaires",
      });

  // Video states
  static String get loadingVideo => LocalizationService.translate({
        AppLanguage.english: "Loading video...",
        AppLanguage.italian: "Caricamento video...",
        AppLanguage.french: "Chargement vidéo...",
      });

  static String get videoFailedToLoad => LocalizationService.translate({
        AppLanguage.english: "Video failed to load",
        AppLanguage.italian: "Video non caricato",
        AppLanguage.french: "Échec du chargement vidéo",
      });

  static String get retry => LocalizationService.translate({
        AppLanguage.english: "Retry",
        AppLanguage.italian: "Riprova",
        AppLanguage.french: "Réessayer",
      });

  // Instructions
  static String get swipeOrDoubleTap => LocalizationService.translate({
        AppLanguage.english: "Swipe up or double tap for next video",
        AppLanguage.italian:
            "Scorri verso l'alto o tocca due volte per il prossimo video",
        AppLanguage.french:
            "Balayez vers le haut ou double-cliquez pour la vidéo suivante",
      });

  static String get swipeOrDoubleTapNew => LocalizationService.translate({
        AppLanguage.english: "Swipe up or double tap for new video",
        AppLanguage.italian:
            "Scorri verso l'alto o tocca due volte per il nuovo video",
        AppLanguage.french:
            "Balayez vers le haut ou double-cliquez pour une nouvelle vidéo",
      });

  // App titles
  static String get homePage => LocalizationService.translate({
        AppLanguage.english: "HomePage",
        AppLanguage.italian: "Pagina principale",
        AppLanguage.french: "Page d'accueil",
      });

  static String get profile => LocalizationService.translate({
        AppLanguage.english: "Profile",
        AppLanguage.italian: "Profilo",
        AppLanguage.french: "Profil",
      });

  static String get settings => LocalizationService.translate({
        AppLanguage.english: "Settings",
        AppLanguage.italian: "Impostazioni",
        AppLanguage.french: "Paramètres",
      });

  // Profile specific (Temporary)
  static const String userTotalLikes = "0";

  // Profile UI
  static String get followersLabel => LocalizationService.translate({
        AppLanguage.english: "Followers",
        AppLanguage.italian: "Seguiti",
        AppLanguage.french: "Abonnés",
      });

  static String get followingLabel => LocalizationService.translate({
        AppLanguage.english: "Following",
        AppLanguage.italian: "Seguendo",
        AppLanguage.french: "Abonnements",
      });

  static String get likesLabel => LocalizationService.translate({
        AppLanguage.english: "Likes",
        AppLanguage.italian: "Mi piace",
        AppLanguage.french: "J'aime",
      });

  static String get noVideosYet => LocalizationService.translate({
        AppLanguage.english: "No videos here yet.",
        AppLanguage.italian: "Nessun video qui ancora.",
        AppLanguage.french: "Aucune vidéo ici pour le moment.",
      });

  static String get editProfile => LocalizationService.translate({
        AppLanguage.english: "Edit Profile",
        AppLanguage.italian: "Modifica profilo",
        AppLanguage.french: "Modifier le profil",
      });

  // Authentication
  static String get login => LocalizationService.translate({
        AppLanguage.english: "Login",
        AppLanguage.italian: "Accedi",
        AppLanguage.french: "Connexion",
      });

  static String get register => LocalizationService.translate({
        AppLanguage.english: "Sign Up",
        AppLanguage.italian: "Registrati",
        AppLanguage.french: "S'inscrire",
      });

  static String get logout => LocalizationService.translate({
        AppLanguage.english: "Logout",
        AppLanguage.italian: "Esci",
        AppLanguage.french: "Déconnexion",
      });

  static String get welcomeBack => LocalizationService.translate({
        AppLanguage.english: "Welcome Back!",
        AppLanguage.italian: "Bentornato!",
        AppLanguage.french: "Bon retour!",
      });

  static String get createAccount => LocalizationService.translate({
        AppLanguage.english: "Create Account",
        AppLanguage.italian: "Crea Account",
        AppLanguage.french: "Créer un compte",
      });

  static String get alreadyHaveAccount => LocalizationService.translate({
        AppLanguage.english: "Already have an account? ",
        AppLanguage.italian: "Hai già un account? ",
        AppLanguage.french: "Vous avez déjà un compte? ",
      });

  static String get dontHaveAccount => LocalizationService.translate({
        AppLanguage.english: "Don't have an account? ",
        AppLanguage.italian: "Non hai un account? ",
        AppLanguage.french: "Vous n'avez pas de compte? ",
      });

  // Settings
  static String get language => LocalizationService.translate({
        AppLanguage.english: "Language",
        AppLanguage.italian: "Lingua",
        AppLanguage.french: "Langue",
      });

  static String get languageCurrent => LocalizationService.translate({
        AppLanguage.english: "Current",
        AppLanguage.italian: "Attuale",
        AppLanguage.french: "Actuelle",
      });

  static String get account => LocalizationService.translate({
        AppLanguage.english: "Account",
        AppLanguage.italian: "Account",
        AppLanguage.french: "Compte",
      });

  static String get content => LocalizationService.translate({
        AppLanguage.english: "Content",
        AppLanguage.italian: "Contenuto",
        AppLanguage.french: "Contenu",
      });

  static String get access => LocalizationService.translate({
        AppLanguage.english: "Access",
        AppLanguage.italian: "Accesso",
        AppLanguage.french: "Accès",
      });

  // Settings Screen
  static String get accountSettings => LocalizationService.translate({
        AppLanguage.english: "Account Settings",
        AppLanguage.italian: "Impostazioni account",
        AppLanguage.french: "Paramètres du compte",
      });

  static String get privacySecurity => LocalizationService.translate({
        AppLanguage.english: "Privacy & Security",
        AppLanguage.italian: "Privacy e sicurezza",
        AppLanguage.french: "Confidentialité et sécurité",
      });

  static String get notifications => LocalizationService.translate({
        AppLanguage.english: "Notifications",
        AppLanguage.italian: "Notifiche",
        AppLanguage.french: "Notifications",
      });

  static String get contentPreferences => LocalizationService.translate({
        AppLanguage.english: "Content Preferences",
        AppLanguage.italian: "Preferenze contenuti",
        AppLanguage.french: "Préférences de contenu",
      });

  static String get screen => LocalizationService.translate({
        AppLanguage.english: "Screen",
        AppLanguage.italian: "Schermo",
        AppLanguage.french: "Écran",
      });

  static String get accessibility => LocalizationService.translate({
        AppLanguage.english: "Accessibility",
        AppLanguage.italian: "Accessibilità",
        AppLanguage.french: "Accessibilité",
      });

  static String get blockedUsers => LocalizationService.translate({
        AppLanguage.english: "Blocked Users",
        AppLanguage.italian: "Utenti bloccati",
        AppLanguage.french: "Utilisateurs bloqués",
      });

  static String get reportProblem => LocalizationService.translate({
        AppLanguage.english: "Report Problem",
        AppLanguage.italian: "Segnala problema",
        AppLanguage.french: "Signaler un problème",
      });

  // Account Settings
  static String get username => LocalizationService.translate({
        AppLanguage.english: "Username",
        AppLanguage.italian: "Nome utente",
        AppLanguage.french: "Nom d'utilisateur",
      });

  static String get email => LocalizationService.translate({
        AppLanguage.english: "Email",
        AppLanguage.italian: "Email",
        AppLanguage.french: "Email",
      });

  static String get phoneNumber => LocalizationService.translate({
        AppLanguage.english: "Phone Number",
        AppLanguage.italian: "Numero di telefono",
        AppLanguage.french: "Numéro de téléphone",
      });

  static String get profileInformation => LocalizationService.translate({
        AppLanguage.english: "Profile Information",
        AppLanguage.italian: "Informazioni profilo",
        AppLanguage.french: "Informations du profil",
      });

  static String get privacy => LocalizationService.translate({
        AppLanguage.english: "Privacy",
        AppLanguage.italian: "Privacy",
        AppLanguage.french: "Confidentialité",
      });

  static String get privateAccount => LocalizationService.translate({
        AppLanguage.english: "Private Account",
        AppLanguage.italian: "Account privato",
        AppLanguage.french: "Compte privé",
      });

  static String get privateAccountDesc => LocalizationService.translate({
        AppLanguage.english: "Only people you approve can see your videos",
        AppLanguage.italian:
            "Solo le persone che approvi possono vedere i tuoi video",
        AppLanguage.french:
            "Seules les personnes que vous approuvez peuvent voir vos vidéos",
      });

  static String get accountActions => LocalizationService.translate({
        AppLanguage.english: "Account Actions",
        AppLanguage.italian: "Azioni account",
        AppLanguage.french: "Actions du compte",
      });

  static String get deleteAccount => LocalizationService.translate({
        AppLanguage.english: "Delete Account",
        AppLanguage.italian: "Elimina account",
        AppLanguage.french: "Supprimer le compte",
      });

  static String get deleteAccountDesc => LocalizationService.translate({
        AppLanguage.english: "Permanently delete your account",
        AppLanguage.italian: "Elimina definitivamente il tuo account",
        AppLanguage.french: "Supprimer définitivement votre compte",
      });

  static String get deleteAccountConfirm => LocalizationService.translate({
        AppLanguage.english:
            "Are you sure you want to delete your account? This action cannot be undone.",
        AppLanguage.italian:
            "Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata.",
        AppLanguage.french:
            "Êtes-vous sûr de vouloir supprimer votre compte? Cette action ne peut pas être annulée.",
      });

  static String get accountDeleted => LocalizationService.translate({
        AppLanguage.english: "Account Deleted",
        AppLanguage.italian: "Account eliminato",
        AppLanguage.french: "Compte supprimé",
      });

  static String get accountDeletedDesc => LocalizationService.translate({
        AppLanguage.english: "Your account has been deleted successfully.",
        AppLanguage.italian: "Il tuo account è stato eliminato con successo.",
        AppLanguage.french: "Votre compte a été supprimé avec succès.",
      });

  // Screen Settings
  static String get theme => LocalizationService.translate({
        AppLanguage.english: "Theme",
        AppLanguage.italian: "Tema",
        AppLanguage.french: "Thème",
      });

  static String get themeMode => LocalizationService.translate({
        AppLanguage.english: "Theme Mode",
        AppLanguage.italian: "Modalità tema",
        AppLanguage.french: "Mode thème",
      });

  static String get fontSize => LocalizationService.translate({
        AppLanguage.english: "Font Size",
        AppLanguage.italian: "Dimensione carattere",
        AppLanguage.french: "Taille de police",
      });

  static String get fontSizeDesc => LocalizationService.translate({
        AppLanguage.english: "Adjust text size",
        AppLanguage.italian: "Regola dimensione testo",
        AppLanguage.french: "Ajuster la taille du texte",
      });

  static String get selectTheme => LocalizationService.translate({
        AppLanguage.english: "Select Theme",
        AppLanguage.italian: "Seleziona tema",
        AppLanguage.french: "Sélectionner le thème",
      });

  static String get system => LocalizationService.translate({
        AppLanguage.english: "System",
        AppLanguage.italian: "Sistema",
        AppLanguage.french: "Système",
      });

  static String get systemDesc => LocalizationService.translate({
        AppLanguage.english: "Follow system settings",
        AppLanguage.italian: "Segui impostazioni sistema",
        AppLanguage.french: "Suivre les paramètres système",
      });

  static String get light => LocalizationService.translate({
        AppLanguage.english: "Light",
        AppLanguage.italian: "Chiaro",
        AppLanguage.french: "Clair",
      });

  static String get lightDesc => LocalizationService.translate({
        AppLanguage.english: "Light theme",
        AppLanguage.italian: "Tema chiaro",
        AppLanguage.french: "Thème clair",
      });

  static String get dark => LocalizationService.translate({
        AppLanguage.english: "Dark",
        AppLanguage.italian: "Scuro",
        AppLanguage.french: "Sombre",
      });

  static String get darkDesc => LocalizationService.translate({
        AppLanguage.english: "Dark theme",
        AppLanguage.italian: "Tema scuro",
        AppLanguage.french: "Thème sombre",
      });

  // Notification Settings
  static String get general => LocalizationService.translate({
        AppLanguage.english: "General",
        AppLanguage.italian: "Generale",
        AppLanguage.french: "Général",
      });

  static String get pushNotifications => LocalizationService.translate({
        AppLanguage.english: "Push Notifications",
        AppLanguage.italian: "Notifiche push",
        AppLanguage.french: "Notifications push",
      });

  static String get pushNotificationsDesc => LocalizationService.translate({
        AppLanguage.english: "Receive notifications on your device",
        AppLanguage.italian: "Ricevi notifiche sul tuo dispositivo",
        AppLanguage.french: "Recevoir des notifications sur votre appareil",
      });

  static String get emailNotifications => LocalizationService.translate({
        AppLanguage.english: "Email Notifications",
        AppLanguage.italian: "Notifiche email",
        AppLanguage.french: "Notifications par email",
      });

  static String get emailNotificationsDesc => LocalizationService.translate({
        AppLanguage.english: "Receive notifications via email",
        AppLanguage.italian: "Ricevi notifiche via email",
        AppLanguage.french: "Recevoir des notifications par email",
      });

  static String get activity => LocalizationService.translate({
        AppLanguage.english: "Activity",
        AppLanguage.italian: "Attività",
        AppLanguage.french: "Activité",
      });

  static String get likesNotification => LocalizationService.translate({
        AppLanguage.english: "Likes",
        AppLanguage.italian: "Mi piace",
        AppLanguage.french: "J'aime",
      });

  static String get likesNotificationDesc => LocalizationService.translate({
        AppLanguage.english: "When someone likes your video",
        AppLanguage.italian: "Quando qualcuno mette mi piace al tuo video",
        AppLanguage.french: "Quand quelqu'un aime votre vidéo",
      });

  static String get commentsNotification => LocalizationService.translate({
        AppLanguage.english: "Comments",
        AppLanguage.italian: "Commenti",
        AppLanguage.french: "Commentaires",
      });

  static String get commentsNotificationDesc => LocalizationService.translate({
        AppLanguage.english: "When someone comments on your video",
        AppLanguage.italian: "Quando qualcuno commenta il tuo video",
        AppLanguage.french: "Quand quelqu'un commente votre vidéo",
      });

  static String get newFollowers => LocalizationService.translate({
        AppLanguage.english: "New Followers",
        AppLanguage.italian: "Nuovi seguaci",
        AppLanguage.french: "Nouveaux abonnés",
      });

  static String get newFollowersDesc => LocalizationService.translate({
        AppLanguage.english: "When someone follows you",
        AppLanguage.italian: "Quando qualcuno ti segue",
        AppLanguage.french: "Quand quelqu'un vous suit",
      });

  static String get mentions => LocalizationService.translate({
        AppLanguage.english: "Mentions",
        AppLanguage.italian: "Menzioni",
        AppLanguage.french: "Mentions",
      });

  static String get mentionsDesc => LocalizationService.translate({
        AppLanguage.english: "When someone mentions you",
        AppLanguage.italian: "Quando qualcuno ti menziona",
        AppLanguage.french: "Quand quelqu'un vous mentionne",
      });

  static String get directMessages => LocalizationService.translate({
        AppLanguage.english: "Direct Messages",
        AppLanguage.italian: "Messaggi diretti",
        AppLanguage.french: "Messages directs",
      });

  static String get directMessagesDesc => LocalizationService.translate({
        AppLanguage.english: "When you receive a direct message",
        AppLanguage.italian: "Quando ricevi un messaggio diretto",
        AppLanguage.french: "Quand vous recevez un message direct",
      });

  // Common
  static String get cancel => LocalizationService.translate({
        AppLanguage.english: "Cancel",
        AppLanguage.italian: "Annulla",
        AppLanguage.french: "Annuler",
      });

  static String get confirm => LocalizationService.translate({
        AppLanguage.english: "Confirm",
        AppLanguage.italian: "Conferma",
        AppLanguage.french: "Confirmer",
      });

  static String get save => LocalizationService.translate({
        AppLanguage.english: "Save",
        AppLanguage.italian: "Salva",
        AppLanguage.french: "Enregistrer",
      });

  static String get edit => LocalizationService.translate({
        AppLanguage.english: "Edit",
        AppLanguage.italian: "Modifica",
        AppLanguage.french: "Modifier",
      });

  static String get ok => LocalizationService.translate({
        AppLanguage.english: "OK",
        AppLanguage.italian: "OK",
        AppLanguage.french: "OK",
      });

  static String get delete => LocalizationService.translate({
        AppLanguage.english: "Delete",
        AppLanguage.italian: "Elimina",
        AppLanguage.french: "Supprimer",
      });

  static String get loading => LocalizationService.translate({
        AppLanguage.english: "Loading...",
        AppLanguage.italian: "Caricamento...",
        AppLanguage.french: "Chargement...",
      });

  // Debug messages
  static String get menuPressed => LocalizationService.translate({
        AppLanguage.english: "Menu pressed",
        AppLanguage.italian: "Menu premuto",
        AppLanguage.french: "Menu pressé",
      });

  static String get settingsPressed => LocalizationService.translate({
        AppLanguage.english: "Settings pressed",
        AppLanguage.italian: "Impostazioni premute",
        AppLanguage.french: "Paramètres pressés",
      });

  static String get notificationsPressed => LocalizationService.translate({
        AppLanguage.english: "Notifications pressed",
        AppLanguage.italian: "Notifiche premute",
        AppLanguage.french: "Notifications pressées",
      });

  static String get noVideosAvailable => LocalizationService.translate({
        AppLanguage.english: "No videos available",
        AppLanguage.italian: "Nessun video disponibile",
        AppLanguage.french: "Aucune vidéo disponible",
      });

  static String get failedToLoadVideos => LocalizationService.translate({
        AppLanguage.english: "Failed to load videos",
        AppLanguage.italian: "Impossibile caricare i video",
        AppLanguage.french: "Échec du chargement des vidéos",
      });
}
