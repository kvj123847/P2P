import 'package:flutter/material.dart';

/// ---------- Enums ----------

enum UserRole { learner, tutor, both, mentor }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.learner:
        return 'Learner';
      case UserRole.tutor:
        return 'Tutor';
      case UserRole.both:
        return 'Learner & Tutor';
      case UserRole.mentor:
        return 'Mentor';
    }
  }

  bool get canTeach => this == UserRole.tutor || this == UserRole.both;
  bool get canLearn => this == UserRole.learner || this == UserRole.both;
}

/// Age-tier separation: school students (<18) and college/adults (18+)
/// never cross-match in search, chat, sessions or courses.
enum AgeTier { school, college }

extension AgeTierX on AgeTier {
  String get label => this == AgeTier.school ? 'School (Under 18)' : 'College (18+)';
  String get short => this == AgeTier.school ? 'School' : 'College';
}

enum ReviewStatus { draft, pending, approved, rejected }

extension ReviewStatusX on ReviewStatus {
  String get label {
    switch (this) {
      case ReviewStatus.draft:
        return 'Draft';
      case ReviewStatus.pending:
        return 'Pending Review';
      case ReviewStatus.approved:
        return 'Approved';
      case ReviewStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case ReviewStatus.draft:
        return const Color(0xFF718096);
      case ReviewStatus.pending:
        return const Color(0xFFF59E0B);
      case ReviewStatus.approved:
        return const Color(0xFF16A34A);
      case ReviewStatus.rejected:
        return const Color(0xFFDC2626);
    }
  }
}

enum CourseType { text, video }

enum SessionType { oneToOne, group }

enum SessionStatus { upcoming, completed, cancelled }

/// ---------- Models ----------

class Tutor {
  final String id;
  final String name;
  final String institution;
  final List<String> subjects;
  final double rating;
  final int reviews;
  final int sessionsTaught;
  final double pricePerHour;
  final String bio;
  final AgeTier tier;
  final Color avatarColor;
  final bool online;

  const Tutor({
    required this.id,
    required this.name,
    required this.institution,
    required this.subjects,
    required this.rating,
    required this.reviews,
    required this.sessionsTaught,
    required this.pricePerHour,
    required this.bio,
    required this.tier,
    required this.avatarColor,
    this.online = false,
  });

  String get initials {
    final parts = name.split(' ');
    return parts.take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();
  }
}

class Lesson {
  final String title;
  final String duration;
  final String body;

  const Lesson({required this.title, required this.duration, this.body = ''});
}

class Course {
  final String id;
  final String title;
  final String tutorId;
  final String tutorName;
  final String subject;
  final CourseType type;
  final double price;
  final double rating;
  final int students;
  final String description;
  final List<Lesson> lessons;
  final AgeTier tier;
  final Color color;
  final IconData icon;

  const Course({
    required this.id,
    required this.title,
    required this.tutorId,
    required this.tutorName,
    required this.subject,
    required this.type,
    required this.price,
    required this.rating,
    required this.students,
    required this.description,
    required this.lessons,
    required this.tier,
    required this.color,
    required this.icon,
  });

  bool get isFree => price == 0;
}

class Session {
  final String id;
  final String title;
  final String tutorName;
  final String subject;
  final SessionType type;
  final DateTime dateTime;
  final int durationMinutes;
  final int participants;
  final SessionStatus status;
  final double price;

  const Session({
    required this.id,
    required this.title,
    required this.tutorName,
    required this.subject,
    required this.type,
    required this.dateTime,
    required this.durationMinutes,
    required this.participants,
    required this.status,
    required this.price,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  final String? attachmentName;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.attachmentName,
  });
}

class ChatThread {
  final String id;
  final String name;
  final String subtitle;
  final Color color;
  final bool online;
  final List<ChatMessage> messages;
  int unread;

  ChatThread({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.messages,
    this.online = false,
    this.unread = 0,
  });
}

class PaymentTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isCredit;
  final String method;

  const PaymentTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isCredit,
    required this.method,
  });
}

/// A course / session a tutor submits to mentors for approval.
class Submission {
  final String id;
  final String title;
  final String tutorName;
  final String subject;
  final CourseType type;
  final double price;
  final String description;
  final List<String> lessonTitles;
  final AgeTier tier;
  final DateTime submittedAt;
  ReviewStatus status;
  String? feedback;

  Submission({
    required this.id,
    required this.title,
    required this.tutorName,
    required this.subject,
    required this.type,
    required this.price,
    required this.description,
    required this.lessonTitles,
    required this.tier,
    required this.submittedAt,
    this.status = ReviewStatus.pending,
    this.feedback,
  });
}

class AppNotification {
  final String title;
  final String body;
  final IconData icon;
  final DateTime time;
  bool read;

  AppNotification({
    required this.title,
    required this.body,
    required this.icon,
    required this.time,
    this.read = false,
  });
}
