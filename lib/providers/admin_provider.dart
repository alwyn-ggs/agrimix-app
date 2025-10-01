import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/users_repo.dart';
import '../repositories/posts_repo.dart';
import '../repositories/recipes_repo.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';

class AdminProvider extends ChangeNotifier {
  final UsersRepo usersRepo;
  final PostsRepo posts;
  final RecipesRepo recipes;
  final AuthService authService;
  
  List<AppUser> _users = [];
  List<Recipe> _recipes = [];
  bool _loading = false;
  String? _error;
  StreamSubscription<List<AppUser>>? _usersSubscription;
  StreamSubscription<List<Recipe>>? _recipesSubscription;

  AdminProvider(this.usersRepo, this.posts, this.recipes, this.authService) {
    AppLogger.debug('AdminProvider: Constructor called');
    AppLogger.debug('AdminProvider: UsersRepo: OK');
    AppLogger.debug('AdminProvider: Starting to listen to users...');
    _startListeningToUsers();
    _startListeningToRecipes();
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _recipesSubscription?.cancel();
    super.dispose();
  }

  List<AppUser> get users => _users;
  bool get loading => _loading;
  String? get error => _error;
  
  List<AppUser> get pendingUsers => _users.where((user) => 
    user.role == 'farmer' && !user.approved).toList();
  
  int get pendingUsersCount => pendingUsers.length;

  // Recipe management getters
  List<Recipe> get allRecipes => _recipes;
  List<Recipe> get standardRecipes => _recipes.where((recipe) => recipe.isStandard).toList();
  List<Recipe> get nonStandardRecipes => _recipes.where((recipe) => !recipe.isStandard).toList();
  List<Recipe> get publicRecipes => _recipes.where((recipe) => recipe.visibility == RecipeVisibility.public).toList();
  List<Recipe> get flaggedRecipes => _recipes.where((recipe) => 
    recipe.totalRatings > 0 && recipe.avgRating < 2.0).toList();

  // Real-time streams specifically for pending users
  final Set<String> _approvingUids = <String>{};
  bool isApproving(String uid) => _approvingUids.contains(uid);

  Stream<List<AppUser>> get pendingUsersStream => usersRepo
      .watchPendingUsers()
      .map((users) => users.where((u) => !_approvingUids.contains(u.uid)).toList());
  Stream<int> get pendingUsersCountStream => usersRepo.watchPendingUsersCount();

