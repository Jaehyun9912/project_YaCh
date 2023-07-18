import 'package:flutter/material.dart';

class BattleScreen extends StatefulWidget {
  // 맵 정보 데이터
  final Map<String, dynamic> locationData;
  const BattleScreen({Key? key, required this.locationData}) : super(key: key);

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  @override
  Widget build(BuildContext context) {
    // locationData 가져오기
    final Map<String, dynamic> locationData = widget.locationData;
    debugPrint("전투 페이지 로드됨 :" + locationData['title']);

    // battle 화면 정보
    return Scaffold(
      appBar: AppBar(
        title: Text(locationData['title'])
      ),
    );
  }
}