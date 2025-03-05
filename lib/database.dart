import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';
 

class SqlDB {


  static Database? _db;
  Future<Database?> get db async {
    if (_db == null){
      _db = await intialDb();
      return _db;
    } else {
      return _db;
    }
  } 
Future<Database>  intialDb() async {
    String databasepath = await getDatabasesPath();
    String path = join(databasepath,"absence_file_db.db");
    Database mydb = await openDatabase(path,onCreate: _onCreate , version: 1);
    return mydb;
  }


  Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE portfolios(
      portfolioID INTEGER PRIMARY KEY AUTOINCREMENT,
      specialization TEXT NOT NULL,
      groupName TEXT NOT NULL,
      courseName TEXT NOT NULL,
      totalLectures INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE registrations(
      registrationID INTEGER PRIMARY KEY AUTOINCREMENT,
      portfolioID INTEGER,
      studentName  TEXT NOT NULL,
      FOREIGN KEY(portfolioID) REFERENCES portfolios(portfolioID) ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE attendance(
      attendanceID INTEGER PRIMARY KEY AUTOINCREMENT,
      registrationID INTEGER,
      lectureDate INTEGER NOT NULL,
      status TEXT NOT NULL,
      FOREIGN KEY(registrationID) REFERENCES registrations(registrationID) ON DELETE CASCADE
    )
  ''');
}
 Future<int> insertPortfolio(Portfolio portfolio) async {
    Database? mydb =  await db;
    print("intert bbb =============================");
    return await mydb!.insert('portfolios', portfolio.toMap());
  }
  Future<int> insertRegistration(Registration registration) async {
    Database? mydb = await db;
    return await mydb!.insert('registrations', registration.toMap());
  }
  
  
  // إضافة حضور
  Future<int> insertAttendance(Attendance attendance) async {
    Database? mydb = await db;
    return await mydb!.insert('attendance', attendance.toMap());
  }

  
  // جلب جميع الحافظات
  Future<List<Portfolio>> getPortfolios() async {
    Database? mydb = await db;
    List<Map<String, dynamic>> maps = await mydb!.query('portfolios');
    return List.generate(maps.length, (i) {
      return Portfolio(
        portfolioID: maps[i]['portfolioID'],
        specialization: maps[i]['specialization'],
        groupName: maps[i]['groupName'],
        courseName: maps[i]['courseName'],
        totalLectures: maps[i]['totalLectures'],
      );
    });
  }

  
  // جلب حضور طالب معين
  Future<List<Attendance>> getAttendance(int registrationID) async {
    Database? mydb = await db;
    List<Map<String, dynamic>> maps = await mydb!.query(
      'attendance',
      where: 'registrationID = ?',
      whereArgs: [registrationID],
    );
    return List.generate(maps.length, (i) {
      return Attendance(
        attendanceID: maps[i]['attendanceID'],
        registrationID: maps[i]['registrationID'],
        lectureDate: maps[i]['lectureDate'],
        status: maps[i]['status'],
      );
    });
  }
// تعديل Portfolio
Future<int> updatePortfolio(Portfolio portfolio) async {
  Database? mydb = await db;
  return await mydb!.update(
    'portfolios',
    portfolio.toMap(),
    where: 'portfolioID = ?',
    whereArgs: [portfolio.portfolioID],
  );
}

// تعديل Registration
Future<int> updateRegistration(Registration registration) async {
  Database? mydb = await db;
  return await mydb!.update(
    'registrations',
    registration.toMap(),
    where: 'registrationID = ?',
    whereArgs: [registration.registrationID],
  );
}

// تعديل Attendance
Future<int> updateAttendance(Attendance attendance) async {
  Database? mydb = await db;
  return await mydb!.update(
    'attendance',
    attendance.toMap(),
    where: 'attendanceID = ?',
    whereArgs: [attendance.attendanceID],
  );
}

// حذف Portfolio
Future<int> deletePortfolio(int portfolioID) async {
  Database? mydb = await db;
  return await mydb!.delete(
    'portfolios',
    where: 'portfolioID = ?',
    whereArgs: [portfolioID],
  );
}

// حذف Registration
Future<int> deleteRegistration(int registrationID) async {
  Database? mydb = await db;
  return await mydb!.delete(
    'registrations',
    where: 'registrationID = ?',
    whereArgs: [registrationID],
  );
}

// حذف Attendance
Future<int> deleteAttendance(int attendanceID) async {
  Database? mydb = await db;
  return await mydb!.delete(
    'attendance',
    where: 'attendanceID = ?',
    whereArgs: [attendanceID],
  );
}

Future<List<Registration>> getRegistrationsByPortfolio(int portfolioID) async {
  Database? mydb = await db;
  List<Map<String, dynamic>> maps = await mydb!.query(
    'registrations',
    where: 'portfolioID = ?',
    whereArgs: [portfolioID],
  );
  return List.generate(maps.length, (i) {
    return Registration(
      registrationID: maps[i]['registrationID'],
      portfolioID: maps[i]['portfolioID'],
      studentName: maps[i]['studentName'],
    );
  });
}

Future<int> getAttendanceCount(int registrationID, String status) async {
  Database? mydb = await db;
  var result = await mydb!.rawQuery(
    'SELECT COUNT(*) as count FROM attendance WHERE registrationID = ? AND status = ?',
    [registrationID, status],
  );
  return Sqflite.firstIntValue(result) ?? 0;
}


}