  void _startListeningToUsers() {
    _loading = true;
    _error = null;
    notifyListeners();

    AppLogger.debug('AdminProvider: Starting to listen to users in real-time');
    AppLogger.debug('AdminProvider: Current users count before stream: ${_users.length}');
    
    // Cancel existing subscription if any
    _usersSubscription?.cancel();
    
    _usersSubscription = usersRepo.watchAllUsers().listen(
      (users) {
        AppLogger.debug('AdminProvider: Received ${users.length} users from stream');
        AppLogger.debug('AdminProvider: Raw user data:');
        for (var user in users) {
          AppLogger.debug('  - ${user.name} (${user.email}) - Role: ${user.role}, Approved: ${user.approved}');
        }
        
        // Check for new pending users
        final newPendingUsers = users.where((user) => 
          user.role == 'farmer' && !user.approved).toList();
        
        AppLogger.debug('AdminProvider: Filtered pending users: ${newPendingUsers.length}');
        for (var user in newPendingUsers) {
          AppLogger.debug('  Pending: ${user.name} (${user.email}) - Role: ${user.role}, Approved: ${user.approved}');
        }
        
        _users = users;
        _loading = false;
        _error = null;
        notifyListeners();
        
        AppLogger.debug('AdminProvider: Updated _users list with ${_users.length} users');
        AppLogger.debug('AdminProvider: Pending users count: ${pendingUsers.length}');
        
        // Force UI update
        Future.microtask(() {
          notifyListeners();
        });
      },
      onError: (error) {
        AppLogger.debug('AdminProvider: Error in users stream: $error');
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
      onDone: () {
        AppLogger.debug('AdminProvider: Users stream completed');
      },
    );
  }

  void _startListeningToRecipes() {
    AppLogger.debug('AdminProvider: Starting to listen to recipes...');
    
    _recipesSubscription = recipes.watchAll().listen(
      (recipeList) {
        AppLogger.debug('AdminProvider: Received ${recipeList.length} recipes from stream');
        _recipes = recipeList;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        AppLogger.debug('AdminProvider: Error in recipes stream: $error');
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  // Public method to refresh recipes
  void refreshRecipes() {
    AppLogger.debug('AdminProvider: Refreshing recipes...');
    _recipesSubscription?.cancel();
    _loading = true;
    _error = null;
    notifyListeners();
    _startListeningToRecipes();
  }

  // Recipe moderation methods
  Future<void> approveRecipe(String recipeId, {String? reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      // Verify recipe exists
      _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      // Update recipe if needed (recipes are approved by default in current system)
      // This could be extended to add an 'approved' field to recipes
      AppLogger.debug('AdminProvider: Recipe $recipeId approved');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error approving recipe: $e');
      _error = 'Failed to approve recipe: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectRecipe(String recipeId, {required String reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      // Verify recipe exists
      _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      // Delete the rejected recipe
      await recipes.deleteRecipe(recipeId);
      AppLogger.debug('AdminProvider: Recipe $recipeId rejected and deleted');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error rejecting recipe: $e');
      _error = 'Failed to reject recipe: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsStandard(String recipeId, {String? reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      final updatedRecipe = recipe.copyWith(
        isStandard: true,
        updatedAt: DateTime.now(),
      );

      await recipes.updateRecipe(updatedRecipe);
      
      // Admin action completed

      AppLogger.debug('AdminProvider: Recipe $recipeId marked as standard');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error marking recipe as standard: $e');
      _error = 'Failed to mark recipe as standard: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unmarkAsStandard(String recipeId, {String? reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      final updatedRecipe = recipe.copyWith(
        isStandard: false,
        updatedAt: DateTime.now(),
      );

      await recipes.updateRecipe(updatedRecipe);
      
      // Admin action completed

      AppLogger.debug('AdminProvider: Recipe $recipeId unmarked as standard');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error unmarking recipe as standard: $e');
      _error = 'Failed to unmark recipe as standard: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId, {required String reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      // Verify recipe exists
      _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      await recipes.deleteRecipeDeep(recipeId);
      AppLogger.debug('AdminProvider: Recipe $recipeId deleted');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error deleting recipe: $e');
      _error = 'Failed to delete recipe: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeRecipeRating(String recipeId, String userId, {String? reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      // We need to access the FirestoreService through the recipes repo
      // For now, we'll use a simpler approach by updating the rating to 0
      // In a real implementation, you'd want to add a deleteRating method to RecipesRepo
      await recipes.rateRecipe(recipeId, userId, 0.0);
      
      // Admin action completed

      AppLogger.debug('AdminProvider: Rating removed for recipe $recipeId');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error removing rating: $e');
      _error = 'Failed to remove rating: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approveUser(String uid) async {
    try {
      AppLogger.debug('AdminProvider: Approving user with UID: $uid');
      _approvingUids.add(uid);
      notifyListeners();
      final user = _users.firstWhere((u) => u.uid == uid);
      AppLogger.debug('AdminProvider: Found user: ${user.name} (${user.email})');
      
      final updatedUser = user.copyWith(approved: true);
      AppLogger.debug('AdminProvider: Updating user approval status to: ${updatedUser.approved}');
      
      // Force approved to boolean true via dedicated setter to avoid type merge issues
      await usersRepo.setApproved(user.uid, true);
      AppLogger.debug('AdminProvider: User approved successfully in Firestore (setApproved)');
      
      // Log admin action
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        // Admin action completed
      }
      
      // Update local list immediately
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = updatedUser;
        AppLogger.debug('AdminProvider: Updated local user list');
        notifyListeners();
      }
      
      // Force UI update
      Future.microtask(() {
        notifyListeners();
      });
      
      // Temporarily suppress reappearance from stream in case of snapshot latency
      Future.delayed(const Duration(seconds: 3), () {
        if (_approvingUids.remove(uid)) {
          AppLogger.debug('AdminProvider: Cleared approving flag for $uid');
          notifyListeners();
        }
      });

      // Clear any previous errors
      _error = null;
    } catch (e) {
      AppLogger.debug('AdminProvider: Error approving user: $e');
      
      // Handle specific exception types
      if (e is PasswordMismatchException) {
        _error = e.message;
      } else if (e is UserAccountException) {
        _error = e.message;
      } else if (e is UserAuthenticationException) {
        _error = e.message;
      } else {
        _error = 'Failed to approve user: ${e.toString()}';
      }
      
      notifyListeners();
      rethrow; // Re-throw so the UI can show the error
    }
  }

  Future<void> rejectUser(String uid, {String? reason}) async {
    try {
      AppLogger.debug('AdminProvider: Rejecting user with UID: $uid');
      final user = _users.firstWhere((u) => u.uid == uid);
      AppLogger.debug('AdminProvider: Found user: ${user.name} (${user.email})');
      
      // Write rejection status; Cloud Function will email then delete the user record
      await usersRepo.setRejected(user.uid, reason: reason);
      AppLogger.debug('AdminProvider: setRejected write completed');
      
      // Log admin action
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        // Admin action completed
      }
      
      // Remove from local list immediately so it disappears from UI
      _users = _users.where((u) => u.uid != uid).toList();
      AppLogger.debug('AdminProvider: Removed rejected user from local list');
      notifyListeners();
      
      // Force UI update
      Future.microtask(() {
        notifyListeners();
      });
      
      // Clear any previous errors
      _error = null;
    } catch (e) {
      AppLogger.debug('AdminProvider: Error rejecting user: $e');
      _error = 'Failed to reject user: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-throw so the UI can show the error
    }
  }

  Future<void> refreshUsers() async {
    AppLogger.debug('AdminProvider: Refreshing users list');
    _usersSubscription?.cancel();
    _startListeningToUsers();
  }

  Future<void> forceRefreshUsers() async {
    AppLogger.debug('AdminProvider: Force refreshing users list');
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      
      // Get users directly from Firestore as fallback
      final users = await usersRepo.getAllUsers();
      _users = users;
      _loading = false;
      notifyListeners();
      
      AppLogger.debug('AdminProvider: Force refresh completed, found ${users.length} users');
      
      // Restart the stream
      _startListeningToUsers();
    } catch (e) {
      AppLogger.debug('AdminProvider: Error in force refresh: $e');
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  void testStream() {
    AppLogger.debug('AdminProvider: Testing stream connection...');
    _usersSubscription?.cancel();
    _startListeningToUsers();
  }

  Future<void> createTestUser() async {
    try {
      AppLogger.debug('AdminProvider: Creating test user...');
      final testUser = AppUser(
        uid: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Farmer ${DateTime.now().millisecondsSinceEpoch}',
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        role: 'farmer',
        approved: false,
        createdAt: DateTime.now(),
        fcmTokens: [],
      );
      
      AppLogger.debug('AdminProvider: Test user data: ${testUser.toMap()}');
      await usersRepo.createUser(testUser);
      AppLogger.debug('AdminProvider: Test user created successfully');
    } catch (e) {
      AppLogger.debug('AdminProvider: Error creating test user: $e');
      _error = 'Failed to create test user: ${e.toString()}';
      notifyListeners();
    }
  }
}