import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

import 'map_screen.dart';

class MapLoadingScreen extends StatefulWidget {
  // 로드할 맵 이름 필요
  final String mapName;
  const MapLoadingScreen({Key? key, required this.mapName}) : super(key: key);

  @override
  State<MapLoadingScreen> createState() => _MapLoadingScreen();
}

class _MapLoadingScreen extends State<MapLoadingScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getMapData(widget.mapName),
      builder: (context, snapshot) {
        // 로딩 완료
        if (snapshot.connectionState == ConnectionState.done) {
          // 데이터 정상 로드 후 맵 페이지 활성화
          if (snapshot.hasData) {
              return MapScreen(mapData: snapshot.data!);
            }
          // 데이터 로드 오류
          else {
            throw Error();
          }
        }
        // 로딩 중
        else {
          debugPrint("Waiting...");
          return const Loading();
        }
      },
    );
  }

  Future<Map<String, dynamic>> _getMapData(String fileName) async {
    debugPrint("Reading MAP : $fileName");
    final input = await rootBundle.loadString('assets/data/maps/$fileName.json');
    var map = jsonDecode(input);
    return map;
  }
}

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    // 로딩 화면
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '맵 로딩중...',
            ),
          ],
        ),
      )
    );
  }
}
