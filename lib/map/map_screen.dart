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
  double max_y = 1000;

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
          _x = max(-max_x, min(max_x, _x+details.delta.dx));
          _y = max(-max_y, min(max_y, _y+details.delta.dy));
        });
      },
      child: Stack(
        children: [
          Positioned(
              left: _x,
              top: _y,
              child: Container(
                width: MediaQuery.of(context).size.width * 3,
                height: MediaQuery.of(context).size.height * 3,
                decoration: const BoxDecoration(
                  color: Colors.orange
                ),
                /*decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/map.png'),
                    fit: BoxFit.cover,
                  )
                ),*/
              )
          )
        ],
      ),
    );
  }
}