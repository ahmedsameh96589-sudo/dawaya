import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/auth_session.dart';
import '../models/chat_message.dart';
import '../models/consultation.dart';
import '../widgets/doctor_rating_badge.dart';
import 'consultation_rating_dialog.dart';
import '../../../core/network/uploads.dart';
import '../data/chat_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/realtime_client.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.consultationId});

  final String consultationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Consultation? _consultation;
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;
  StreamSubscription<ConsultationEvent>? _liveEvents;
  bool _ratingPromptShown = false;

  /// New messages arrive over the socket. Polling only runs as a safety net
  /// while the socket is disconnected (e.g. a flaky network).
  static const Duration _fallbackPollInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _loadConsultation().then((_) => _startLiveUpdates());
  }

  void _startLiveUpdates() {
    final realtime = ref.read(realtimeClientProvider);
    realtime.connect();
    _liveEvents = realtime.eventsFor(widget.consultationId).listen(_onLiveEvent);

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_fallbackPollInterval, (_) {
      if (mounted && !_sending && !_loading && !realtime.connected.value) {
        _refreshMessages(silent: true);
      }
    });
  }

  void _onLiveEvent(ConsultationEvent event) {
    if (!mounted) return;
    final message = event.message;
    if (message != null && !_messages.any((m) => m.id == message.id)) {
      final shouldScroll = _isNearBottom;
      setState(() => _messages.add(message));
      if (shouldScroll) _scrollToBottom();
    }
    // A status change (doctor closed the chat, first reply activated it)
    // needs the full consultation for the header and rating prompt.
    if (event.status != null && event.status != _consultation?.status) {
      _refreshMessages(silent: true);
    }
  }

  Future<void> _loadConsultation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final consultation = await ref.read(chatRepositoryProvider).fetchConsultation(
        widget.consultationId,
      );
      setState(() {
        _consultation = consultation;
        _messages = consultation.messages;
        _loading = false;
      });
      _scrollToBottom();
      _maybePromptForRating(previousStatus: null);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _maybePromptForRating({String? previousStatus}) {
    final consultation = _consultation;
    if (consultation == null) return;
    if (AuthSession.role == 'doctor') return;
    if (!consultation.isClosed || consultation.hasUserRating) return;
    if (_ratingPromptShown) return;

    final justClosed =
        previousStatus != null &&
        previousStatus != 'closed' &&
        consultation.isClosed;
    if (!justClosed && previousStatus != null) return;

    _ratingPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showRatingDialog(submitOnClose: false);
    });
  }

  Future<void> _showRatingDialog({required bool submitOnClose}) async {
    final doctorName = _consultation?.doctor.name ?? 'your doctor';
    final result = await showConsultationRatingDialog(
      context,
      doctorName: doctorName,
    );
    if (!mounted || result == null) return;

    try {
      final updated = submitOnClose
          ? await ref.read(chatRepositoryProvider).closeConsultation(
              consultationId: widget.consultationId,
              rating: result.rating,
              comment: result.comment,
            )
          : await ref.read(chatRepositoryProvider).rateConsultation(
              consultationId: widget.consultationId,
              rating: result.rating,
              comment: result.comment,
            );
      setState(() => _consultation = updated);
      _showMessage('Thank you for your rating!');
    } catch (e) {
      _ratingPromptShown = false;
      _showMessage(e.toString());
    }
  }

  Future<void> _endConsultation() async {
    final isDoctor = AuthSession.role == 'doctor';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDoctor ? 'End consultation?' : 'End consultation?'),
        content: Text(
          isDoctor
              ? 'This will close the chat for the patient.'
              : 'You can rate your doctor after ending the consultation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (isDoctor) {
      try {
        final updated = await ref.read(chatRepositoryProvider).closeConsultation(
          consultationId: widget.consultationId,
          reason: 'Closed by doctor',
        );
        setState(() => _consultation = updated);
        _showMessage('Consultation ended.');
      } catch (e) {
        _showMessage(e.toString());
      }
      return;
    }

    await _showRatingDialog(submitOnClose: true);
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending || _consultation?.isClosed == true) return;

    setState(() => _sending = true);
    try {
      final message = await ref.read(chatRepositoryProvider).sendMessage(
        consultationId: widget.consultationId,
        text: text,
      );
      _messageController.clear();
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImageMessage() async {
    if (_sending || _consultation?.isClosed == true) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final message = await ref.read(chatRepositoryProvider).sendMessage(
        consultationId: widget.consultationId,
        imagePath: picked.path,
      );
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _refreshMessages({bool silent = false}) async {
    try {
      final previousStatus = _consultation?.status;
      final consultation = await ref.read(chatRepositoryProvider).fetchConsultation(
        widget.consultationId,
      );
      if (!mounted) return;

      final incoming = consultation.messages;
      final hasNew = incoming.length != _messages.length ||
          (incoming.isNotEmpty &&
              (_messages.isEmpty ||
                  incoming.last.id != _messages.last.id)) ||
          consultation.status != previousStatus;

      if (!hasNew) return;

      final shouldScroll = !silent || _isNearBottom;
      setState(() {
        _consultation = consultation;
        _messages = incoming;
      });
      if (shouldScroll) _scrollToBottom();
      _maybePromptForRating(previousStatus: previousStatus);
    } catch (_) {}
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _liveEvents?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = AuthSession.role == 'doctor';
    final isClosed = _consultation?.isClosed == true;
    final title = _consultation?.displayName(viewingAsDoctor: isDoctor) ??
        (isDoctor ? 'مريض' : 'Doctor');
    return Scaffold(
      appBar: AppBar(
        title: isDoctor
            ? Text(title)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_consultation != null) ...[
                    const SizedBox(width: 8),
                    DoctorRatingBadge(
                      average: _consultation!.doctor.ratingAverage,
                      count: _consultation!.doctor.ratingCount,
                      compact: true,
                    ),
                  ],
                ],
              ),
        actions: [
          if (_consultation != null && !isClosed)
            IconButton(
              onPressed: _endConsultation,
              icon: const Icon(Icons.call_end_outlined),
              tooltip: 'End consultation',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('تعذّر تحميل المحادثة'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadConsultation,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (isClosed)
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          _consultation!.hasUserRating
                              ? 'Consultation ended. Thanks for your rating!'
                              : 'This consultation has ended.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMine = isDoctor
                                ? message.senderType == 'doctor'
                                : message.senderType == 'user';
                            final attachmentUrl = Uploads.resolve(
                              message.attachmentUrl,
                            );
                            return Align(
                              alignment: isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMine
                                      ? const Color(0xFF0B5ED7)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (attachmentUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          attachmentUrl,
                                          headers: Uploads.headers,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    if (message.text.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: attachmentUrl.isNotEmpty ? 8 : 0,
                                        ),
                                        child: Text(
                                          message.text,
                                          style: TextStyle(
                                            color: isMine
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (!isClosed)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _sending ? null : _sendImageMessage,
                                icon: const Icon(Icons.image_outlined),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendTextMessage(),
                                  decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FloatingActionButton(
                                mini: true,
                                onPressed: _sending ? null : _sendTextMessage,
                                child: _sending
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
