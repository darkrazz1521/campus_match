import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:google_fonts/google_fonts.dart' hide Config; // Hide the conflicting name
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For timestamp formatting
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // For emoji keyboard
import 'package:visibility_detector/visibility_detector.dart'; // For read receipts
import '../providers/user_provider.dart';
import '../services/chat_service.dart';
// Hide this conflicting name 

class ChatScreen extends StatefulWidget {
  final String matchName;
  final String matchImage;
  final String matchUid;

  const ChatScreen({
    super.key,
    required this.matchName,
    required this.matchImage,
    required this.matchUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  // --- State Variables ---
  late String _currentUid;
  late String _matchId;
  late Stream<QuerySnapshot> _chatStream;
  late Stream<DocumentSnapshot> _matchStream; // For typing status (Suggestion #6)
  late Stream<DocumentSnapshot> _userStream; // For online status (Suggestion #1)

  bool _isSendButtonEnabled = false; // (Suggestion #8)
  bool _showEmojiPicker = false; // (Suggestion #8)
  Timer? _typingDebouncer; // (Suggestion #6)
  String? _latestMessageIdFromMatch; // For floating heart (Suggestion #4)
  bool _showHeartAnimation = false; // (Suggestion #4)

  // --- UI Colors & Gradients (Suggestions #2, #5) ---
  final Color accentColor = const Color(0xFF9A4C73);
  final Gradient bgGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
  );
  final Gradient myMessageGradient = const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF9A4C73), Color(0xFFE86A92)],
  );

  @override
  void initState() {
    super.initState();
    _currentUid = Provider.of<UserProvider>(context, listen: false).currentUser!.uid;
    _matchId = _chatService.getMatchId(_currentUid, widget.matchUid);

    // --- Stream Setup ---
    _chatStream = _chatService.getChatStream(_matchId);
    _matchStream = _chatService.getMatchStream(_matchId);
    _userStream = _chatService.getUserStream(widget.matchUid);

    // --- Mark messages as read on screen load ---
    _chatService.markMessagesAsRead(_matchId, _currentUid);

    // --- Listeners ---
    _messageController.addListener(_updateSendButtonState);
    _chatStream.listen(_onNewMessage);
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateSendButtonState);
    _messageController.dispose();
    _scrollController.dispose();
    _typingDebouncer?.cancel();
    // Stop typing when leaving screen
    _chatService.setTypingStatus(_matchId, _currentUid, false);
    super.dispose();
  }

  /// (Suggestion #8) Update send button state
  void _updateSendButtonState() {
    if (mounted) {
      setState(() {
        _isSendButtonEnabled = _messageController.text.trim().isNotEmpty;
      });
    }
  }

  /// (Suggestion #4 & #7) Listen for new messages
  void _onNewMessage(QuerySnapshot snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final latestMessage = snapshot.docs.first;
      final latestId = latestMessage.id;
      final fromUid = (latestMessage.data() as Map)['fromUid'];

      // Trigger floating heart animation
      if (fromUid == widget.matchUid && latestId != _latestMessageIdFromMatch) {
        _latestMessageIdFromMatch = latestId;
        _triggerHeartAnimation();
      }
    }
    
    // (Suggestion #7) Auto-scroll logic
    if (mounted && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  /// (Suggestion #10) Get image provider (same as your original)
  ImageProvider<Object>? _getImageProvider(String imgData) {
    if (imgData.isEmpty) return null;
    if (imgData.length > 200 && !imgData.startsWith('http')) {
      try {
        final base64Str = imgData.contains(',') ? imgData.split(',').last : imgData;
        final imageBytes = base64Decode(base64Str);
        return MemoryImage(imageBytes);
      } catch (e) {
        debugPrint("⚠️ Invalid Base64 in chat screen: $e");
        return null;
      }
    }
    if (Uri.tryParse(imgData)?.hasAbsolutePath == true) {
      return NetworkImage(imgData);
    }
    return null;
  }

  /// (Suggestion #6) Handle typing status with a debouncer
  void _onTypingChanged(String text) {
    if (_typingDebouncer?.isActive ?? false) _typingDebouncer!.cancel();
    
    // Set typing to true immediately
    _chatService.setTypingStatus(_matchId, _currentUid, true);

    // Set typing to false after 2 seconds of inactivity
    _typingDebouncer = Timer(const Duration(seconds: 2), () {
      _chatService.setTypingStatus(_matchId, _currentUid, false);
    });
  }

  /// (Suggestion #8, #10) Send message logic
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      matchId: _matchId,
      messageText: text,
      fromUid: _currentUid,
      toUid: widget.matchUid,
    );

    _messageController.clear();
    HapticFeedback.mediumImpact(); // (Suggestion #10) Haptic feedback
    
    // Stop typing immediately after sending
    _typingDebouncer?.cancel();
    _chatService.setTypingStatus(_matchId, _currentUid, false);

    // Ensure emoji picker is hidden
    if (_showEmojiPicker) {
      _toggleEmojiPicker();
    }
  }

  /// (Suggestion #8) Toggle emoji picker and manage keyboard
  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
    
    // Manually hide/show keyboard
    if (_showEmojiPicker) {
      FocusScope.of(context).unfocus(); // Hide keyboard
    } else {
      FocusScope.of(context).requestFocus(); // Show keyboard
    }
  }

  /// (Suggestion #4) Trigger floating heart animation
  void _triggerHeartAnimation() {
    if (!mounted) return;
    setState(() => _showHeartAnimation = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showHeartAnimation = false);
      }
    });
  }

  /// (Suggestion #2) Format Firestore Timestamp to "2:15 PM"
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  /// (Suggestion #9) Show Block/Report/Unmatch menu
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Safety Options",
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                leading: Icon(Icons.block, color: Colors.red.shade700),
                title: Text("Block ${widget.matchName}"),
                onTap: () {
                  // TODO: Implement block logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.flag, color: Colors.orange.shade700),
                title: Text("Report ${widget.matchName}"),
                onTap: () {
                  // TODO: Implement report logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.close, color: Colors.grey.shade700),
                title: Text("Unmatch"),
                onTap: () {
                  // TODO: Implement unmatch logic
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// (Suggestion #3) Show attachment menu
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Send...",
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: accentColor),
                title: Text("Photo from Gallery"),
                onTap: () {
                  // TODO: Implement image picker (gallery)
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: accentColor),
                title: Text("Take Photo"),
                onTap: () {
                  // TODO: Implement image picker (camera)
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.mic, color: accentColor),
                title: Text("Voice Note"),
                onTap: () {
                  // TODO: Implement voice note logic
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.pink),
                title: Text("Send Flirt Animation"),
                onTap: () {
                  // TODO: Implement custom flirt/animation message type
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
      );
  }


  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    // (Suggestion #10) Dismiss keyboard on tap outside
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_showEmojiPicker) {
          setState(() => _showEmojiPicker = false);
        }
      },
      child: Scaffold(
        // (Suggestion #5) Use background gradient for the whole screen
        body: Container(
          decoration: BoxDecoration(gradient: bgGradient),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // (Suggestion #1, #6, #9, #10) - Replaced AppBar with SliverAppBar
                    // The chat list is now in a CustomScrollView
                    // --- THIS IS THE FIX ---
Expanded(
  child: CustomScrollView(
    controller: _scrollController,
    reverse: true, // Shows messages from the bottom up
    physics: const BouncingScrollPhysics(),
    slivers: [
      _buildChatList(),     // The list of messages (now first)
      _buildSliverAppBar(), // Sticky header (now second)
    ],
  ),
),
                    
                    // --- Message Input Field ---
                    _buildMessageInput(), // (Suggestion #5, #8)
                    
                    // (Suggestion #8) Emoji Picker
                    _buildEmojiPicker(), 
                  ],
                ),
              ),

              // (Suggestion #4) Floating Love Reaction
              _buildFloatingHeartAnimation(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builder Methods ---

  /// (Suggestion #1) Sticky Romantic Header
  Widget _buildSliverAppBar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream, // Listen to user's online/lastSeen status
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        
        return StreamBuilder<DocumentSnapshot>(
          stream: _matchStream, // Listen to match doc for typing status
          builder: (context, matchSnapshot) {
            final matchData = matchSnapshot.data?.data() as Map<String, dynamic>?;
            final typingMap = matchData?['typing'] as Map<String, dynamic>?;
            final bool isMatchTyping = typingMap?[widget.matchUid] ?? false;

            return SliverAppBar(
              pinned: true, // Stays at the top
              floating: true, // Appears as you scroll up
              snap: true, // Snaps into view
              elevation: 2,
              backgroundColor: Colors.white.withOpacity(0.8), // Subtle blur effect
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  // (Suggestion #10) Hero animation for avatar
                  Hero(
                    tag: 'avatar_${widget.matchUid}',
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.pink.shade50,
                      backgroundImage: _getImageProvider(widget.matchImage),
                      child: (_getImageProvider(widget.matchImage) == null)
                          ? Icon(Icons.person, color: accentColor)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.matchName,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        // (Suggestion #1, #6) Status text
                        _buildStatusText(isMatchTyping, userData),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // (Suggestion #9) Safety options
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black87),
                  onPressed: _showChatOptions,
                ),
              ],
            );
          }
        );
      }
    );
  }

  /// (Suggestion #1, #6) Helper for dynamic status text in AppBar
  Widget _buildStatusText(bool isTyping, Map<String, dynamic>? userData) {
    // (Suggestion #6, Bonus Idea) Typing has highest priority
    if (isTyping) {
      return Text(
        "Typing... ❤️", // (Bonus: romantic typing)
        style: GoogleFonts.beVietnamPro(
          fontSize: 13,
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    
    // (Suggestion #1) Online/Offline status
    if (userData != null) {
      final bool isOnline = userData['isOnline'] ?? false;
      final Timestamp? lastSeen = userData['lastSeen'];

      if (isOnline) {
        return Text(
          "Online", // TODO: Add online dot
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: Colors.green.shade700,
          ),
        );
      }
      
      if (lastSeen != null) {
        // Simple relative time (e.g., "Last seen 5m ago")
        // For a more robust solution, use the `timeago` package
        final duration = DateTime.now().difference(lastSeen.toDate());
        String timeAgo = "Last seen recently";
        if (duration.inMinutes < 60) {
          timeAgo = "Last seen ${duration.inMinutes}m ago";
        } else if (duration.inHours < 24) {
          timeAgo = "Last seen ${duration.inHours}h ago";
        } else {
          timeAgo = "Last seen ${duration.inDays}d ago";
        }

        return Text(
          timeAgo,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        );
      }
    }
    
    // Fallback
    return Text(
      "Offline",
      style: GoogleFonts.beVietnamPro(
        fontSize: 13,
        color: Colors.grey[600],
      ),
    );
  }


  /// (Suggestion #2, #6, #7) The list of chat messages
  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                "You matched! Say hi 👋",
                style: GoogleFonts.beVietnamPro(color: Colors.grey[700], fontSize: 16),
              ),
            ),
          );
        }

        final messages = snapshot.data!.docs;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final msg = messages[index];
              final msgData = msg.data() as Map<String, dynamic>;
              final String messageId = msg.id; // Get message ID for reactions
              
              // (Suggestion #7) Message grouping logic
              bool isContinuation = false;
              if (index < messages.length - 1) {
                final prevMsgData = messages[index + 1].data() as Map<String, dynamic>;
                if (prevMsgData['fromUid'] == msgData['fromUid']) {
                  isContinuation = true;
                }
              }

              return _buildMessageBubble(
                msgData,
                messageId,
                isContinuation,
              );
            },
            childCount: messages.length,
          ),
        );
      },
    );
  }

  /// (Suggestion #2, #6, #7) A single message bubble
  Widget _buildMessageBubble(
      Map<String, dynamic> msgData, String messageId, bool isContinuation) {
    final bool isMe = msgData['fromUid'] == _currentUid;
    final String text = msgData['text'] ?? '';
    final Timestamp? timestamp = msgData['timestamp'];
    final bool isRead = msgData['isRead'] ?? false;
    final String? reaction = msgData['reaction']; // (Suggestion #2)

    // (Suggestion #7) Adjust bubble rounding for grouped messages
    final Radius messageRadius = const Radius.circular(20);
    final Radius continuationRadius = const Radius.circular(5);

    final bubbleBorderRadius = BorderRadius.only(
      topLeft: messageRadius,
      topRight: messageRadius,
      bottomLeft: isMe
          ? messageRadius
          : (isContinuation ? continuationRadius : messageRadius),
      bottomRight: isMe
          ? (isContinuation ? continuationRadius : messageRadius)
          : messageRadius,
    );

    // (Suggestion #6) Mark as read when message is visible
    return VisibilityDetector(
      key: Key(messageId),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !isMe && !isRead) {
          _chatService.markMessagesAsRead(_matchId, _currentUid);
        }
      },
      child: GestureDetector(
        // (Suggestion #2) Double tap to react
        onDoubleTap: () {
          final newReaction = reaction == null ? '❤️' : null;
          _chatService.reactToMessage(_matchId, messageId, newReaction);
        },
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: isContinuation ? 2 : 5, // (Suggestion #7)
            horizontal: 12,
          ),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    // (Suggestion #2) Gradient for "my" messages
                    gradient: isMe ? myMessageGradient : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: bubbleBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: GoogleFonts.beVietnamPro(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // (Suggestion #2, #6) Timestamp and Read Receipt
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: (isMe ? Colors.white : Colors.black)
                                  .withOpacity(0.6),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 5),
                            Icon(
                              isRead ? Icons.done_all : Icons.done,
                              size: 14,
                              color: (isMe ? Colors.white : Colors.black)
                                  .withOpacity(0.6),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
                // (Suggestion #2) Show reaction
                if (reaction != null)
                  Positioned(
                    bottom: -10,
                    right: isMe ? 0 : null,
                    left: isMe ? null : 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ]
                      ),
                      child: Text(reaction, style: TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// (Suggestion #5, #8) The message input bar
  Widget _buildMessageInput() {
    // (Suggestion #5) Frosted glass effect
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // (Suggestion #3) Attachment Button
              IconButton(
                icon: Icon(Icons.add, color: accentColor),
                onPressed: _showAttachmentMenu,
              ),
              // (Suggestion #8) Polished TextField
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      // (Suggestion #8) Emoji Button
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, 
                          color: Colors.grey[600]
                        ),
                        onPressed: _toggleEmojiPicker,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: _onTypingChanged, // (Suggestion #6)
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1, // (Suggestion #8) Auto-grow
                          maxLines: 5, // (Suggestion #8) Auto-grow
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle:
                                GoogleFonts.beVietnamPro(color: Colors.grey[600]),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // (Suggestion #8) Send Button
              IconButton(
                icon: Icon(Icons.send_rounded, 
                  color: _isSendButtonEnabled ? accentColor : Colors.grey,
                ),
                onPressed: _isSendButtonEnabled ? _sendMessage : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (Suggestion #8) The emoji picker widget
/// (Suggestion #8) The emoji picker widget
  Widget _buildEmojiPicker() {
    return Offstage(
      offstage: !_showEmojiPicker,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          onEmojiSelected: (Category? category, Emoji emoji) {
            // This is the recommended way to update text
            final text = _messageController.text;
            final selection = _messageController.selection;
            final newText = text.replaceRange(
              selection.start,
              selection.end,
              emoji.emoji,
            );
            _messageController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.fromPosition(
                TextPosition(offset: selection.start + emoji.emoji.length),
              ),
            );
          },
          // --- UNCOMMENTED AND FIXED CONFIG ---
          // config: Config(
          //   columns: 7,
          //   emojiSizeMax:
          //       32 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
          //   verticalSpacing: 0,
          //   horizontalSpacing: 0,
          //   gridPadding: EdgeInsets.zero,
          //   initCategory: Category.RECENT,
          //   bgColor: Color(0xFFF2F2F2),
          //   indicatorColor: accentColor,
          //   iconColor: Colors.grey,
          //   iconColorSelected: accentColor,
          //   skinToneDialogBgColor: Colors.white,
          //   skinToneIndicatorColor: Colors.grey,
          //   enableSkinTones: true,
          //   // showRecentTab: true,  <-- This was an error, so it's removed
          //   // replaceSmiley: true, <-- This was an error, so it's removed
          //   recentsLimit: 28,
          //   noRecents: Text(
          //     'No Recents',
          //     style: TextStyle(fontSize: 20, color: Colors.black26),
          //     textAlign: TextAlign.center,
          //   ),
          //   tabIndicatorAnimDuration: kTabScrollDuration,
          //   categoryIcons: const CategoryIcons(),
          //   buttonMode: ButtonMode.MATERIAL,
          // ),
        ),
      ),
    );
  }

  /// (Suggestion #4) Floating heart animation
  Widget _buildFloatingHeartAnimation() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      top: _showHeartAnimation ? 100 : 80, // Animate from top
      left: 20,
      child: AnimatedOpacity(
        duration: const Duration(seconds: 2),
        opacity: _showHeartAnimation ? 1.0 : 0.0,
        child: Icon(
          Icons.favorite,
          color: Colors.pink.withOpacity(0.7),
          size: 30,
        ),
      ),
    );
  }
}