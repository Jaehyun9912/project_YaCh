import 'package:flutter/material.dart';

class InteractScreen extends StatefulWidget {
  // 맵 정보 데이터 필요
  final Map<String, dynamic> locationData;
  const InteractScreen({Key? key, required this.locationData}) : super(key: key);

  @override
  State<InteractScreen> createState() => _InteractScreenState();
}

class _InteractScreenState extends State<InteractScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // locationData 가져오기
    final Map<String, dynamic> locationData = widget.locationData;
    debugPrint("상호작용 페이지 로드됨 :" + locationData['title']);

    // interact 화면 정보
    return Column(
      children: [
        // 위쪽 이미지 화면
        Expanded(
            child: Container(
              color: Colors.blue,
            ),
        ),
        // 밑쪽 버튼 화면
        Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {debugPrint("1번 버튼 눌림");},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 0)),
                    child: const Text("Button 1"),
                  ),
                  ElevatedButton(
                    onPressed: () {debugPrint("2번 버튼 눌림");},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 0)),
                    child: const Text("Button 2"),
                  ),
                  ElevatedButton(
                    onPressed: () {debugPrint("3번 버튼 눌림");},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 0)),
                    child: const Text("Button 3"),
                  ),
                ]
            )
          )
        )
      ],
    );
  }
}