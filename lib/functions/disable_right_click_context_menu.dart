
import 'package:universal_html/html.dart';

void disableRightClickContextMenu() {
  document.onContextMenu.listen((event) => event.preventDefault());
}
