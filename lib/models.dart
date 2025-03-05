class Portfolio {
  final int? portfolioID;
  final String specialization;
  final String groupName;
  final String courseName;
  final int totalLectures;

  Portfolio({
    this.portfolioID,
    required this.specialization,
    required this.groupName,
    required this.courseName,
    required this.totalLectures,
  });

  Map<String, dynamic> toMap() {
    return {
      'portfolioID': portfolioID,
      'specialization': specialization,
      'groupName': groupName,
      'courseName': courseName,
      'totalLectures': totalLectures,
    };
  }
}



class Registration {
  final int? registrationID;
  final int portfolioID;
  final String studentName;

  Registration({
    this.registrationID,
    required this.portfolioID,
    required this.studentName,
  });

  Map<String, dynamic> toMap() {
    return {
      'registrationID': registrationID,
      'portfolioID': portfolioID,
      'studentName': studentName,
    };
  }
}





class Attendance {
  final int? attendanceID;
  final int registrationID;
  final String lectureDate;
  final String status;

  Attendance({
    this.attendanceID,
    required this.registrationID,
    required this.lectureDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'attendanceID': attendanceID,
      'registrationID': registrationID,
      'lectureDate': lectureDate,
      'status': status,
    };
  }
}