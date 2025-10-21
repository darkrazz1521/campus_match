import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/matchmaking_service.dart';
import 'user_provider.dart'; // Import UserProvider

class SwipeProvider with ChangeNotifier {
  final UserService _userService = UserService.instance;
  final MatchmakingService _matchmakingService = MatchmakingService.instance;

  List<UserModel> _profiles = [];
  List<UserModel> get profiles => _profiles;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _canSwipe = true;
  bool get canSwipe => _canSwipe;

  String? _lastSwipedUserId;
  String? get lastSwipedUserId => _lastSwipedUserId;
  
  bool _isSwiping = false; // To prevent concurrent swipes
  bool get isSwiping => _isSwiping;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  UserModel? _matchToShow;
  UserModel? get matchToShow => _matchToShow;

  bool _profilesLoaded = false;

  void clearMatchToShow() {
    _matchToShow = null;
    // We don't notify listeners here, the dialog will just close.
  }

  // Update method to get data from UserProvider
  void update(UserProvider userProvider) {
    // Check if the user has changed
    if (userProvider.currentUser != _currentUser) {
        _currentUser = userProvider.currentUser;
        // If user is loaded and profiles haven't been, load them
        if (_currentUser != null && !_profilesLoaded) {
          loadProfiles();
        }
    }
  }

  Future<void> loadProfiles() async {
    if (_currentUser == null) return;

    _isLoading = true;
    _profilesLoaded = true; // Mark as loaded to prevent re-fetch on simple updates
    notifyListeners();

    try {
      final String currentUid = _currentUser!.uid;
      
      // Check swipe limit
      final isNewDay = !UserService.isSameDay(
        DateTime.now(),
        _currentUser!.lastSwipeDate ?? DateTime(2000),
      );
      final hasLimit =
          !_currentUser!.isPremium && _currentUser!.dailySwipeCount >= 50 && !isNewDay;

      // 1. Fetch all users
      final fetchedUsers = await _userService.getAllUsers(currentUid);

      // 2. Load user’s saved filter preferences
      final filterPrefs = await _userService.getFilterPreferences(currentUid);

      // 3. Apply filters
      List<UserModel> processedUsers;
      if (_currentUser!.isPremium && filterPrefs != null) {
        processedUsers = await _matchmakingService.processMatches(
          users: fetchedUsers,
          filters: filterPrefs,
        );
      } else {
        processedUsers = await _matchmakingService.processMatches(
          users: fetchedUsers,
        );
      }

      _profiles = processedUsers;
      _isLoading = false;
      _canSwipe = _currentUser!.isPremium || !hasLimit;
      _lastSwipedUserId = _currentUser!.lastSwipedUserId;
      
    } catch (e) {
      print("Error loading profiles in Provider: $e");
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  // --- Swipe Actions ---

  Future<void> swipe(UserModel swipedUser, bool liked, bool superLike) async {
   // if (_currentUser == null || _isSwiping) return;
    if (!_canSwipe) return;

    _isSwiping = true;
    // Don't notify here, it's not necessary
    // notifyListeners();

    Map<String, dynamic> res = {};
    try {
      res = await _userService.updateSwipe(
        currentUid: _currentUser!.uid,
        targetUid: swipedUser.uid, // Use swipedUser.uid
        liked: liked,
        superLike: superLike,
      );

      if (res['success'] == true) {
        _lastSwipedUserId = swipedUser.uid; // Store the ID

        // **** THIS IS THE KEY ****
        // If it's a match, set the user to our new state variable
        if (res['isMatch'] == true) {
          _matchToShow = swipedUser;
        }
      } else {
        // The swipe failed, log it.
        // We can't easily roll back the UI at this point.
        print("Swipe failed in provider: ${res['message']}");
      }
    } catch (e) {
      print("❌ Error during updateSwipe call: $e");
    } finally {
      _isSwiping = false;
      // This notify will trigger the UI to check for a match
      notifyListeners();
    }
    // No need to return 'res'
  }

  Future<Map<String, dynamic>> revertLastSwipe() async {
    if (_currentUser == null) return {'success': false, 'message': 'Not logged in.'};
    if (_lastSwipedUserId == null) {
      return {'success': false, 'message': 'No swipe to undo.'};
    }
    
    _isSwiping = true;
    notifyListeners();

    // Use constants for max values
    final int maxPremiumSuperLikes = 10;
    final int maxPremiumUndos = 10;
    final int maxFreeUndos = 1;

    final maxAllowedUndos =
      _currentUser!.isPremium &&
      (_currentUser!.superLikesUsedToday ?? 0) >= maxPremiumSuperLikes
        ? maxPremiumUndos 
        : maxFreeUndos;

    final res = await _userService.revertLastSwipe(
      _currentUser!.uid,
      maxFreeUndos: maxAllowedUndos,
    );

    if (res['success'] == true) {
      _lastSwipedUserId = null; // Clear tracking
      // Reload profiles to get the user back
      await loadProfiles(); 
    }

    _isSwiping = false;
    notifyListeners();
    return res;
  }
}