
import 'package:flutter/material.dart';
import 'pages/PortfolioPage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() {
  databaseFactory = databaseFactoryFfi;

  runApp( MaterialApp(
    builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    debugShowCheckedModeBanner: false,
    home:const PortfolioPage(),
    )
  );
}
