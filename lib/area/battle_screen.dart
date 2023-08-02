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
    debugPrint("전투 페이지 로드됨 :${locationData['infoJsonFile']}");

    // battle 화면 정보
    return Scaffold(
      appBar: AppBar(
        title: Text("전투 화면")
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
              child: Container(
                color: Colors.lightGreen,
              )
          ),
          Expanded(
            flex: 1,
              child: Column(
                children: [
                  // 첫번째 위 영역
                  Expanded(
                    flex: 1,
                    child: Stack(
                      children: [
                        // 4개의 원형 버튼
                        Positioned(
                          left: 0,
                          top: 50,
                          child: FloatingActionButton(
                            onPressed: () {},
                            backgroundColor: Colors.red,
                          ),
                        ),
                        Positioned(
                          left: 50,
                          top: 0,
                          child: FloatingActionButton(
                            onPressed: () {},
                            backgroundColor: Colors.orange,
                          ),
                        ),
                        Positioned(
                          right: 50,
                          top: 0,
                          child: FloatingActionButton(
                            onPressed: () {},
                            backgroundColor: Colors.yellow,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 50,
                          child: FloatingActionButton(
                            onPressed: () {},
                            backgroundColor: Colors.green,
                          ),
                        ),
                        // 정가운데 타원 모양의 정사각형 버튼
                        Center(
                          child: Container(
                            width: 50,
                            height: 100,
                            child: Container(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 두번째 밑 영역
                  Expanded(
                    flex: 1,
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(4, (index) {
                        return Center(
                          child: Container(
                            color: Colors.red,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              )
          )
        ],
      )
    );
  }
}