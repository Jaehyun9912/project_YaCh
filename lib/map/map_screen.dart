import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';

import '../area/interact_screen.dart';

//////////////////////////// TEST JSON//////////
const String mapJsonData = '''
{
  "mapName": "StartWorld",
  "mapSize": {"x":2000,"y":300},
  "locations": [
    {
      "id": 1,
      "position": {"x": 50, "y": 100},
      "type": "interact",
      "infoJsonFile": "location1.json"
    },
    {
      "id": 2,
      "position": {"x": 150, "y": 250},
      "type": "battle",
      "infoJsonFile": "location2.json"
    },
  ]
}
''';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  // 현재 페이지 위치
  double _x = 0.0;
  double _y = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 맵 json 파일
    final jsonData =jsonDecode(mapJsonData);

    //현재 맵 정보
    final mapName = jsonData['mapName'];
    final locations = jsonData['locations'];
    final double maxX = jsonData['mapSize']['x'];
    final double maxY = jsonData['mapSize']['y'];

    debugPrint("X = $_x Y + $_y");  // 위치 로그 표시
    
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // 위치 갱신
          _x = max(-maxX, min(0, _x+details.delta.dx));
          _y = max(-maxY, min(maxY, _y+details.delta.dy));
        });
      },
      child: Positioned(
        left: _x,
        top: _y,
        child: Stack(
          children: [
            Image.asset('assets.images/testMap.png'),
            Positioned(
              // 디버그용 전투 구역
              top: 50.0,
              left: 100.0,
              child: GestureDetector(
                onTap: () {
                  // 상호작용 구역 터치 테스트
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>const InteractScreen()));
                  debugPrint("Position 1 clicked! 50, 100");
                },
                child: Container(
                  // 전투구역 아이콘
                  width: 30.0,
                  height: 30.0,
                  color: Colors.red,
                ),
              ),
            ),
            Positioned(
              // 디버그용 길드 구역
              top: 150.0,
              left: 250.0,
              child: GestureDetector(
                onTap: () {
                  // 길드구역 터치 테스트
                  debugPrint("Position 2 clicked! 150, 250");
                },
                child: Container(
                  // 길드구역 아이콘
                  width: 30.0,
                  height: 30.0,
                  color: Colors.red,
                ),
              ),
            )
          ],
        ),
      )
    );
  }
}