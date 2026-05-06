import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/semantics.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';

void main() {
  registerPlatformViews();
  runApp(const MyApp(useBrowserScroller: true));
  SemanticsBinding.instance.ensureSemantics();
}

void registerPlatformViews() {
  ui_web.platformViewRegistry.registerViewFactory('youtube-iframe', (
    int viewId,
  ) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = 'https://www.youtube.com/embed/aqz-KE-bpKQ';
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.allow =
        'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture';
    iframe.setAttribute('allowfullscreen', 'true');
    return iframe;
  });

  ui_web.platformViewRegistry.registerViewFactory('wikipedia-iframe', (
    int viewId,
  ) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = 'https://en.wikipedia.org/wiki/Main_Page';
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    return iframe;
  });

  ui_web.platformViewRegistry.registerViewFactory('scrollable-html-div', (
    int viewId,
  ) {
    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.style.width = '100%';
    container.style.height = '100%';
    container.style.overflow = 'auto';
    container.style.backgroundColor = '#f5f5f5';
    container.style.fontFamily = 'Arial, sans-serif';
    container.style.fontSize = '14px';
    container.style.padding = '16px';
    container.style.boxSizing = 'border-box';

    final title = web.document.createElement('h3') as web.HTMLHeadingElement;
    title.textContent = 'Same-Origin Scrollable HTML';
    title.style.color = '#6200ea';
    title.style.marginTop = '0';
    container.append(title);

    final desc = web.document.createElement('p') as web.HTMLParagraphElement;
    desc.textContent =
        'This is a same-origin <div> with overflow:auto. '
        'It has its own scrollable content. When this div reaches '
        'its scroll boundary, the parent Flutter page should take over.';
    desc.style.color = '#666';
    container.append(desc);

    for (int i = 1; i <= 30; i++) {
      final item = web.document.createElement('div') as web.HTMLDivElement;
      item.style.padding = '12px';
      item.style.margin = '4px 0';
      item.style.backgroundColor = i.isEven ? '#e8eaf6' : '#ffffff';
      item.style.borderRadius = '4px';
      item.style.borderLeft = '3px solid #6200ea';

      final itemTitle = web.document.createElement('strong');
      itemTitle.textContent = 'HTML Item $i';
      item.append(itemTitle);

      final itemText =
          web.document.createElement('p') as web.HTMLParagraphElement;
      itemText.textContent =
          'This is native HTML content inside a scrollable div. '
          'Scroll down to reach the boundary.';
      itemText.style.margin = '4px 0 0 0';
      itemText.style.fontSize = '12px';
      itemText.style.color = '#888';
      item.append(itemText);

      container.append(item);
    }

    return container;
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.useBrowserScroller});

  final bool useBrowserScroller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: useBrowserScroller
          ? 'Browser Scroll - Comprehensive Test (After)'
          : 'Browser Scroll - Comprehensive Test (Before)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ComprehensiveTestPage(useBrowserScroller: useBrowserScroller),
    );
  }
}

class ComprehensiveTestPage extends StatefulWidget {
  const ComprehensiveTestPage({super.key, required this.useBrowserScroller});

  final bool useBrowserScroller;

  @override
  State<ComprehensiveTestPage> createState() => _ComprehensiveTestPageState();
}

