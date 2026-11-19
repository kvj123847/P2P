import 'package:flutter/material.dart';

import '../models/models.dart';

/// Mock data so the whole frontend can be demonstrated before the backend
/// exists. Replace these with REST API calls later (see services/api_service.dart).
class MockData {
  static const List<String> subjects = [
    'Maths',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'English',
    'Electronics',
    'AI / ML',
  ];

  static const List<Tutor> tutors = [
    // ---------- College tier ----------
    Tutor(
      id: 't1',
      name: 'Aisha Rahman',
      institution: 'B.Tech CSE, Final Year',
      subjects: ['Computer Science', 'AI / ML'],
      rating: 4.9,
      reviews: 128,
      sessionsTaught: 210,
      pricePerHour: 249,
      bio: 'I love breaking down Data Structures and Machine Learning into '
          'simple, visual ideas. Placed at a product company; happy to help '
          'with interview prep too.',
      tier: AgeTier.college,
      avatarColor: Color(0xFF6366F1),
      online: true,
    ),
    Tutor(
      id: 't2',
      name: 'Rahul Menon',
      institution: 'M.Sc Physics',
      subjects: ['Physics', 'Maths'],
      rating: 4.7,
      reviews: 86,
      sessionsTaught: 140,
      pricePerHour: 199,
      bio: 'Engineering physics and calculus made intuitive. I use lots of '
          'worked examples from university exam papers.',
      tier: AgeTier.college,
      avatarColor: Color(0xFF0EA5E9),
    ),
    Tutor(
      id: 't3',
      name: 'Fathima Nasrin',
      institution: 'B.Tech ECE, S7',
      subjects: ['Electronics', 'Maths'],
      rating: 4.8,
      reviews: 64,
      sessionsTaught: 95,
      pricePerHour: 149,
      bio: 'Digital electronics, signals & systems and network theory. '
          'Short, focused sessions before your series exams.',
      tier: AgeTier.college,
      avatarColor: Color(0xFFEC4899),
      online: true,
    ),
    Tutor(
      id: 't4',
      name: 'Arjun Nair',
      institution: 'B.Tech AIML, S7',
      subjects: ['AI / ML', 'Computer Science'],
      rating: 4.6,
      reviews: 41,
      sessionsTaught: 58,
      pricePerHour: 0,
      bio: 'Free peer sessions on Python, NumPy and deep learning basics. '
          'Building my teaching portfolio!',
      tier: AgeTier.college,
      avatarColor: Color(0xFF10B981),
    ),
    // ---------- School tier ----------
    Tutor(
      id: 't5',
      name: 'Meera Krishnan',
      institution: 'Class 12, Science',
      subjects: ['Maths', 'Physics'],
      rating: 4.8,
      reviews: 52,
      sessionsTaught: 77,
      pricePerHour: 99,
      bio: 'School topper in Maths. I help Class 9-11 students with algebra, '
          'trigonometry and basic mechanics.',
      tier: AgeTier.school,
      avatarColor: Color(0xFFF97316),
      online: true,
    ),
    Tutor(
      id: 't6',
      name: 'Adil Hussain',
      institution: 'Class 11, Biology Science',
      subjects: ['Biology', 'Chemistry'],
      rating: 4.7,
      reviews: 33,
      sessionsTaught: 45,
      pricePerHour: 79,
      bio: 'Biology diagrams and chemistry equations explained with memory '
          'tricks that actually work.',
      tier: AgeTier.school,
      avatarColor: Color(0xFF8B5CF6),
    ),
    Tutor(
      id: 't7',
      name: 'Sneha Joseph',
      institution: 'Class 12, Computer Science',
      subjects: ['Computer Science', 'English'],
      rating: 4.9,
      reviews: 29,
      sessionsTaught: 38,
      pricePerHour: 0,
      bio: 'Free Python and English grammar sessions for juniors.',
      tier: AgeTier.school,
      avatarColor: Color(0xFF14B8A6),
    ),
  ];

  static const String _sampleText =
      'This lesson introduces the core idea with a short story, then builds '
      'up the formal definition step by step.\n\n'
      'Key points:\n'
      'â€¢ Start from what you already know and connect it to the new concept.\n'
      'â€¢ Work through two solved examples before trying one yourself.\n'
      'â€¢ Note common mistakes students make in exams.\n\n'
      'Practice: try the three questions at the end of this lesson, then '
      'post your doubts in the course chat. Your tutor usually replies '
      'within a few hours.';

