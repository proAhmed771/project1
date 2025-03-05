import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:toprepare/pages/ReportsPage.dart';
import '../database.dart';
import '../models.dart';
import 'package:toprepare/pages/Attendance.dart';
import 'package:toprepare/pages/SearchBar.dart' as custom; // استيراد SearchBar مع اسم بديل

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  int selectpage = 0;
  final SqlDB _sqlDB = SqlDB();
  List<Portfolio> _portfolios = [];
  List<Portfolio> _filteredPortfolios = [];

  @override
  void initState() {
    super.initState();
    _fetchPortfolios();
  }

  Future<void> _fetchPortfolios() async {
    List<Portfolio> list = await _sqlDB.getPortfolios();
    setState(() {
      _portfolios = list;
      _filteredPortfolios = list;
    });
  }

  void _filterPortfolios(String query) {
    setState(() {
      _filteredPortfolios = _portfolios.where((portfolio) {
        return portfolio.specialization.toLowerCase().contains(query.toLowerCase()) ||
            portfolio.groupName.toLowerCase().contains(query.toLowerCase()) ||
            portfolio.courseName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showPortfolioDialog({Portfolio? portfolio}) {
    final TextEditingController specializationController =
        TextEditingController(text: portfolio?.specialization ?? "");
    final TextEditingController groupNameController =
        TextEditingController(text: portfolio?.groupName ?? "");
    final TextEditingController courseNameController =
        TextEditingController(text: portfolio?.courseName ?? "");
    final TextEditingController totalLecturesController =
        TextEditingController(text: portfolio?.totalLectures.toString() ?? "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            portfolio == null ? "إضافة Portfolio" : "تعديل Portfolio",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: specializationController,
                  decoration: const InputDecoration(
                    labelText: "التخصص",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: "اسم المجموعة",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseNameController,
                  decoration: const InputDecoration(
                    labelText: "اسم الدورة",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalLecturesController,
                  decoration: const InputDecoration(
                    labelText: "إجمالي المحاضرات",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء", style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () async {
                String specialization = specializationController.text.trim();
                String groupName = groupNameController.text.trim();
                String courseName = courseNameController.text.trim();
                int? totalLectures = int.tryParse(totalLecturesController.text.trim());

                if (specialization.isEmpty ||
                    groupName.isEmpty ||
                    courseName.isEmpty ||
                    totalLectures == null) {
                  // يمكن إضافة رسالة تنبيه هنا
                  return;
                }

                if (portfolio == null) {
                  Portfolio newPortfolio = Portfolio(
                    specialization: specialization,
                    groupName: groupName,
                    courseName: courseName,
                    totalLectures: totalLectures,
                  );
                  await _sqlDB.insertPortfolio(newPortfolio);
                } else {
                  Portfolio updated = Portfolio(
                    portfolioID: portfolio.portfolioID,
                    specialization: specialization,
                    groupName: groupName,
                    courseName: courseName,
                    totalLectures: totalLectures,
                  );
                  await _sqlDB.updatePortfolio(updated);
                }
                await _fetchPortfolios();
                Navigator.pop(context);
              },
              child: Text(
                portfolio == null ? "إضافة" : "تعديل",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePortfolio(int portfolioID) async {
    await _sqlDB.deletePortfolio(portfolioID);
    await _fetchPortfolios();
  }

  Future<void> _exportToExcel(Portfolio portfolio) async {
  var excel = Excel.createExcel();
  var sheet = excel['Sheet1'];

  // إضافة عنوان الجدول (الرؤوس)
  sheet.appendRow([
    'اسم الطالب',
    'حضور',
    'غياب',
    'مستأذن'
  ]);

  // جلب قائمة الطلاب المسجلين في المحفظة
  List<Registration> registrations = await _sqlDB.getRegistrationsByPortfolio(portfolio.portfolioID!);

  // لكل طالب، نحسب عدد أيام الحضور والغياب والمستأذن
  for (var reg in registrations) {
    int hadir = await _sqlDB.getAttendanceCount(reg.registrationID!, "حاضر");
    int absent = await _sqlDB.getAttendanceCount(reg.registrationID!, "غياب");
    int excused = await _sqlDB.getAttendanceCount(reg.registrationID!, "مستأذن");

    // إضافة صف للطالب
    sheet.appendRow([
      reg.studentName,
      hadir.toString(),
      absent.toString(),
      excused.toString(),
    ]);
  }

  // الحصول على مسار المجلد الخاص بالمستندات
  Directory directory = await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/${portfolio.groupName}_report.xlsx';

  // حفظ الملف في المسار المحدد
  File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(excel.encode()!);

  // إشعار المستخدم بنجاح حفظ التقرير
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text("تم حفظ التقرير بنجاح في: $filePath"),
      backgroundColor: Colors.green,
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("حافظات الحضور والغياب", style: TextStyle(fontSize: 20)),
      ),
      body: Column(
        children: [
          // شريط البحث مع تحسين التصميم
          custom.SearchBar(
            hintText: "ابحث عن حافظة...",
            onChanged: _filterPortfolios,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _filteredPortfolios.isEmpty
                  ? const Center(child: Text("لا توجد محافظ", style: TextStyle(fontSize: 18)))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _filteredPortfolios.length,
                      itemBuilder: (context, index) {
                        Portfolio portfolio = _filteredPortfolios[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AttendancePage(portfolio: portfolio),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "التخصص: ${portfolio.specialization}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "المجموعة: ${portfolio.groupName}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "الدورة: ${portfolio.courseName}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "المحاضرات: ${portfolio.totalLectures}",
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _showPortfolioDialog(portfolio: portfolio);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _deletePortfolio(portfolio.portfolioID!);
                                        },
                                      ),
                                      MaterialButton(
                                        color: Colors.green,
                                        textColor: Colors.white,
                                        onPressed: () {
                                          _exportToExcel(portfolio);
                                        },
                                        child: const Text("تصدير", style: TextStyle(fontSize: 14)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showPortfolioDialog();
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
