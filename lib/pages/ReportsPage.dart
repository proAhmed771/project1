import 'package:flutter/material.dart';
import 'package:toprepare/pages/PortfolioPage.dart';
import '../database.dart';
import '../models.dart';
import 'report_details_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final SqlDB _sqlDB = SqlDB();
  List<Portfolio> _portfolios = [];
  int selectpage =1;
  @override
  void initState() {
    super.initState();
    _fetchPortfolios();
  }

  Future<void> _fetchPortfolios() async {
    List<Portfolio> list = await _sqlDB.getPortfolios();
    setState(() {
      _portfolios = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تقارير المحافظ"),
      ),
      body: _portfolios.isEmpty
          ? const Center(child: Text("لا توجد محافظ"))
          : ListView.builder(
              itemCount: _portfolios.length,
              itemBuilder: (context, index) {
                Portfolio portfolio = _portfolios[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(portfolio.courseName),
                    subtitle: Text("التخصص: ${portfolio.specialization}\nالمجموعة: ${portfolio.groupName}"),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailsPage(portfolio: portfolio),
                        ),
                      );
                    },
                  ),
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
