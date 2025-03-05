import 'package:flutter/material.dart';
import 'package:toprepare/pages/PortfolioPage.dart';
import '../database.dart';
import '../models.dart';

class ReportDetailsPage extends StatefulWidget {
  final Portfolio portfolio;
  const ReportDetailsPage({Key? key, required this.portfolio}) : super(key: key);

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  final SqlDB _sqlDB = SqlDB();
  List<Registration> _registrations = [];
  int selectpage=1;
  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  Future<void> _fetchRegistrations() async {
    List<Registration> list = await _sqlDB.getRegistrationsByPortfolio(widget.portfolio.portfolioID!);
    setState(() {
      _registrations = list;
    });
  }

  Future<int> _getStatusCount(int registrationID, String status) async {
    int count = await _sqlDB.getAttendanceCount(registrationID, status);
    return count;
  }

  Future<Map<String, int>> _fetchAttendanceCounts(int registrationID) async {
    int hadir = await _getStatusCount(registrationID, "حاضر");
    int absent = await _getStatusCount(registrationID, "غياب");
    int excused = await _getStatusCount(registrationID, "مستأذن");
    return {"حاضر": hadir, "غياب": absent, "مستأذن": excused};
  }

  Widget _buildRegistrationReport(Registration reg) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchAttendanceCounts(reg.registrationID!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(reg.studentName),
            subtitle: const Text("جارٍ التحميل..."),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text(reg.studentName),
            subtitle: const Text("حدث خطأ أثناء جلب البيانات"),
          );
        } else {
          Map<String, int> counts = snapshot.data!;
          return ListTile(
            title: Text(reg.studentName),
            subtitle: Text(
              "حضور: ${counts['حاضر'] ?? 0}  |  غياب: ${counts['غياب'] ?? 0}  |  مستأذن: ${counts['مستأذن'] ?? 0}",
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("تقارير ${widget.portfolio.courseName}"),
      ),
      body: _registrations.isEmpty
          ? const Center(child: Text("لا يوجد طلاب مسجلين"))
          : ListView.builder(
              itemCount: _registrations.length,
              itemBuilder: (context, index) {
                Registration reg = _registrations[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: _buildRegistrationReport(reg),
                );
              },
            ),
             bottomNavigationBar: BottomNavigationBar(
        currentIndex:selectpage ,
        onTap: (val){
          setState(() {
          selectpage =val;
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (val)=> PortfolioPage()),(route) => false,);
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Portfolios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'تقارير',
          ),]),

 
    );
  }
}
