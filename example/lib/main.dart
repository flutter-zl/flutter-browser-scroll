// https://github.com/flutter/flutter/issues/175892

import 'package:flutter/material.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';

void main() {
  runWidget(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return View(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BrowserScroller(
        scrollerApi: JsViewScroller(View.of(context).viewId),
        child: const DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontFamily: 'Roboto',
          ),
          child: LongContent(),
        ),
      ),
    );
  }
}

class LongContent extends StatelessWidget {
  const LongContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ...List<Widget>.generate(30, (int index) => Text(index.toString())),
        ElevatedButton(
          onPressed: () {
            debugPrint('clicked');
          },
          child: const Text('Click me'),
        ),
        ...List<Widget>.generate(50, (int index) => Text(index.toString())),
      ],
    );
  }
}