class _ComprehensiveTestPageState extends State<ComprehensiveTestPage> {
  final BrowserScrollController _scrollController = BrowserScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String introText = widget.useBrowserScroller
        ? 'This is the AFTER demo. The flutter_browser_scroll package is '
              'applied. The outer page scroll is owned by the browser; '
              'Flutter mirrors the browser scroll position via '
              'BrowserScrollController. Inner Flutter scrollables wrapped '
              'in BrowserScrollChild chain to the parent page when they '
              'reach a boundary, and BrowserScrollChild prevents iOS Safari '
              'from panning the document while Flutter handles an inner '
              'gesture. Compare with the BEFORE demo to see what the '
              'package adds.'
        : 'This is the BEFORE demo. The flutter_browser_scroll package is '
              'NOT applied. The outer page is scrolled by Flutter, not the '
              'browser. Inner Flutter scrollables do not chain to the '
              'parent page when they reach a boundary, and on iOS Safari '
              'touch on an inner list can also pan the document. Compare '
              'with the AFTER demo to see what the package adds.';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.useBrowserScroller
              ? 'Comprehensive Scroll Test (After)'
              : 'Comprehensive Scroll Test (Before)',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: _ScrollFabColumn(
        controller: _scrollController,
        topTag: 'top',
        bottomTag: 'bottom',
      ),
      body: _TestPageBody(
        controller: _scrollController,
        useBrowserScroller: widget.useBrowserScroller,
        intro: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            introText,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable floating action button column for Scroll to Top and Scroll to
/// Bottom. Hero tags are parameterized so multiple pages can coexist in the
/// navigator stack.
class _ScrollFabColumn extends StatelessWidget {
  const _ScrollFabColumn({
    required this.controller,
    required this.topTag,
    required this.bottomTag,
  });

  final ScrollController controller;
  final String topTag;
  final String bottomTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: topTag,
          onPressed: () => controller.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          icon: const Icon(Icons.arrow_upward),
          label: const Text('Scroll to Top'),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          heroTag: bottomTag,
          onPressed: () => controller.animateTo(
            controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          icon: const Icon(Icons.arrow_downward),
          label: const Text('Scroll to Bottom'),
        ),
      ],
    );
  }
}

/// Shared body shown on the home page and on every pushed page. The only
/// variable is the [intro] widget rendered above the test sections, and
/// whether the list is wrapped in BrowserScroller.
class _TestPageBody extends StatefulWidget {
  const _TestPageBody({
    required this.controller,
    required this.intro,
    required this.useBrowserScroller,
  });

  final ScrollController controller;
  final Widget intro;
  final bool useBrowserScroller;

  @override
  State<_TestPageBody> createState() => _TestPageBodyState();
}

class _TestPageBodyState extends State<_TestPageBody> {
  String _dropdownValue = 'Option A';

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      const SizedBox(height: 48),
      widget.intro,
      const SizedBox(height: 24),

