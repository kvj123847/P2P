import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Single source of truth for the prototype.
///
/// Uses Flutter's built-in [ChangeNotifier] + [InheritedNotifier] so the app
/// needs no extra packages. Any widget that calls `AppScope.of(context)`
/// rebuilds automatically when `notifyListeners()` is called.
///
/// When you add a backend, these methods are where API calls go
/// (e.g. `login()` -> POST /auth/login).
class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  bool loading = false;
  String? errorMessage;
  // ---------- User ----------
  bool isLoggedIn = false;
  String name = '';
  String email = '';
  String phone = '';
  String institution = '';
  String bio = '';
  List<String> interests = [];
  UserRole role = UserRole.learner;
  AgeTier tier = AgeTier.college;

  /// For the "Both" role: false = Learning mode, true = Teaching mode.
  bool teachingMode = false;

  // ---------- Learning ----------
  final Set<String> enrolledCourseIds = {};
  final Map<String, Set<int>> completedLessons = {};
  final List<Tutor> _tutors = [];
  final List<Course> _courses = [];

  // ---------- Sessions / chat / payments ----------
  List<Session> sessions = [];
  List<ChatThread> chats = [];
  List<PaymentTransaction> transactions = [];
  List<PaymentTransaction> earnings = [];
  double walletBalance = 0;
  double tutorBalance = 0;

  // ---------- Mentor review ----------
  final List<Submission> submissions = [];

  // ---------- Notifications ----------
  final List<AppNotification> notifications = [];

  // ======================================================
  // Auth
  // ======================================================

  Future<String?> login(String emailOrPhone, String password) async {
    try {
      final response = await _api.postCore(Endpoints.login, body: {
        'email': emailOrPhone,
        'password': password,
      });
      await _applyAuthResponse(response);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> signUp({
    required String fullName,
    required String emailAddress,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      final response = await _api.postCore(Endpoints.signup, body: {
        'email': emailAddress,
        'password': password,
        'firstName': parts.first,
        'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'phone': phoneNumber,
        'ageTier': tier.name.toUpperCase(),
        'role': 'LEARNER',
      });
      await _applyAuthResponse(response);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> response) async {
    final data = (response['data'] as Map<String, dynamic>?) ?? response;
    final user = (data['user'] as Map<String, dynamic>?) ?? const {};
    final access = data['accessToken']?.toString();
    final refresh = data['refreshToken']?.toString();
    if (access == null || refresh == null) {
      throw const ApiException(500, 'Authentication response was incomplete');
    }
    await _api.saveAccessToken(access);
    await _api.saveRefreshToken(refresh);
    _applyUser(user);
    isLoggedIn = true;
    await loadHome();
    notifyListeners();
  }

  void _applyUser(Map<String, dynamic> user) {
    name = [user['firstName'], user['lastName']]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    email = user['email']?.toString() ?? email;
    phone = user['phone']?.toString() ?? phone;
    tier = user['ageTier']?.toString().toLowerCase() == 'school'
        ? AgeTier.school
        : AgeTier.college;
    final roles = (user['roles'] as List<dynamic>?) ?? const [];
    final roleNames = roles
        .whereType<Map<String, dynamic>>()
        .map((item) => item['role']?.toString())
        .toSet();
    role = roleNames.contains('MENTOR')
        ? UserRole.mentor
        : roleNames.contains('TUTOR')
            ? UserRole.tutor
            : UserRole.learner;
  }

  Future<void> loadHome() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getCore(Endpoints.tutors),
        _api.getCore(Endpoints.courses),
        _api.getCore(Endpoints.sessions),
        _api.getCore(Endpoints.notifications),
      ]);
      _tutors
        ..clear()
        ..addAll(_mapTutors(results[0]));
      _courses
        ..clear()
        ..addAll(_mapCourses(results[1]));
      sessions = _mapSessions(results[2]);
      _mapNotifications(results[3]);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setRole(UserRole r) {
    role = r;
    teachingMode = r == UserRole.tutor;
    notifyListeners();
  }

  void setTier(AgeTier t) {
    tier = t;
    loadHome();
    notifyListeners();
  }

  void completeProfile({
    required String institutionName,
    required String about,
    required List<String> selectedSubjects,
  }) {
    institution = institutionName;
    bio = about;
    interests = selectedSubjects;
    notifyListeners();
  }

  void updateProfile({String? newName, String? newInstitution, String? newBio}) {
    if (newName != null && newName.trim().isNotEmpty) name = newName.trim();
    if (newInstitution != null) institution = newInstitution;
    if (newBio != null) bio = newBio;
    notifyListeners();
  }

  void toggleTeachingMode(bool value) {
    teachingMode = value;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    role = UserRole.learner;
    teachingMode = false;
    enrolledCourseIds.clear();
    completedLessons.clear();
    notifyListeners();
  }

  // ======================================================
  // Tutors & courses (always filtered by age tier)
  // ======================================================

  List<Tutor> get visibleTutors => List.unmodifiable(_tutors);

  List<Course> get visibleCourses => List.unmodifiable(_courses);

  Tutor? tutorById(String id) {
    for (final t in _tutors) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Course> coursesByTutor(String tutorId) =>
      visibleCourses.where((c) => c.tutorId == tutorId).toList();

  bool isEnrolled(Course c) => enrolledCourseIds.contains(c.id);

  List<Course> get enrolledCourses =>
      visibleCourses.where((c) => enrolledCourseIds.contains(c.id)).toList();

  double progressOf(Course c) {
    if (c.lessons.isEmpty) return 0;
    final done = completedLessons[c.id]?.length ?? 0;
    return done / c.lessons.length;
  }

  bool isLessonDone(Course c, int index) =>
      completedLessons[c.id]?.contains(index) ?? false;

  void markLessonDone(Course c, int index) {
    completedLessons.putIfAbsent(c.id, () => <int>{}).add(index);
    notifyListeners();
  }

  Future<String?> enroll(Course c, {String method = 'MOCK'}) async {
    try {
      if (c.isFree) {
        await _api.postCore('/courses/${c.id}/enroll');
      } else {
        final checkout = await _api.postCore(Endpoints.checkout, body: {
          'itemType': 'COURSE',
          'itemId': c.id,
        });
        final paymentId = ((checkout['data'] as Map<String, dynamic>?)?['paymentId'])?.toString();
        if (paymentId == null) throw const ApiException(500, 'Checkout response was incomplete');
        await _api.postCore('/payments/mock/$paymentId/confirm');
      }
      enrolledCourseIds.add(c.id);
      _notify(
        'Enrolled successfully',
        'DEMO PAYMENT: you can now access "${c.title}".',
        Icons.check_circle_outline,
      );
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  // ======================================================
  // Sessions
  // ======================================================

  List<Session> get upcomingSessions =>
      sessions.where((s) => s.status == SessionStatus.upcoming).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Session> get pastSessions =>
      sessions.where((s) => s.status != SessionStatus.upcoming).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  void bookSession({
    required Tutor tutor,
    required DateTime when,
    required int minutes,
    required SessionType type,
    required String topic,
    required double price,
    required String method,
  }) {
    sessions.add(Session(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      title: topic.isEmpty ? '${tutor.subjects.first} session' : topic,
      tutorName: tutor.name,
      subject: tutor.subjects.first,
      type: type,
      dateTime: when,
      durationMinutes: minutes,
      participants: type == SessionType.group ? 5 : 2,
      status: SessionStatus.upcoming,
      price: price,
    ));
    if (price > 0) {
      transactions.insert(
        0,
        PaymentTransaction(
          id: 'p${DateTime.now().millisecondsSinceEpoch}',
          title: 'Session with ${tutor.name}',
          amount: price,
          date: DateTime.now(),
          isCredit: false,
          method: method,
        ),
      );
      if (method == 'Wallet') walletBalance -= price;
    }
    _notify('Session booked', 'Your session with ${tutor.name} is confirmed.',
        Icons.event_available);
    notifyListeners();
  }

  /// Tutor creates a live session that learners can join.
  void createTeachingSession({
    required String title,
    required SessionType type,
    required DateTime when,
    required int minutes,
    required double price,
  }) {
    sessions.add(Session(
      id: 's${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      tutorName: name,
      subject: interests.isNotEmpty ? interests.first : 'General',
      type: type,
      dateTime: when,
      durationMinutes: minutes,
      participants: 1,
      status: SessionStatus.upcoming,
      price: price,
    ));
    _notify('Session scheduled', '"$title" is now visible to learners.',
        Icons.event_available);
    notifyListeners();
  }

  // ======================================================
  // Chat
  // ======================================================

  ChatThread openChatWith(Tutor tutor) {
    for (final c in chats) {
      if (c.name == tutor.name) return c;
    }
    final thread = ChatThread(
      id: 'chat_${tutor.id}',
      name: tutor.name,
      subtitle: tutor.subjects.first,
      color: tutor.avatarColor,
      online: tutor.online,
      messages: [],
    );
    chats.insert(0, thread);
    notifyListeners();
    return thread;
  }

  void sendMessage(ChatThread thread, String text, {String? attachment}) {
    thread.messages.add(ChatMessage(
      text: text,
      isMe: true,
      time: DateTime.now(),
      attachmentName: attachment,
    ));
    notifyListeners();
  }

  /// Simulated reply so the chat feels alive in a demo.
  void receiveAutoReply(ChatThread thread) {
    thread.messages.add(ChatMessage(
      text: 'Thanks! Give me a moment, I\'ll explain this step by step.',
      isMe: false,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  void markChatRead(ChatThread thread) {
    if (thread.unread == 0) return;
    thread.unread = 0;
    notifyListeners();
  }

  int get unreadChats => chats.fold(0, (sum, c) => sum + c.unread);

  // ======================================================
  // Tutor content + mentor review
  // ======================================================

  List<Submission> get mySubmissions =>
      submissions.where((s) => s.tutorName == name).toList();

  List<Submission> get pendingReviews =>
      submissions.where((s) => s.status == ReviewStatus.pending).toList();

  List<Submission> get reviewedSubmissions =>
      submissions.where((s) => s.status != ReviewStatus.pending).toList();

  void submitForReview({
    required String title,
    required String subject,
    required CourseType type,
    required double price,
    required String description,
    required List<String> lessonTitles,
  }) {
    submissions.insert(
      0,
      Submission(
        id: 'sub${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        tutorName: name,
        subject: subject,
        type: type,
        price: price,
        description: description,
        lessonTitles: lessonTitles,
        tier: tier,
        submittedAt: DateTime.now(),
      ),
    );
    _notify('Submitted for review',
        '"$title" was sent to mentors. You\'ll be notified after review.',
        Icons.hourglass_top);
    notifyListeners();
  }

  void reviewSubmission(Submission s, {required bool approve, String? feedback}) {
    s.status = approve ? ReviewStatus.approved : ReviewStatus.rejected;
    s.feedback = (feedback == null || feedback.trim().isEmpty)
        ? (approve ? 'Approved. Great work!' : 'Please revise and resubmit.')
        : feedback.trim();
    if (approve) {
      _courses.add(Course(
        id: 'pub_${s.id}',
        title: s.title,
        tutorId: 'me',
        tutorName: s.tutorName,
        subject: s.subject,
        type: s.type,
        price: s.price,
        rating: 0,
        students: 0,
        description: s.description,
        lessons: [
          for (final t in s.lessonTitles)
            Lesson(
              title: t,
              duration: s.type == CourseType.video ? '10:00' : '5 min read',
              body: 'Content for "$t" will appear here once the tutor uploads it.',
            ),
        ],
        tier: s.tier,
        color: const Color(0xFF1565C0),
        icon: s.type == CourseType.video
            ? Icons.play_circle_outline
            : Icons.article_outlined,
      ));
    }
    _notify(
      approve ? 'Content approved' : 'Content needs changes',
      '"${s.title}" was ${approve ? 'approved and is now live' : 'returned with feedback'}.',
      approve ? Icons.verified_outlined : Icons.feedback_outlined,
    );
    notifyListeners();
  }

  // ======================================================
  // Wallet / earnings
  // ======================================================

  void topUpWallet(double amount) {
    walletBalance += amount;
    transactions.insert(
      0,
      PaymentTransaction(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        title: 'Wallet top-up',
        amount: amount,
        date: DateTime.now(),
        isCredit: true,
        method: 'UPI',
      ),
    );
    notifyListeners();
  }

  void requestPayout(double amount) {
    tutorBalance -= amount;
    earnings.insert(
      0,
      PaymentTransaction(
        id: 'e${DateTime.now().millisecondsSinceEpoch}',
        title: 'Payout to bank',
        amount: amount,
        date: DateTime.now(),
        isCredit: false,
        method: 'Payout',
      ),
    );
    notifyListeners();
  }

  // ======================================================
  // Notifications
  // ======================================================

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  void markAllNotificationsRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void _notify(String title, String body, IconData icon) {
    notifications.insert(
      0,
      AppNotification(title: title, body: body, icon: icon, time: DateTime.now()),
    );
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> response) {
    final value = response['data'];
    return value is List
        ? value.whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
  }

  List<Tutor> _mapTutors(Map<String, dynamic> response) {
    return _dataList(response).map((item) {
      final first = item['firstName']?.toString() ?? '';
      final last = item['lastName']?.toString() ?? '';
      return Tutor(
        id: item['tutorId']?.toString() ?? '',
        name: '$first $last'.trim(),
        institution: '',
        subjects: (item['subjects'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
        rating: _asDouble(item['averageRating'] ?? item['avgRating']),
        reviews: _asInt(item['totalReviews'] ?? item['reviewCount']),
        sessionsTaught: 0,
        pricePerHour: _asDouble(item['hourlyRate']),
        bio: item['bio']?.toString() ?? '',
        tier: tier,
        avatarColor: Colors.blue,
        online: false,
      );
    }).where((tutor) => tutor.id.isNotEmpty).toList();
  }

  List<Course> _mapCourses(Map<String, dynamic> response) {
    return _dataList(response).map((item) {
      final tutor = item['tutor'] as Map<String, dynamic>?;
      final tutorUser = tutor?['user'] as Map<String, dynamic>?;
      return Course(
        id: item['id']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        tutorId: item['tutorId']?.toString() ?? '',
        tutorName: '${tutorUser?['firstName'] ?? ''} ${tutorUser?['lastName'] ?? ''}'.trim(),
        subject: item['subject']?.toString() ?? '',
        type: CourseType.text,
        price: _asDouble(item['price']),
        rating: 0,
        students: 0,
        description: item['description']?.toString() ?? '',
        lessons: const [],
        tier: tier,
        color: Colors.blue,
        icon: Icons.menu_book_outlined,
      );
    }).where((course) => course.id.isNotEmpty).toList();
  }

  List<Session> _mapSessions(Map<String, dynamic> response) {
    return _dataList(response).map((item) {
      final status = item['status']?.toString() == 'COMPLETED'
          ? SessionStatus.completed
          : item['status']?.toString() == 'CANCELLED'
              ? SessionStatus.cancelled
              : SessionStatus.upcoming;
      return Session(
        id: item['id']?.toString() ?? '',
        title: item['title']?.toString() ?? '',
        tutorName: item['tutorName']?.toString() ?? '',
        subject: item['subject']?.toString() ?? '',
        type: item['sessionType']?.toString() == 'GROUP'
            ? SessionType.group
            : SessionType.oneToOne,
        dateTime: DateTime.tryParse(item['scheduledAt']?.toString() ?? '') ?? DateTime.now(),
        durationMinutes: _asInt(item['durationMinutes']),
        participants: _asInt(item['maxParticipants'], 1),
        status: status,
        price: _asDouble(item['price']),
      );
    }).where((session) => session.id.isNotEmpty).toList();
  }

  void _mapNotifications(Map<String, dynamic> response) {
    notifications
      ..clear()
      ..addAll(_dataList(response).map((item) => AppNotification(
            title: item['title']?.toString() ?? 'Notification',
            body: item['body']?.toString() ?? '',
            icon: Icons.notifications_outlined,
            time: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
            read: item['isRead'] == true,
          )));
  }
}

/// Makes [AppState] available to the whole widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  /// Read the state AND rebuild when it changes (use inside build()).
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read the state WITHOUT listening (use inside callbacks like onPressed).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}

/// The API sends Prisma Decimal fields (price, hourlyRate, ratings) as
/// strings like "39.99", so accept both numbers and numeric strings.
double _asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? fallback;
  return fallback;
}
