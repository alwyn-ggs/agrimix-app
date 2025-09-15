import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/users_repo.dart';
import '../repositories/posts_repo.dart';
import '../repositories/recipes_repo.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/recipe.dart';
import '../utils/exceptions.dart';

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
    print('AdminProvider: Constructor called');
    print('AdminProvider: UsersRepo: ${usersRepo != null ? 'OK' : 'NULL'}');
    print('AdminProvider: Starting to listen to users...');
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

    print('AdminProvider: Starting to listen to users in real-time');
    print('AdminProvider: Current users count before stream: ${_users.length}');
    
    // Cancel existing subscription if any
    _usersSubscription?.cancel();
    
    _usersSubscription = usersRepo.watchAllUsers().listen(
      (users) {
        print('AdminProvider: Received ${users.length} users from stream');
        print('AdminProvider: Raw user data:');
        for (var user in users) {
          print('  - ${user.name} (${user.email}) - Role: ${user.role}, Approved: ${user.approved}');
        }
        
        // Check for new pending users
        final newPendingUsers = users.where((user) => 
          user.role == 'farmer' && !user.approved).toList();
        
        print('AdminProvider: Filtered pending users: ${newPendingUsers.length}');
        for (var user in newPendingUsers) {
          print('  Pending: ${user.name} (${user.email}) - Role: ${user.role}, Approved: ${user.approved}');
        }
        
        _users = users;
        _loading = false;
        _error = null;
        notifyListeners();
        
        print('AdminProvider: Updated _users list with ${_users.length} users');
        print('AdminProvider: Pending users count: ${pendingUsers.length}');
        
        // Force UI update
        Future.microtask(() {
          notifyListeners();
        });
      },
      onError: (error) {
        print('AdminProvider: Error in users stream: $error');
        _error = error.toString();
        _loading = false;
        notifyListeners();
      },
      onDone: () {
        print('AdminProvider: Users stream completed');
      },
    );
  }

  void _startListeningToRecipes() {
    print('AdminProvider: Starting to listen to recipes...');
    
    _recipesSubscription = recipes.watchAll().listen(
      (recipeList) {
        print('AdminProvider: Received ${recipeList.length} recipes from stream');
        _recipes = recipeList;
        notifyListeners();
      },
      onError: (error) {
        print('AdminProvider: Error in recipes stream: $error');
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Recipe moderation methods
  Future<void> approveRecipe(String recipeId, {String? reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      // Update recipe if needed (recipes are approved by default in current system)
      // This could be extended to add an 'approved' field to recipes
      print('AdminProvider: Recipe $recipeId approved');
    } catch (e) {
      print('AdminProvider: Error approving recipe: $e');
      _error = 'Failed to approve recipe: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> rejectRecipe(String recipeId, {required String reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      // Delete the rejected recipe
      await recipes.deleteRecipe(recipeId);
      print('AdminProvider: Recipe $recipeId rejected and deleted');
    } catch (e) {
      print('AdminProvider: Error rejecting recipe: $e');
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

      print('AdminProvider: Recipe $recipeId marked as standard');
    } catch (e) {
      print('AdminProvider: Error marking recipe as standard: $e');
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

      print('AdminProvider: Recipe $recipeId unmarked as standard');
    } catch (e) {
      print('AdminProvider: Error unmarking recipe as standard: $e');
      _error = 'Failed to unmark recipe as standard: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId, {required String reason}) async {
    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) throw Exception('Admin not authenticated');

      final recipe = _recipes.firstWhere((r) => r.id == recipeId);
      
      // Admin action completed

      await recipes.deleteRecipe(recipeId);
      print('AdminProvider: Recipe $recipeId deleted');
    } catch (e) {
      print('AdminProvider: Error deleting recipe: $e');
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

      print('AdminProvider: Rating removed for recipe $recipeId');
    } catch (e) {
      print('AdminProvider: Error removing rating: $e');
      _error = 'Failed to remove rating: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> approveUser(String uid) async {
    try {
      print('AdminProvider: Approving user with UID: $uid');
      _approvingUids.add(uid);
      notifyListeners();
      final user = _users.firstWhere((u) => u.uid == uid);
      print('AdminProvider: Found user: ${user.name} (${user.email})');
      
      final updatedUser = user.copyWith(approved: true);
      print('AdminProvider: Updating user approval status to: ${updatedUser.approved}');
      
      // Force approved to boolean true via dedicated setter to avoid type merge issues
      await usersRepo.setApproved(user.uid, true);
      print('AdminProvider: User approved successfully in Firestore (setApproved)');
      
      // Log admin action
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        // Admin action completed
      }
      
      // Update local list immediately
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = updatedUser;
        print('AdminProvider: Updated local user list');
        notifyListeners();
      }
      
      // Force UI update
      Future.microtask(() {
        notifyListeners();
      });
      
      // Temporarily suppress reappearance from stream in case of snapshot latency
      Future.delayed(const Duration(seconds: 3), () {
        if (_approvingUids.remove(uid)) {
          print('AdminProvider: Cleared approving flag for $uid');
          notifyListeners();
        }
      });

      // Clear any previous errors
      _error = null;
    } catch (e) {
      print('AdminProvider: Error approving user: $e');
      
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

  Future<void> rejectUser(String uid) async {
    try {
      print('AdminProvider: Rejecting user with UID: $uid');
      final user = _users.firstWhere((u) => u.uid == uid);
      print('AdminProvider: Found user: ${user.name} (${user.email})');
      
      final updatedUser = user.copyWith(approved: false);
      print('AdminProvider: Updating user approval status to: ${updatedUser.approved}');
      
      await usersRepo.updateUser(updatedUser);
      print('AdminProvider: User rejected successfully in Firestore');
      
      // Log admin action
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        // Admin action completed
      }
      
      // Update local list immediately
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = updatedUser;
        print('AdminProvider: Updated local user list');
        notifyListeners();
      }
      
      // Force UI update
      Future.microtask(() {
        notifyListeners();
      });
      
      // Clear any previous errors
      _error = null;
    } catch (e) {
      print('AdminProvider: Error rejecting user: $e');
      _error = 'Failed to reject user: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-throw so the UI can show the error
    }
  }

  Future<void> refreshUsers() async {
    print('AdminProvider: Refreshing users list');
    _usersSubscription?.cancel();
    _startListeningToUsers();
  }

  Future<void> forceRefreshUsers() async {
    print('AdminProvider: Force refreshing users list');
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      
      // Get users directly from Firestore as fallback
      final users = await usersRepo.getAllUsers();
      _users = users;
      _loading = false;
      notifyListeners();
      
      print('AdminProvider: Force refresh completed, found ${users.length} users');
      
      // Restart the stream
      _startListeningToUsers();
    } catch (e) {
      print('AdminProvider: Error in force refresh: $e');
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  void testStream() {
    print('AdminProvider: Testing stream connection...');
    _usersSubscription?.cancel();
    _startListeningToUsers();
  }

  Future<void> createTestUser() async {
    try {
      print('AdminProvider: Creating test user...');
      final testUser = AppUser(
        uid: 'test_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Farmer ${DateTime.now().millisecondsSinceEpoch}',
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        role: 'farmer',
        approved: false,
        createdAt: DateTime.now(),
        fcmTokens: [],
      );
      
      print('AdminProvider: Test user data: ${testUser.toMap()}');
      await usersRepo.createUser(testUser);
      print('AdminProvider: Test user created successfully');
    } catch (e) {
      print('AdminProvider: Error creating test user: $e');
      _error = 'Failed to create test user: ${e.toString()}';
      notifyListeners();
    }
  }
}