  static const List<Course> courses = [
    // ---------- College tier ----------
    Course(
      id: 'c1',
      title: 'Python Programming from Zero',
      tutorId: 't1',
      tutorName: 'Aisha Rahman',
      subject: 'Computer Science',
      type: CourseType.video,
      price: 299,
      rating: 4.8,
      students: 1240,
      description: 'Learn Python the way seniors wish they had: variables, '
          'loops, functions, files and mini projects.',
      lessons: [
        Lesson(title: 'Setting up Python & VS Code', duration: '08:12'),
        Lesson(title: 'Variables and data types', duration: '12:40'),
        Lesson(title: 'Conditions and loops', duration: '15:05'),
        Lesson(title: 'Functions', duration: '14:22'),
        Lesson(title: 'Mini project: Quiz app', duration: '21:30'),
      ],
      tier: AgeTier.college,
      color: Color(0xFF6366F1),
      icon: Icons.code,
    ),
    Course(
      id: 'c2',
      title: 'Machine Learning Crash Course',
      tutorId: 't4',
      tutorName: 'Arjun Nair',
      subject: 'AI / ML',
      type: CourseType.video,
      price: 0,
      rating: 4.6,
      students: 860,
      description: 'Regression, classification and neural networks with '
          'hands-on scikit-learn notebooks.',
      lessons: [
        Lesson(title: 'What is ML?', duration: '09:45'),
        Lesson(title: 'Linear regression', duration: '18:10'),
        Lesson(title: 'Classification & metrics', duration: '16:55'),
        Lesson(title: 'Intro to neural networks', duration: '22:00'),
      ],
      tier: AgeTier.college,
      color: Color(0xFF10B981),
      icon: Icons.psychology,
    ),
    Course(
      id: 'c3',
      title: 'Engineering Mathematics - Calculus',
      tutorId: 't2',
      tutorName: 'Rahul Menon',
      subject: 'Maths',
      type: CourseType.text,
      price: 149,
      rating: 4.7,
      students: 530,
      description: 'Concise notes with solved university questions on limits, '
          'derivatives, integrals and series.',
      lessons: [
        Lesson(title: 'Limits & continuity', duration: '10 min read', body: _sampleText),
        Lesson(title: 'Differentiation rules', duration: '12 min read', body: _sampleText),
        Lesson(title: 'Integration techniques', duration: '15 min read', body: _sampleText),
        Lesson(title: 'Infinite series', duration: '14 min read', body: _sampleText),
      ],
      tier: AgeTier.college,
      color: Color(0xFF0EA5E9),
      icon: Icons.functions,
    ),
    Course(
      id: 'c4',
      title: 'Digital Electronics Notes',
      tutorId: 't3',
      tutorName: 'Fathima Nasrin',
      subject: 'Electronics',
      type: CourseType.text,
      price: 99,
      rating: 4.8,
      students: 410,
      description: 'Number systems, logic gates, K-maps, flip-flops and '
          'counters - exam-ready notes.',
      lessons: [
        Lesson(title: 'Number systems', duration: '8 min read', body: _sampleText),
        Lesson(title: 'Boolean algebra & K-maps', duration: '14 min read', body: _sampleText),
        Lesson(title: 'Flip-flops', duration: '11 min read', body: _sampleText),
      ],
      tier: AgeTier.college,
      color: Color(0xFFEC4899),
      icon: Icons.memory,
    ),
    // ---------- School tier ----------
    Course(
      id: 'c5',
      title: 'Class 10 Algebra Made Easy',
      tutorId: 't5',
      tutorName: 'Meera Krishnan',
      subject: 'Maths',
      type: CourseType.video,
      price: 99,
      rating: 4.8,
      students: 640,
      description: 'Quadratic equations, progressions and coordinate geometry '
          'with lots of practice.',
      lessons: [
        Lesson(title: 'Polynomials', duration: '10:20'),
        Lesson(title: 'Quadratic equations', duration: '14:05'),
        Lesson(title: 'Arithmetic progressions', duration: '12:48'),
      ],
      tier: AgeTier.school,
      color: Color(0xFFF97316),
      icon: Icons.calculate,
    ),
    Course(
      id: 'c6',
      title: 'Biology Diagrams Workbook',
      tutorId: 't6',
      tutorName: 'Adil Hussain',
      subject: 'Biology',
      type: CourseType.text,
      price: 0,
      rating: 4.7,
      students: 380,
      description: 'Step-by-step guides to draw and label the most asked '
          'biology diagrams.',
      lessons: [
        Lesson(title: 'The human heart', duration: '6 min read', body: _sampleText),
        Lesson(title: 'Plant cell vs animal cell', duration: '5 min read', body: _sampleText),
        Lesson(title: 'The nephron', duration: '7 min read', body: _sampleText),
      ],
      tier: AgeTier.school,
      color: Color(0xFF8B5CF6),
      icon: Icons.biotech,
    ),
    Course(
      id: 'c7',
      title: 'Python for School Students',
      tutorId: 't7',
      tutorName: 'Sneha Joseph',
      subject: 'Computer Science',
      type: CourseType.video,
      price: 0,
      rating: 4.9,
      students: 290,
      description: 'Fun beginner Python with games and puzzles.',
      lessons: [
        Lesson(title: 'Hello, Python!', duration: '07:30'),
        Lesson(title: 'Make a number-guessing game', duration: '13:15'),
      ],
      tier: AgeTier.school,
      color: Color(0xFF14B8A6),
      icon: Icons.sports_esports,
    ),
  ];

