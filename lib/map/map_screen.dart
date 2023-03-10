import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);
  @override
  _MapScreen createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  double _x = 0.0;
  double _y = 0.0;

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
          _x += details.delta.dx;
          _y += details.delta.dy;
        });
      },
      child: Stack(
        children: [
          Positioned(
              left: _x,
              top: _y,
              child: Container(
                width: MediaQuery.of(context).size.width * 2,
                height: MediaQuery.of(context).size.height * 2,
                decoration: const BoxDecoration(
                  color: Colors.green
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