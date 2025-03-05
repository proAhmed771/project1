import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // لاستخدام DateFormat
import 'package:toprepare/pages/ReportsPage.dart';
import '../database.dart';
import '../models.dart';

class AttendancePage extends StatefulWidget {
  final Portfolio portfolio;
  const AttendancePage({Key? key, required this.portfolio}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final SqlDB _sqlDB = SqlDB();
  int selectpage =0;
  List<Registration> _registrations = [];
  List<Registration> _filteredRegistrations = []; // قائمة الطلاب المصفاة
  String _searchQuery = ""; // نص البحث

  // خريطة الحالة اليومية لكل طالب: المفتاح: registrationID، القيمة: الحالة (حاضر، غياب، مستأذن أو "")
  Map<int, String> _dailyStatusMap = {};

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  // جلب قائمة الطلاب ثم حالة كل طالب لليوم
  Future<void> _fetchRegistrations() async {
    List<Registration> list = await _sqlDB.getRegistrationsByPortfolio(widget.portfolio.portfolioID!);
    setState(() {
      _registrations = list;
      _filteredRegistrations = list; // تهيئة القائمة المصفاة
    });

    // بعد جلب الطلاب، نجلب حالة كل طالب لهذا اليوم
    for (var reg in list) {
      String status = await _getTodayStatus(reg.registrationID!);
      setState(() {
        _dailyStatusMap[reg.registrationID!] = status;
      });
    }
  }

  /// استرجاع الحالة المسجلة لهذا الطالب في اليوم الحالي؛ إن لم توجد تُعيد ""
  Future<String> _getTodayStatus(int registrationID) async {
    final db = await _sqlDB.db;
    String todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> result = await db!.query(
      'attendance',
      where: 'registrationID = ? AND lectureDate LIKE ?',
      whereArgs: [registrationID, '$todayString%'],
    );
    if (result.isNotEmpty) {
      return result[0]['status'] as String;
    } else {
      return "";
    }
  }

  /// عند اختيار حالة جديدة من الراديو، نقوم بتسجيلها أو تحديثها في قاعدة البيانات
  Future<void> _recordAttendance(int registrationID, String status) async {
    String nowString = DateTime.now().toIso8601String();
    Attendance? existingAttendance = await _getTodayAttendance(registrationID);
    if (existingAttendance == null) {
      await _sqlDB.insertAttendance(Attendance(
        registrationID: registrationID,
        lectureDate: nowString,
        status: status,
      ));
    } else {
      Attendance updated = Attendance(
        attendanceID: existingAttendance.attendanceID,
        registrationID: existingAttendance.registrationID,
        lectureDate: existingAttendance.lectureDate,
        status: status,
      );
      await _sqlDB.updateAttendance(updated);
    }
  }

  /// استرجاع سجل الحضور لهذا الطالب في اليوم الحالي إن وجد
  Future<Attendance?> _getTodayAttendance(int registrationID) async {
    final db = await _sqlDB.db;
    String todayString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    List<Map<String, dynamic>> result = await db!.query(
      'attendance',
      where: 'registrationID = ? AND lectureDate LIKE ?',
      whereArgs: [registrationID, '$todayString%'],
    );
    if (result.isNotEmpty) {
      return Attendance(
        attendanceID: result[0]['attendanceID'],
        registrationID: result[0]['registrationID'],
        lectureDate: result[0]['lectureDate'],
        status: result[0]['status'],
      );
    }
    return null;
  }

  // دالة لإضافة أو تعديل بيانات الطالب
  void _showRegistrationDialog({Registration? registration}) {
    final TextEditingController nameController = TextEditingController(text: registration?.studentName ?? "");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(registration == null ? "إضافة طالب" : "تعديل بيانات الطالب"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "اسم الطالب",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                if (name.isEmpty) return;
                if (registration == null) {
                  Registration newReg = Registration(
                    portfolioID: widget.portfolio.portfolioID!,
                    studentName: name,
                  );
                  await _sqlDB.insertRegistration(newReg);
                } else {
                  Registration updated = Registration(
                    registrationID: registration.registrationID,
                    portfolioID: registration.portfolioID,
                    studentName: name,
                  );
                  await _sqlDB.updateRegistration(updated);
                }
                await _fetchRegistrations();
                Navigator.pop(context);
              },
              child: Text(registration == null ? "إضافة" : "تعديل"),
            ),
          ],
        );
      },
    );
  }

  // حذف سجل الطالب
  Future<void> _deleteRegistration(int registrationID) async {
    await _sqlDB.deleteRegistration(registrationID);
    await _fetchRegistrations();
  }

  // تصفية الطلاب بناءً على نص البحث
  void _filterRegistrations(String query) {
    setState(() {
      _searchQuery = query;
      _filteredRegistrations = _registrations.where((reg) {
        return reg.studentName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("حضور ${widget.portfolio.courseName}"),
      ),
      body: Column(
        children: [
          // شريط البحث مع تباعد جيد وحدود أنيقة
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "ابحث عن طالب...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: _filterRegistrations,
            ),
          ),
          // قائمة الطلاب
          Expanded(
            child: _filteredRegistrations.isEmpty
                ? const Center(child: Text("لا يوجد طلاب مسجلين", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: _filteredRegistrations.length,
                    itemBuilder: (context, index) {
                      Registration reg = _filteredRegistrations[index];
                      String currentStatus = _dailyStatusMap[reg.registrationID!] ?? "";
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // عرض اسم الطالب بخط عريض وحجم أكبر
                              Text(
                                reg.studentName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              // خيارات الراديو مع فاصل زمني مناسب
                              Column(
                                children: [
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("حاضر", style: TextStyle(fontSize: 16)),
                                    value: "حاضر",
                                    groupValue: currentStatus.isEmpty ? null : currentStatus,
                                    onChanged: (val) async {
                                      if (val == null) return;
                                      setState(() {
                                        _dailyStatusMap[reg.registrationID!] = val;
                                      });
                                      await _recordAttendance(reg.registrationID!, val);
                                    },
                                  ),
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("غياب", style: TextStyle(fontSize: 16)),
                                    value: "غياب",
                                    groupValue: currentStatus.isEmpty ? null : currentStatus,
                                    onChanged: (val) async {
                                      if (val == null) return;
                                      setState(() {
                                        _dailyStatusMap[reg.registrationID!] = val;
                                      });
                                      await _recordAttendance(reg.registrationID!, val);
                                    },
                                  ),
                                  RadioListTile<String>(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text("مستأذن", style: TextStyle(fontSize: 16)),
                                    value: "مستأذن",
                                    groupValue: currentStatus.isEmpty ? null : currentStatus,
                                    onChanged: (val) async {
                                      if (val == null) return;
                                      setState(() {
                                        _dailyStatusMap[reg.registrationID!] = val;
                                      });
                                      await _recordAttendance(reg.registrationID!, val);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // أزرار التعديل والحذف
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  MaterialButton(
                                    color: Colors.blue,
                                    textColor: Colors.white,
                                    onPressed: () {
                                      _showRegistrationDialog(registration: reg);
                                    },
                                    child: const Text("تعديل"),
                                  ),
                                  const SizedBox(width: 8),
                                  MaterialButton(
                                    color: Colors.red,
                                    textColor: Colors.white,
                                    onPressed: () {
                                      _deleteRegistration(reg.registrationID!);
                                    },
                                    child: const Text("حذف"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showRegistrationDialog();
        },
        child: const Icon(Icons.add),
      ),
       bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectpage,
        onTap: (val) {
          if (val == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ReportsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Portfolios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'تقارير',
          ),
        ],
      ),
  
    );
  }
}
