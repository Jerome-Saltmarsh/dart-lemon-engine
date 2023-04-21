## Getting Started
```
// main.dart

import 'package:flutter/material.dart';
import 'package:lemon_engine/lemon_engine.dart';

void main() {
  
  var circleX = 0.0;
  var circleY = 100.0;
  
  Engine.run(
      init: (sharedPreferences) {
          // load assets etc
      },
      update: () {
         circleX++;
         if (Engine.keyPressed(KeyCode.Arrow_Down)) {
           circleY += 1;
         }
      },
      render: (Canvas canvas, Size size) {
        canvas.drawCircle(Offset(circleX, circleY), 100, Engine.paint);
      },
      buildUI: (BuildContext context){
         return Stack(
            children: [
              Positioned(
                  bottom: 16,
                  right: 16,
                  child: Engine.buildOnPressed(
                      child: const Text("RESET",
                        style: TextStyle(color: Colors.white70, fontSize: 60),
                      ),
                      action: () => circleX = 0,
                  )),
            ],
         );
      }
  );
}

```


