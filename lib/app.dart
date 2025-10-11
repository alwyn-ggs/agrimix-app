import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'theme/theme.dart';
import 'providers/settings_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'ui/common/app_wrapper.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/fermentation_provider.dart';
import 'providers/community_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/moderation_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/admin_fermentation_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/storage_service.dart';
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_message_handler.dart';
import 'services/navigation_service.dart';
import 'services/fcm_push_service.dart';
import 'services/audit_service.dart';
import 'repositories/users_repo.dart';
import 'repositories/recipes_repo.dart';
import 'repositories/ingredients_repo.dart';
import 'repositories/fermentation_repo.dart';
import 'repositories/posts_repo.dart';
import 'repositories/comments_repo.dart';
import 'repositories/violations_repo.dart';
import 'repositories/announcements_repo.dart';
import 'repositories/audit_repo.dart';

class AgriMixAppRoot extends StatelessWidget {
  const AgriMixAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Base services
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final storageService = StorageService();
    final messagingService = MessagingService();
    final notificationService = NotificationService(messagingService);
    final fcmMessageHandler = FCMMessageHandler(notificationService);
    final fcmPushService = FCMPushService();
    final auditService = AuditService(AuditRepo(firestoreService));

    // Repositories
    final usersRepo = UsersRepo(authService, firestoreService);
    final recipesRepo = RecipesRepo(firestoreService, storageService);
    final ingredientsRepo = IngredientsRepo(firestoreService);
    final fermentationRepo = FermentationRepo(firestoreService, storageService);
    final postsRepo = PostsRepo(firestoreService, storageService);
    final commentsRepo = CommentsRepo(firestoreService);
    final violationsRepo = ViolationsRepo(firestoreService);
    final announcementsRepo = AnnouncementsRepo(firestoreService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService, usersRepo, messagingService, notificationService)),
        ChangeNotifierProvider(create: (_) => UserProvider(usersRepo)),
        ChangeNotifierProvider(create: (_) => RecipeProvider(recipesRepo, ingredientsRepo)),
        ChangeNotifierProvider(create: (_) => FermentationProvider(fermentationRepo, notificationService)),
        ChangeNotifierProvider(create: (_) => CommunityProvider(postsRepo, commentsRepo, violationsRepo)),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider(announcementsRepo, fcmPushService, notificationService)),
        ChangeNotifierProvider(create: (_) => ModerationProvider(violationsRepo, postsRepo, commentsRepo, notificationService, recipesRepo)),
        ChangeNotifierProvider(create: (_) => AdminProvider(usersRepo, postsRepo, recipesRepo, authService)),
        ChangeNotifierProvider(create: (_) => AdminFermentationProvider()),
        // Expose repos needed directly by pages (detail/edit/flows)
        Provider(create: (_) => storageService),
        Provider(create: (_) => usersRepo),
        Provider(create: (_) => recipesRepo),
        Provider(create: (_) => ingredientsRepo),
        Provider(create: (_) => fermentationRepo),
        Provider(create: (_) => postsRepo),
        Provider(create: (_) => commentsRepo),
        Provider(create: (_) => violationsRepo),
        Provider(create: (_) => messagingService),
        Provider(create: (_) => notificationService),
        Provider(create: (_) => fcmMessageHandler),
        Provider(create: (_) => fcmPushService),
        Provider(create: (_) => auditService),
      ],
      child: Builder(
        builder: (context) {
          final theme = buildTheme();
          final darkTheme = buildDarkTheme();
          final settings = context.watch<SettingsProvider>();
          return MaterialApp(
            title: 'AgriMix App',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: theme,
            darkTheme: darkTheme,
            locale: settings.locale,
            supportedLocales: const [Locale('en'), Locale('tl')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.delegate,
            ],
            navigatorKey: NavigationService.navigatorKey,
            home: const AppWrapper(), // Use AppWrapper for initial navigation
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}