  static List<Session> sessionsFor(AgeTier tier) {
    final now = DateTime.now();
    final names = tutors.where((t) => t.tier == tier).toList();
    final a = names[0].name;
    final b = names.length > 1 ? names[1].name : a;
    final c = names.length > 2 ? names[2].name : a;
    return [
      Session(
        id: 's1',
        title: '${names[0].subjects.first} doubt clearing',
        tutorName: a,
        subject: names[0].subjects.first,
        type: SessionType.oneToOne,
        dateTime: now.add(const Duration(hours: 3)),
        durationMinutes: 45,
        participants: 2,
        status: SessionStatus.upcoming,
        price: names[0].pricePerHour,
      ),
      Session(
        id: 's2',
        title: 'Group revision: ${names.length > 1 ? names[1].subjects.first : 'Maths'}',
        tutorName: b,
        subject: names.length > 1 ? names[1].subjects.first : 'Maths',
        type: SessionType.group,
        dateTime: now.add(const Duration(days: 1, hours: 2)),
        durationMinutes: 60,
        participants: 6,
        status: SessionStatus.upcoming,
        price: 49,
      ),
      Session(
        id: 's3',
        title: 'Exam strategy session',
        tutorName: c,
        subject: 'General',
        type: SessionType.group,
        dateTime: now.subtract(const Duration(days: 2)),
        durationMinutes: 60,
        participants: 8,
        status: SessionStatus.completed,
        price: 0,
      ),
      Session(
        id: 's4',
        title: 'Problem solving practice',
        tutorName: a,
        subject: names[0].subjects.first,
        type: SessionType.oneToOne,
        dateTime: now.subtract(const Duration(days: 6)),
        durationMinutes: 30,
        participants: 2,
        status: SessionStatus.completed,
        price: names[0].pricePerHour / 2,
      ),
    ];
  }

  static List<ChatThread> chatsFor(AgeTier tier) {
    final now = DateTime.now();
    final list = tutors.where((t) => t.tier == tier).take(3).toList();
    return [
      for (var i = 0; i < list.length; i++)
        ChatThread(
          id: 'chat_${list[i].id}',
          name: list[i].name,
          subtitle: list[i].subjects.first,
          color: list[i].avatarColor,
          online: list[i].online,
          unread: i == 0 ? 2 : 0,
          messages: [
            ChatMessage(
              text: 'Hi! I had a doubt in ${list[i].subjects.first}.',
              isMe: true,
              time: now.subtract(Duration(hours: 5 + i)),
            ),
            ChatMessage(
              text: 'Sure, share the question and I will explain step by step.',
              isMe: false,
              time: now.subtract(Duration(hours: 4 + i, minutes: 50)),
            ),
            ChatMessage(
              text: 'Uploading it now.',
              isMe: true,
              time: now.subtract(Duration(hours: 4 + i, minutes: 45)),
              attachmentName: 'question_${i + 1}.jpg',
            ),
            ChatMessage(
              text: i == 0
                  ? 'Got it! Let\'s do a quick 20-min session at 6 PM?'
                  : 'Check the notes I shared in the course too.',
              isMe: false,
              time: now.subtract(Duration(minutes: 30 + i * 20)),
            ),
          ],
        ),
    ];
  }

