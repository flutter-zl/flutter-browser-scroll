import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import 'package:flutter/semantics.dart';
import 'package:flutter_browser_scroll/flutter_browser_scroll.dart';

void main() {
  _registerPlatformViews();
  runApp(const MyApp());
  SemanticsBinding.instance.ensureSemantics();
}

void _registerPlatformViews() {
  ui_web.platformViewRegistry.registerViewFactory('youtube-iframe', (
    int viewId,
  ) {
    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = 'https://www.youtube.com/embed/dQw4w9WgXcQ';
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

  ui_web.platformViewRegistry.registerViewFactory('wikipedia-in-div', (
    int viewId,
  ) {
    // The iframe is taller than the div so the div has real scroll content.
    // Chain: Wikipedia (cross-origin) → div (overflow:auto) → Flutter page.
    final label = web.document.createElement('div') as web.HTMLDivElement;
    label.textContent =
        '⬇ overflow:auto div — scroll here first, then the Flutter page takes over';
    label.style.background = '#e65100';
    label.style.color = 'white';
    label.style.padding = '6px 12px';
    label.style.fontSize = '12px';
    label.style.fontFamily = 'monospace';
    label.style.position = 'sticky';
    label.style.top = '0';
    label.style.zIndex = '10';

    final iframe =
        web.document.createElement('iframe') as web.HTMLIFrameElement;
    iframe.src = 'https://en.wikipedia.org/wiki/Main_Page';
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '800px';
    iframe.style.display = 'block';

    final container = web.document.createElement('div') as web.HTMLDivElement;
    container.style.width = '100%';
    container.style.height = '100%';
    container.style.overflow = 'auto';
    container.style.border = '2px solid #e65100';
    container.style.boxSizing = 'border-box';
    container.append(label);
    container.append(iframe);

    return container;
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser Scroll - Comprehensive Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ComprehensiveTestPage(),
    );
  }
}

class ComprehensiveTestPage extends StatefulWidget {
  const ComprehensiveTestPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Scroll Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      floatingActionButton: _ScrollFabColumn(
        controller: _scrollController,
        topTag: 'top',
        bottomTag: 'bottom',
      ),
      body: _TestPageBody(
        controller: _scrollController,
        useBrowserScroller: true,
        intro: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'This demo explores browser-driven scrolling in Flutter Web. '
            'Normally, Flutter intercepts all scroll events and handles '
            'them in Dart. The BrowserScroller widget solves this by letting '
            'the browser own the scroll position. When the user scrolls, '
            'the browser moves the page natively, and the engine reports '
            'the new offset back to Flutter via a dart:ui callback. '
            'Flutter then syncs its internal pixel position to match. '
            'This approach restores native browser behaviors while keeping '
            'the Flutter widget tree fully in control of layout and '
            'painting. Nested scrollables, pull-to-refresh, platform views, '
            'cross-origin iframes, and programmatic scrolling via '
            'ScrollController all continue to work correctly. Scroll down '
            'to explore each test case and observe how the framework '
            'handles each scenario.',
            style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
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

      // TEST 1: Basic scroll
      _TestSection(
        number: 1,
        title: 'Basic Flutter Scroll',
        description:
            'Scroll this page with mouse wheel or trackpad. '
            'The browser drives scrolling natively.',
        color: Colors.blue,
        status: TestStatus.pending,
        child: SizedBox(
          height: 400,
          child: BrowserScrollTouchRegion(
            forwardTopOverscroll: true,
            child: ListView(
              primary: false,
              physics: const ClampingScrollPhysics(),
              children: [for (int i = 1; i <= 20; i++) _FlutterCard(index: i)],
            ),
          ),
        ),
      ),

      // TEST 2: Pull-to-refresh at top edge
      _TestSection(
        number: 2,
        title: 'Pull-to-Refresh (RefreshIndicator)',
        description:
            'Pull down on this inner list when it is at its top. '
            'A refresh indicator should appear. Overscroll at the top '
            'edge is preserved so that RefreshIndicator works. '
            'At the bottom edge, the inner list clamps and the '
            'parent page takes over.',
        color: Colors.cyan,
        child: const _PullToRefreshTest(),
      ),

      // TEST 3: Cross-origin iframe (Wikipedia)
      _TestSection(
        number: 3,
        title: 'Cross-Origin Iframe (Wikipedia)',
        description:
            'Scroll inside the Wikipedia article. '
            'When it reaches the bottom, the parent page should '
            'take over and keep scrolling.',
        color: Colors.orange,
        child: const SizedBox(
          height: 400,
          child: HtmlElementView(viewType: 'wikipedia-iframe'),
        ),
      ),

      // TEST 4: Wikipedia iframe inside a scrollable div
      _TestSection(
        number: 4,
        title: 'Cross-Origin Iframe in Scrollable Div (Wikipedia)',
        description:
            'The Wikipedia page is loaded inside a <div '
            'overflow:auto> which is itself inside an iframe. Scroll '
            'inside it to the bottom, then keep scrolling to test '
            'chained boundary crossing.',
        color: Colors.deepOrange,
        child: const SizedBox(
          height: 400,
          child: HtmlElementView(viewType: 'wikipedia-in-div'),
        ),
      ),

      // TEST 5: Cross-origin iframe (YouTube)
      _TestSection(
        number: 5,
        title: 'Cross-Origin Iframe (YouTube)',
        description:
            'Move your cursor over the video and scroll. '
            'The page should continue scrolling without getting stuck.',
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
        description:
            'This HTML div has its own scroll. Scroll inside it to '
            'the bottom, then keep scrolling. The parent Flutter page should '
            'take over at the boundary.',
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
        description:
            'Click on the page, then press Page Down, Space, '
            'or Arrow Down. The browser should handle keyboard scrolling '
            'on the flutter-view element.',
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

      // More content for scrolling
      for (int i = 10; i <= 25; i++) _FlutterCard(index: i),

      // TEST 10: Bottom reached
      _TestSection(
        number: 10,
        title: 'Bottom Reached',
        description:
            'You scrolled to the bottom without getting stuck! '
            'All scroll boundary crossing scenarios are working.',
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
  const _PullToRefreshTest();

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
    return SizedBox(
      height: 300,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: BrowserScrollTouchRegion(
          child: ListView.builder(
            primary: false,
            physics: const ClampingScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              return ListTile(
                dense: true,
                leading: Icon(
                  index == 0 && _refreshCount > 0
                      ? Icons.fiber_new
                      : Icons.circle,
                  size: 16,
                  color: index == 0 && _refreshCount > 0
                      ? Colors.cyan
                      : Colors.grey,
                ),
                title: Text(_items[index]),
              );
            },
          ),
        ),
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
