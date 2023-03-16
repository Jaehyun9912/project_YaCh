import 'package:flutter/material.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  _MapScreen createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  double _x = 0.0;
  double _y = 0.0;

  double max_x = 500;
  double max_y = 300;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("X = $_x Y + $_y");
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _x = max(-max_x, min(0, _x+details.delta.dx));
          _y = max(-max_y, min(max_y, _y+details.delta.dy));
        });
      },
      child: Stack(
        children: [
          Positioned(
              left: _x,
              top: _y,
              child: Container(
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
                      top: 50.0,
                      left: 100.0,
                      child: GestureDetector(
                        onTap: () {
                          debugPrint("Position 1 clicked! 50, 100");
                        },
                        child: Container(
                          width: 30.0,
                          height: 30.0,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 150.0,
                      left: 250.0,
                      child: GestureDetector(
                        onTap: () {
                          debugPrint("Position 2 clicked! 150, 250");
                        },
                        child: Container(
                          width: 30.0,
                          height: 30.0,
                          color: Colors.red,
                        ),
                      ),
                    )
                  ],
                ),
              )
          )
        ],
      ),
    );
  }
}