      // TEST 1: Inner list (with or without BrowserScrollChild)
      _TestSection(
        number: 1,
        title: widget.useBrowserScroller
            ? 'Inner List with BrowserScrollChild'
            : 'Inner List',
        description: widget.useBrowserScroller
            ? 'An inner Flutter ListView wrapped in BrowserScrollChild. '
                  'Scroll inside it; when it reaches its top or bottom '
                  'edge, the parent page continues scrolling. On iOS '
                  'Safari this wrapper prevents the browser from panning '
                  'the document at the same time as the inner list.'
            : 'An inner Flutter ListView. On mobile browsers, without flutter_browser_scroll, '
                  'scroll stops at the list boundary; the parent page '
                  'does not continue',
        color: Colors.blue,
        status: TestStatus.pending,
        child: SizedBox(
          height: 400,
          child: widget.useBrowserScroller
              ? BrowserScrollChild(
                  child: ListView(
                    primary: false,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      for (int i = 1; i <= 20; i++) _FlutterCard(index: i),
                    ],
                  ),
                )
              : ListView(
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    for (int i = 1; i <= 20; i++) _FlutterCard(index: i),
                  ],
                ),
        ),
      ),

      // TEST 2: Inner list without BrowserScrollChild (after-only comparison)
      if (widget.useBrowserScroller)
        _TestSection(
          number: 2,
          title: 'Inner List without BrowserScrollChild',
          description:
              'The same inner list as TEST 1 but without the wrapper. '
              'On desktop and Android Chrome it still chains correctly. '
              'On iOS Safari the page double-scrolls because the '
              'browser pans the document while Flutter also scrolls '
              'the inner list.',
          color: Colors.indigo,
          child: SizedBox(
            height: 400,
            child: ListView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              children: [for (int i = 1; i <= 20; i++) _FlutterCard(index: i)],
            ),
          ),
        ),

      // TEST 3: Pull-to-refresh at top edge
      _TestSection(
        number: 3,
        title: 'Pull-to-Refresh (RefreshIndicator)',
        description: widget.useBrowserScroller
            ? 'Pull down on this inner list when it is at its top. A '
                  'refresh indicator should appear. Overscroll at the '
                  'top edge is preserved so RefreshIndicator works. At '
                  'the bottom edge, the inner list clamps and the '
                  'browser-owned parent page takes over.'
            : 'Pull down on this inner list when it is at its top. A '
                  'refresh indicator should appear (Flutter handles top-'
                  'edge overscroll natively). At the bottom edge, the '
                  'inner list clamps and stops; without '
                  'flutter_browser_scroll the parent page does not '
                  'continue scrolling.',
        color: Colors.cyan,
        child: _PullToRefreshTest(
          useBrowserScroller: widget.useBrowserScroller,
        ),
      ),

      // TEST 4: Cross-origin iframe (Wikipedia)
      _TestSection(
        number: 4,
        title: 'Cross-Origin Iframe (Wikipedia)',
        description: widget.useBrowserScroller
            ? 'Scroll inside the Wikipedia article. When it reaches its '
                  'bottom, the browser-owned parent page takes over and '
                  'keeps scrolling.'
            : 'Scroll inside the Wikipedia article. Without '
                  'flutter_browser_scroll, the scroll chain does not work',
        color: Colors.orange,
        child: const SizedBox(
          height: 400,
          child: HtmlElementView(viewType: 'wikipedia-iframe'),
        ),
      ),

      // TEST 5: Cross-origin iframe (video embed)
      _TestSection(
        number: 5,
        title: 'Cross-Origin Iframe (Video)',
        description: widget.useBrowserScroller
            ? 'Scroll while pointing at the embedded video, including '
                  'over the iframe itself. The browser-owned page keeps '
                  'scrolling without getting stuck on the embed.'
            : 'Scroll while pointing at the embedded video, including '
                  'over the iframe itself. Without flutter_browser_'
                  'scroll, the page gets stuck on the embed.',
        color: Colors.red,
        child: const SizedBox(
          height: 315,
          child: HtmlElementView(viewType: 'youtube-iframe'),
        ),
      ),

      // TEST 6: Same-origin scrollable div
      _TestSection(
        number: 6,
        title: 'Same-Origin Scrollable HTML',
        description: widget.useBrowserScroller
            ? 'A same-origin HTML div with overflow:auto. Scroll inside '
                  'it; when it reaches its boundary, the browser-owned '
                  'parent page takes over.'
            : 'A same-origin HTML div with overflow:auto. The inner list does not scroll at all',
        color: Colors.deepPurple,
        child: const SizedBox(
          height: 300,
          child: HtmlElementView(viewType: 'scrollable-html-div'),
        ),
      ),

      // TEST 7: Keyboard scroll
      _TestSection(
        number: 7,
        title: 'Keyboard Scroll',
        description: widget.useBrowserScroller
            ? 'Click on the page, then press Page Down, Space, or Arrow '
                  'Down. The browser handles keyboard scrolling on the '
                  'flutter-view element.'
            : 'Click on the page, then press Page Down, Space, or Arrow '
                  'Down. Without flutter_browser_scroll, Flutter handles '
                  'keyboard scroll does not work',
        color: Colors.teal,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _KeyHint(label: 'Page Down'),
                  _KeyHint(label: 'Space'),
                  _KeyHint(label: 'Arrow Down'),
                  _KeyHint(label: 'Home'),
                  _KeyHint(label: 'End'),
                ],
              ),
            ],
          ),
        ),
      ),

      // TEST 8: Overlays & Dialogs
      _TestSection(
        number: 8,
        title: 'Overlays & Dialogs',
        description:
            'Test dialogs, menus, dropdowns, and bottom sheets '
            'inside BrowserScroller. They should position correctly '
            'and not interfere with scroll.',
        color: Colors.purple,
        child: _buildOverlayTests(context),
      ),

      // TEST 9: Programmatic scroll
      _TestSection(
        number: 9,
        title: 'Programmatic Scroll',
        description: widget.useBrowserScroller
            ? 'Drive the page from code via BrowserScrollController. '
                  'jumpTo lands instantly. animateTo uses the browser '
                  'native smooth scroll, so the duration and curve are '
                  'approximate.'
            : 'Drive the page from code via ScrollController. jumpTo '
                  "lands instantly. animateTo uses Flutter's own "
                  'animation, so the duration and curve are honored '
                  'exactly.',
        color: Colors.amber,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => widget.controller.jumpTo(0),
              child: const Text('jumpTo(0)'),
            ),
            OutlinedButton(
              onPressed: () {
                final ScrollController c = widget.controller;
                if (c.hasClients) {
                  c.jumpTo(c.position.maxScrollExtent);
                }
              },
              child: const Text('jumpTo(max)'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller.animateTo(
                1500,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              ),
              child: const Text('animateTo(1500)'),
            ),
          ],
        ),
      ),

      // TEST 10: TextField focus
      _TestSection(
        number: 10,
        title: 'TextField Focus',
        description: widget.useBrowserScroller
            ? 'Tap to focus this text field. On mobile the soft '
                  'keyboard opens. The browser-owned page should still '
                  'scroll after focus, including from any FAB or '
                  'programmatic scroll.'
            : 'Tap to focus this text field. On mobile the soft '
                  'keyboard opens. Without flutter_browser_scroll, '
                  'observe whether the Flutter-scrolled page still '
                  'scrolls after focus.',
        color: Colors.brown,
        child: const TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Tap to focus',
          ),
        ),
      ),

      // More content for scrolling
      for (int i = 10; i <= 25; i++) _FlutterCard(index: i),

      // TEST 11: Bottom reached
      _TestSection(
        number: 11,
        title: 'Bottom Reached',
        description: widget.useBrowserScroller
            ? 'You scrolled to the bottom of the browser-owned page. All '
                  'scroll boundary crossing scenarios are working with '
                  'flutter_browser_scroll.'
            : 'You scrolled to the bottom of the Flutter-scrolled page. '
                  'Compare with the AFTER demo to see what scroll '
                  'chaining and iOS Safari touch handling '
                  'flutter_browser_scroll adds.',
        color: Colors.green,
        status: TestStatus.pass,
        child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
      ),

      const SizedBox(height: 48),
    ];
    final Widget list = ListView(
      controller: widget.controller,
      children: children,
    );
    final Widget browserContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    return widget.useBrowserScroller
        ? BrowserScroller(
            controller: widget.controller is BrowserScrollController
                ? widget.controller as BrowserScrollController
                : null,
            child: browserContent,
          )
        : list;
  }

  Widget _buildOverlayTests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dialog
        _overlayRow(
          icon: Icons.open_in_new,
          label: 'Show Dialog',
          child: ElevatedButton(
            onPressed: () => _showTestDialog(context),
            child: const Text('Open Dialog'),
          ),
        ),
        const Divider(height: 24),

        // Input Dialog
        _overlayRow(
          icon: Icons.edit_note,
          label: 'Input Dialog',
          child: ElevatedButton(
            onPressed: () => _showInputDialog(context),
            child: const Text('Open Input Dialog'),
          ),
        ),
        const Divider(height: 24),

        // DropdownButton
        _overlayRow(
          icon: Icons.arrow_drop_down_circle,
          label: 'Dropdown',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: DropdownButton<String>(
              value: _dropdownValue,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Option A', child: Text('Option A')),
                DropdownMenuItem(value: 'Option B', child: Text('Option B')),
                DropdownMenuItem(value: 'Option C', child: Text('Option C')),
                DropdownMenuItem(value: 'Option D', child: Text('Option D')),
                DropdownMenuItem(value: 'Option E', child: Text('Option E')),
              ],
              onChanged: (v) => setState(() => _dropdownValue = v!),
            ),
          ),
        ),
        const Divider(height: 24),

        // PopupMenuButton
        _overlayRow(
          icon: Icons.more_vert,
          label: 'Popup Menu',
          child: PopupMenuButton<String>(
            onSelected: (v) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected: $v'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'cut',
                child: ListTile(leading: Icon(Icons.cut), title: Text('Cut')),
              ),
              PopupMenuItem(
                value: 'copy',
                child: ListTile(leading: Icon(Icons.copy), title: Text('Copy')),
              ),
              PopupMenuItem(
                value: 'paste',
                child: ListTile(
                  leading: Icon(Icons.paste),
                  title: Text('Paste'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Actions'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 24),

        // MenuAnchor
        _overlayRow(
          icon: Icons.menu_open,
          label: 'MenuAnchor',
          child: _MenuAnchorTest(),
        ),
        const Divider(height: 24),

        // Bottom Sheet
        _overlayRow(
          icon: Icons.vertical_align_bottom,
          label: 'Bottom Sheet',
          child: ElevatedButton(
            onPressed: () => _showBottomSheet(context),
            child: const Text('Show Bottom Sheet'),
          ),
        ),
      ],
    );
  }

  Widget _overlayRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.purple.shade400),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }

  void _showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Dialog'),
        content: const Text(
          'This dialog should appear centered in the viewport. '
          'Tapping outside or pressing the button should close it. '
          'Scroll should be blocked while this is open.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Input Dialog'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Type something to test keyboard interaction inside a dialog overlay.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You typed: ${controller.text}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Bottom Sheet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This bottom sheet slides up from the bottom of the viewport.',
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy Link'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmark'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

enum TestStatus { pending, pass, fail }

class _TestSection extends StatelessWidget {
  const _TestSection({
    required this.number,
    required this.title,
    required this.description,
    required this.color,
    required this.child,
    this.status = TestStatus.pending,
  });

  final int number;
  final String title;
  final String description;
  final MaterialColor color;
  final Widget child;
  final TestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  radius: 16,
                  child: Text(
                    '$number',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: color.shade600),
                      ),
                    ],
                  ),
                ),
                if (status == TestStatus.pass)
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                if (status == TestStatus.fail)
                  const Icon(Icons.cancel, color: Colors.red, size: 28),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _PullToRefreshTest extends StatefulWidget {
  const _PullToRefreshTest({required this.useBrowserScroller});

  final bool useBrowserScroller;

  @override
  State<_PullToRefreshTest> createState() => _PullToRefreshTestState();
}

