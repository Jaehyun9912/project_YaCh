import 'package:flutter/material.dart';
import 'dart:math';

class InteractScreen extends StatefulWidget {
  final String pointData = "";
  const InteractScreen({Key? key}) : super(key: key);
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
    debugPrint("");  // 로그 표시
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