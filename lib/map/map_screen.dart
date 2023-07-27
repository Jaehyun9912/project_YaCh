import 'dart:io';

import 'package:flutter/material.dart';
import 'package:project_yach/area/battle_screen.dart';
import 'dart:math';
import 'dart:convert';

import '../area/interact_screen.dart';

//////////////////////////// TEST JSON//////////
const String mapJsonData = '''
{
  "mapName": "StartWorld",
  "mapSize": {"x":2000.0,"y":800.0},
  "locations": [
    {
      "id": 1,
      "position": {"x": 50.0, "y": 100.0},
      "type": "interact",
      "infoJsonFile": "location1.json"
    },
    {
      "id": 2,
      "position": {"x": 150.0, "y": 250.0},
      "type": "battle",
      "infoJsonFile": "location2.json"
    }
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
    final jsonData = jsonDecode(mapJsonData);

    //현재 맵 정보
    final mapName = jsonData['mapName'];
    final List<dynamic> locations = jsonData['locations'];
    final double maxX = jsonData['mapSize']['x'] as double;
    final double maxY = jsonData['mapSize']['y'] as double;

    debugPrint("X = $_x Y + $_y"); // 위치 로그 표시

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // 위치 갱신
          _x = max(-maxX, min(0, _x + details.delta.dx));
          _y = max(-maxY, min(maxY, _y + details.delta.dy));
        });
      },
      child: Stack(
        children: [
          Positioned(
              top: _y,
              left: _x,
              child: Image.asset(
                  'assets/images/testMap.png',
                width: maxX,
                height: maxY,
                fit: BoxFit.contain,
              )
          ),
          ...locations.map((location) {
            return Positioned(
                left: location['position']['x'] + _x,
                top: location['position']['y'] + _y,
                child: GestureDetector(
                  onTap: () {
                    _loadLocation(context, location);
                  },
                  child: const Icon(
                    Icons.add_business,
                    color: Colors.red,
                    size: 50,
                  ),
                )
              );
            }
          ).toList(),
        ],
      ),
    );
  }

  // 지역 페이지 로드
  void _loadLocation(BuildContext context, Map<String, dynamic> location) {
    // 지역 데이터 json 불러오기
    final locationData = _getLocationData(location['infoJsonFile']);

    // 타입에 맞춰 페이지 생성
    Widget page;
    switch (location['type']) {
      // 상호작용 지역
      case 'interact':
        page = InteractScreen(locationData: locationData);
        break;
      // 전투 지역
      case 'battle':
        page = BattleScreen(locationData: locationData);
        break;
      // 디폴트 페이지
      default:
        page = Container();
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  Future<Map<String, dynamic>> _getLocationData(String fileName) async {
    var input = await File(fileName).readAsString();
    var map = jsonDecode(input);
    return {'title': 'Location Info', 'description': 'This is Location'};
  }
}
