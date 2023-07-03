import 'package:flutter/material.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  // 현재 페이지 위치
  double _x = 0.0;
  double _y = 0.0;

  // 페이지 최대 크기
  double maxX = 2000;
  double maxY = 300;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("X = $_x Y + $_y");  // 위치 로그 표시
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // 위치 갱신
          _x = max(-maxX, min(0, _x+details.delta.dx));
          _y = max(-maxY, min(maxY, _y+details.delta.dy));
        });
      },
      child: Stack(
        children: [
          Positioned(
            // 드래그 가능한 맵
              left: _x,
              top: _y,
              child: Container(
                // 전체 맵 크기
                width: 1000,
                height: 750,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/testMap.png'),
                    fit: BoxFit.cover,
                  )
                ),
                child: Stack(
                  children: [
                    Positioned(
                      // 디버그용 전투 구역
                      top: 50.0,
                      left: 100.0,
                      child: GestureDetector(
                        onTap: () {
                          // 전투구역 터치 테스트
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
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 400,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        )
                      ),

                    );
                  },
              );
            },
          )
        ],
      ),
    );
  }
}