  static List<PaymentTransaction> transactions() {
    final now = DateTime.now();
    return [
      PaymentTransaction(
        id: 'p1',
        title: 'Session with tutor',
        amount: 249,
        date: now.subtract(const Duration(days: 6)),
        isCredit: false,
        method: 'UPI',
      ),
      PaymentTransaction(
        id: 'p2',
        title: 'Wallet top-up',
        amount: 500,
        date: now.subtract(const Duration(days: 10)),
        isCredit: true,
        method: 'Card',
      ),
    ];
  }

  static List<PaymentTransaction> earnings() {
    final now = DateTime.now();
    return [
      PaymentTransaction(
        id: 'e1',
        title: 'Course sale: Python Programming',
        amount: 239,
        date: now.subtract(const Duration(hours: 20)),
        isCredit: true,
        method: 'Course',
      ),
      PaymentTransaction(
        id: 'e2',
        title: '1:1 session (45 min)',
        amount: 187,
        date: now.subtract(const Duration(days: 2)),
        isCredit: true,
        method: 'Session',
      ),
      PaymentTransaction(
        id: 'e3',
        title: 'Payout to bank',
        amount: 1200,
        date: now.subtract(const Duration(days: 7)),
        isCredit: false,
        method: 'Payout',
      ),
      PaymentTransaction(
        id: 'e4',
        title: 'Group session (6 learners)',
        amount: 294,
        date: now.subtract(const Duration(days: 9)),
        isCredit: true,
        method: 'Session',
      ),
    ];
  }

  static List<Submission> submissions() {
    final now = DateTime.now();
    return [
      Submission(
        id: 'sub1',
        title: 'Data Structures in C',
        tutorName: 'Aisha Rahman',
        subject: 'Computer Science',
        type: CourseType.video,
        price: 199,
        description: 'Arrays, linked lists, stacks, queues and trees with '
            'animations.',
        lessonTitles: ['Arrays', 'Linked lists', 'Stacks & queues', 'Trees'],
        tier: AgeTier.college,
        submittedAt: now.subtract(const Duration(hours: 6)),
      ),
      Submission(
        id: 'sub2',
        title: 'Chemical Bonding Notes',
        tutorName: 'Adil Hussain',
        subject: 'Chemistry',
        type: CourseType.text,
        price: 49,
        description: 'Ionic, covalent and metallic bonding with diagrams.',
        lessonTitles: ['Ionic bonds', 'Covalent bonds', 'VSEPR shapes'],
        tier: AgeTier.school,
        submittedAt: now.subtract(const Duration(days: 1)),
      ),
      Submission(
        id: 'sub3',
        title: 'Signals & Systems Quick Revision',
        tutorName: 'Fathima Nasrin',
        subject: 'Electronics',
        type: CourseType.text,
        price: 79,
        description: 'One-page summaries for each module.',
        lessonTitles: ['Classification of signals', 'LTI systems', 'Fourier series'],
        tier: AgeTier.college,
        submittedAt: now.subtract(const Duration(days: 3)),
        status: ReviewStatus.approved,
        feedback: 'Clear and accurate. Approved.',
      ),
    ];
  }

  static List<AppNotification> notifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        title: 'Session starting soon',
        body: 'Your 1:1 doubt-clearing session starts in 3 hours.',
        icon: Icons.videocam_outlined,
        time: now.subtract(const Duration(minutes: 10)),
      ),
      AppNotification(
        title: 'New message',
        body: 'Your tutor replied to your doubt.',
        icon: Icons.chat_bubble_outline,
        time: now.subtract(const Duration(minutes: 30)),
      ),
      AppNotification(
        title: 'Course update',
        body: 'A new lesson was added to a course you are enrolled in.',
        icon: Icons.menu_book_outlined,
        time: now.subtract(const Duration(days: 1)),
        read: true,
      ),
      AppNotification(
        title: 'Welcome to Learn Share Grow!',
        body: 'Complete your profile to get better tutor recommendations.',
        icon: Icons.celebration_outlined,
        time: now.subtract(const Duration(days: 2)),
        read: true,
      ),
    ];
  }
}
