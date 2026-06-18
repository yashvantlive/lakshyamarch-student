class OnlinePaper {
  final String paperId;
  final String title;
  final String category;
  final String grade;
  final String subject;
  final int duration;
  final int totalQuestions;
  final String jsonPath;

  OnlinePaper({
    required this.paperId,
    required this.title,
    required this.category,
    required this.grade,
    required this.subject,
    required this.duration,
    required this.totalQuestions,
    required this.jsonPath,
  });

  factory OnlinePaper.fromJson(Map<String, dynamic> json) {
    return OnlinePaper(
      paperId: json['paperId'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      grade: (json['grade'] ?? '').toString(),
      subject: json['subject'] ?? '',
      duration: json['duration'] is int ? json['duration'] : int.parse((json['duration'] ?? '30').toString()),
      totalQuestions: json['totalQuestions'] is int ? json['totalQuestions'] : int.parse((json['totalQuestions'] ?? '0').toString()),
      jsonPath: json['jsonPath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'title': title,
        'category': category,
        'grade': grade,
        'subject': subject,
        'duration': duration,
        'totalQuestions': totalQuestions,
        'jsonPath': jsonPath,
      };
}

class OnlineQuestion {
  final int questionId;
  final String id;
  final String type; // 'MCQ' or 'NUMERICAL'
  final String imagePath;
  final dynamic correctAnswer;

  OnlineQuestion({
    required this.questionId,
    required this.id,
    required this.type,
    required this.imagePath,
    required this.correctAnswer,
  });

  factory OnlineQuestion.fromJson(Map<String, dynamic> json) {
    return OnlineQuestion(
      questionId: json['questionId'] is int ? json['questionId'] : int.parse((json['questionId'] ?? '0').toString()),
      id: (json['id'] ?? '').toString(),
      type: json['type'] ?? 'MCQ',
      imagePath: json['imagePath'] ?? '',
      correctAnswer: json['correctAnswer'],
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'id': id,
        'type': type,
        'imagePath': imagePath,
        'correctAnswer': correctAnswer,
      };
}

class OnlinePaperDetail {
  final String paperId;
  final String title;
  final String category;
  final String grade;
  final String subject;
  final int duration;
  final int totalQuestions;
  final List<OnlineQuestion> questions;

  OnlinePaperDetail({
    required this.paperId,
    required this.title,
    required this.category,
    required this.grade,
    required this.subject,
    required this.duration,
    required this.totalQuestions,
    required this.questions,
  });

  factory OnlinePaperDetail.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List? ?? [];
    List<OnlineQuestion> parsedQuestions = questionsList.map((q) => OnlineQuestion.fromJson(Map<String, dynamic>.from(q as Map))).toList();

    return OnlinePaperDetail(
      paperId: json['paperId'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      grade: (json['grade'] ?? '').toString(),
      subject: json['subject'] ?? '',
      duration: json['duration'] is int ? json['duration'] : int.parse((json['duration'] ?? '30').toString()),
      totalQuestions: json['totalQuestions'] is int ? json['totalQuestions'] : int.parse((json['totalQuestions'] ?? '0').toString()),
      questions: parsedQuestions,
    );
  }

  Map<String, dynamic> toJson() => {
        'paperId': paperId,
        'title': title,
        'category': category,
        'grade': grade,
        'subject': subject,
        'duration': duration,
        'totalQuestions': totalQuestions,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}
