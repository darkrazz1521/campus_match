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
  // In /providers/swipe_provider.dart

  void update(UserProvider userProvider) {
    print("SwipeProvider.update: Checking for user change...");
    // Check if the user has changed OR if the user logged out (userProvider.currentUser is null)
    if (userProvider.currentUser?.uid != _currentUser?.uid) {
       print("‼️ User changed! Old: ${_currentUser?.uid}, New: ${userProvider.currentUser?.uid}");

       // --- ⬇️ ADD THIS ⬇️ ---
       // Clear old profiles immediately to prevent showing wrong cards
       _profiles = [];
       _profilesLoaded = false; // Reset loaded flag
       _isLoading = true; // Show loading indicator
       // --- ⬆️ END ADD ⬆️ ---

       _currentUser = userProvider.currentUser; // Update the current user reference

       // If the new user is not null (i.e., user logged in, not out) AND profiles haven't loaded yet...
       if (_currentUser != null && !_profilesLoaded) {
          print("   User is valid and profiles not loaded, triggering loadProfiles...");
          loadProfiles(); // Trigger loading for the new user
       } else if (_currentUser == null) {
         print("   User logged out, clearing state.");
         _isLoading = false; // Stop loading if logged out
         notifyListeners(); // Update UI to show empty/logged out state
       } else {
         print("   User is same or profiles already loaded/loading.");
       }
    } else {
       print("SwipeProvider.update: No user change detected.");
       // Optional: You might want to periodically reload profiles even if user hasn't changed
       // E.g., if (!_profilesLoaded && !_isLoading) loadProfiles();
    }
  }

// In /providers/swipe_provider.dart

Future<void> loadProfiles() async {
  // --- Start Enhanced Debugging ---
  print("--- Starting loadProfiles ---");
  if (_currentUser == null) {
    print("❌ ERROR: _currentUser is NULL at start of loadProfiles. Aborting.");
    _isLoading = false; // Ensure loading stops
    notifyListeners();
    return;
  }
  final String currentUid = _currentUser!.uid;
  if (currentUid.isEmpty) {
     print("❌ ERROR: currentUid is EMPTY at start of loadProfiles. Aborting.");
     _isLoading = false;
     notifyListeners();
     return;
  }
  print("✅ Current User UID: $currentUid");
  // --- End Enhanced Debugging ---

  _isLoading = true;
  _profilesLoaded = true;
  notifyListeners(); // Let UI show loading indicator

  try {
    // Check swipe limit (ensure _currentUser is still valid here)
    final currentUserDataForLimit = _currentUser!; // Use a local non-null variable
    final isNewDay = !UserService.isSameDay(
      DateTime.now(),
      currentUserDataForLimit.lastSwipeDate ?? DateTime(2000),
    );
    // Note: Re-calculating hasLimit later with potentially fresher data.

    // 1. Fetch all users
    print("  Fetching users excluding $currentUid...");
    final fetchedUsers = await _userService.getAllUsers(currentUid);
    print("  Fetched ${fetchedUsers.length} users.");
    // --- Add Check: Does fetchedUsers contain currentUid? ---
    if (fetchedUsers.any((user) => user.uid == currentUid)) {
       print("‼️ CRITICAL ERROR: getAllUsers returned the current user!");
    }
    // --- End Check ---


    // 2. Load filters
    print("  Loading filter preferences...");
    final filterPrefs = await _userService.getFilterPreferences(currentUid);
     print("  Filter preferences loaded: ${filterPrefs != null}");

    // 3. Apply matchmaking logic
    print("  Processing matches...");
    List<UserModel> processedUsers;
    // --- Pass currentUser explicitly IF NEEDED, but your code doesn't seem to ---
    // Ensure processMatches doesn't modify the input list reference if possible
    // (Dart lists passed by reference) - It returns a new list which is good.
    if (currentUserDataForLimit.isPremium && filterPrefs != null) {
      processedUsers = await _matchmakingService.processMatches(
        users: List<UserModel>.from(fetchedUsers), // Pass a copy just in case
        filters: filterPrefs,
      );
    } else {
      processedUsers = await _matchmakingService.processMatches(
        users: List<UserModel>.from(fetchedUsers), // Pass a copy just in case
      );
    }
    print("  Processed ${processedUsers.length} users.");
    // --- Add Check: Did processMatches re-introduce currentUid? ---
     if (processedUsers.any((user) => user.uid == currentUid)) {
       print("‼️ CRITICAL ERROR: processMatches added the current user back!");
    }
    // --- End Check ---


    // 4. Apply Final Filter (Safeguard)
    print("  Applying final safeguard filter...");
    _profiles = processedUsers.where((user) => user.uid != currentUid).toList();
    print("  Final profile count: ${_profiles.length}");
    if (processedUsers.length != _profiles.length) {
         print("  ℹ️ Safeguard filter removed the current user (count was ${processedUsers.length}).");
    }


    _isLoading = false;

    // 5. Fetch latest user data for swipe status
    print("  Fetching latest user data for swipe status...");
    final latestUser = await _userService.getUserById(currentUid);
    _currentUser = latestUser; // Update the provider's currentUser

    if (_currentUser != null) {
      final isNewDayForLimit = !UserService.isSameDay(
        DateTime.now(),
        _currentUser!.lastSwipeDate ?? DateTime(2000),
      );
      final bool hasLimit = !_currentUser!.isPremium &&
                            (_currentUser!.dailySwipeCount >= 50) &&
                            !isNewDayForLimit;

      _canSwipe = _currentUser!.isPremium || !hasLimit;
      _lastSwipedUserId = _currentUser!.lastSwipedUserId;
       print("  Swipe status updated: canSwipe=$_canSwipe, lastSwipedUserId=$_lastSwipedUserId");
    } else {
      print("⚠️ Could not fetch latest user data.");
      _canSwipe = false;
      _lastSwipedUserId = null;
    }

  } catch (e, stackTrace) { // Added stackTrace
    print("❌❌❌ FATAL ERROR in loadProfiles: $e");
    print(stackTrace); // Print stack trace for detailed debugging
    _isLoading = false;
    _canSwipe = false; // Assume cannot swipe on error
  } finally {
    print("--- Finished loadProfiles ---");
    notifyListeners(); // Update UI with final state
  }
}

  // --- Swipe Actions ---

  Future<void> swipe(UserModel swipedUser, bool liked, bool superLike) async {

    if (_currentUser != null && swipedUser.uid == _currentUser!.uid) {
     print("‼️ ERROR: Attempted to swipe on self (UID: ${swipedUser.uid}). Swipe prevented.");
     // Optionally notify the UI or log to crash reporting here
     return; // Stop the swipe action
  }
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