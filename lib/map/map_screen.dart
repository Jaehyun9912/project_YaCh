import 'package:flutter/material.dart';
import 'dart:math';

import '../area/interact_screen.dart';
import '../area/battle_screen.dart';

class MapScreen extends StatefulWidget {
  final Map<String, dynamic> mapData;
  const MapScreen({Key? key, required this.mapData}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  // 현재 페이지 내 정보
  double _x = 0.0;
  double _y = 0.0;
  late final Map<String, dynamic> mapData;

  @override
  void initState() {
    super.initState();
    mapData = widget.mapData;
  }

  @override
  Widget build(BuildContext context) {
    //현재 맵 정보
    final mapName = mapData['mapName'];
    final List<dynamic> locations = mapData['locations'];
    final double maxX = mapData['mapSize']['x'] as double;
    final double maxY = mapData['mapSize']['y'] as double;

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
                  'assets/images/${mapData['mapImage']}',
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
  void _loadLocation(BuildContext context, dynamic locationData) {
    // 타입에 맞춰 페이지 생성
    Widget page;
    switch (locationData['type']) {
      // 상호 작용 지역
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
}
