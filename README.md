## Getting Started
```
// main.dart

import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';

void main() {
    Engine.run(
        title: "My Amazing Game",
        update: () {
           // game loop logic
        },
        render: (Canvas canvas, Size size){
           // render loop 
        },
        buildUI: (BuildContext context){
            return Stack(
                children: const [
                  Positioned(
                      top: 16,
                      left: 16,
                      child: Text("Hello World")),
                ],
             );
        }
    );
}
```


