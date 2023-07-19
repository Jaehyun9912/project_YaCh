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
    debugPrint("상호작용 페이지 로드됨 :${locationData['title']}");

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
                children: <Widget>[
                  Flexible(
                      flex: 2,
                      child: Container(
                        color: Colors.transparent,
                      )
                  ),
                  Flexible(
                    flex: 3,
                    child: Choice(
                      text: "1번 선택지"
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Container(
                      color: Colors.transparent,
                    )
                  ),
                  Flexible(
                    flex: 3,
                    child: Choice(
                        text: "2번 선택지"
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: Container(
                      color: Colors.transparent,
                    )
                  ),
                  Flexible(
                    flex: 3,
                    child: Choice(
                        text: "3번 선택지"
                    ),
                  ),
                  Flexible(
                      flex: 2,
                      child: Container(
                        color: Colors.transparent,
                      )
                  )
                ]
            )
          )
        )
      ],
    );
  }
}

// 선택지 버튼
class Choice extends StatelessWidget {
  final String text;
  double fontSize;
  Color textColor = Colors.black;
  Color color = Colors.white54;

  Choice({required this.text, this.fontSize = 24, this.color = Colors.white, this.textColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint("${text}Clicked!");
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8)
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}