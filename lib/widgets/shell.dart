import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'kit.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.activeIcon, this.page, {this.badge = 0});
  final String label;
  final IconData icon, activeIcon;
  final Widget page;
  final int badge;
}

/// 4-tab bottom navigation. Tabs keep their state (IndexedStack).
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.items, this.initial = 0});
  final List<NavItem> items;
  final int initial;

  static AppShellState? of(BuildContext context) => context.findAncestorStateOfType<AppShellState>();

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int index = widget.initial;

  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: index == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) go(0);
    },
    child: Scaffold(
      body: IndexedStack(index: index, children: [for (final i in widget.items) i.page]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: C.card, border: Border(top: BorderSide(color: C.line))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final (i, item) in widget.items.indexed)
                  Expanded(
                    child: Pressable(
                      onTap: () => go(i),
                      scale: .92,
                      semanticLabel: item.label,
                      child: _Tab(item: item, active: i == index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active});
  final NavItem item;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: M.fast,
            curve: M.out,
            width: 54,
            height: 30,
            decoration: BoxDecoration(color: active ? C.turqWash : Colors.transparent, borderRadius: BorderRadius.circular(R.pill)),
            child: Icon(active ? item.activeIcon : item.icon, size: 22, color: active ? C.navy : C.inkFaint),
          ),
          if (item.badge > 0)
            Positioned(
              right: 6,
              top: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(R.pill), border: Border.all(color: C.card, width: 1.5)),
                child: Text('${item.badge}', textAlign: TextAlign.center, style: figs(size: 10.5, color: C.white, weight: FontWeight.w700)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 3),
      Text(item.label, style: body(size: 11.5, weight: active ? FontWeight.w700 : FontWeight.w500, color: active ? C.ink : C.inkSoft, height: 1.2)),
    ],
  );
}