class _PullToRefreshTestState extends State<_PullToRefreshTest> {
  final _items = List.generate(20, (i) => 'Refresh Item ${i + 1}');
  int _refreshCount = 0;

  Future<void> _onRefresh() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    setState(() {
      _refreshCount++;
      _items.insert(0, 'New item from refresh #$_refreshCount');
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget list = ListView.builder(
      primary: false,
      physics: const ClampingScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ListTile(
          dense: true,
          leading: Icon(
            index == 0 && _refreshCount > 0 ? Icons.fiber_new : Icons.circle,
            size: 16,
            color: index == 0 && _refreshCount > 0 ? Colors.cyan : Colors.grey,
          ),
          title: Text(_items[index]),
        );
      },
    );
    return SizedBox(
      height: 300,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: widget.useBrowserScroller
            ? BrowserScrollChild(preserveTopOverscroll: true, child: list)
            : list,
      ),
    );
  }
}

class _FlutterCard extends StatelessWidget {
  const _FlutterCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.shade100,
          child: Text('$index'),
        ),
        title: Text('Flutter Widget $index'),
        subtitle: const Text('Regular Flutter content in the scroll list'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.teal.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100,
            offset: const Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade800,
        ),
      ),
    );
  }
}

class _MenuAnchorTest extends StatefulWidget {
  @override
  State<_MenuAnchorTest> createState() => _MenuAnchorTestState();
}

class _MenuAnchorTestState extends State<_MenuAnchorTest> {
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.undo),
          onPressed: () {},
          child: const Text('Undo'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.redo),
          onPressed: () {},
          child: const Text('Redo'),
        ),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.select_all),
          onPressed: () {},
          child: const Text('Select All'),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.format_align_left),
          menuChildren: [
            MenuItemButton(onPressed: () {}, child: const Text('Left')),
            MenuItemButton(onPressed: () {}, child: const Text('Center')),
            MenuItemButton(onPressed: () {}, child: const Text('Right')),
          ],
          child: const Text('Align'),
        ),
      ],
      child: GestureDetector(
        onTap: () {
          if (_controller.isOpen) {
            _controller.close();
          } else {
            _controller.open();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Menu'),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
