import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'kit.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.activeIcon, this.page, {this.badge = 0});
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final int badge;
}

/// Bottom-tab shell shared by the three roles. Tabs fade-through (Material
/// motion) and the ink pill slides to the active tab.
class Shell extends StatefulWidget {
  const Shell({super.key, required this.items, this.center, this.initialIndex = 0});
  final int initialIndex;
  final List<NavItem> items;

  /// Optional raised center action (client: "Post a job").
  final ({IconData icon, String label, VoidCallback onTap})? center;

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  late int index = widget.initialIndex;
  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 260),
        transitionBuilder: (child, a, b) => FadeThroughTransition(animation: a, secondaryAnimation: b, fillColor: C.paper, child: child),
        child: KeyedSubtree(key: ValueKey(index), child: items[index].page),
      ),
      bottomNavigationBar: _Bar(
        items: items,
        index: index,
        onTap: (i) {
          if (i == index) return;
          HapticFeedback.selectionClick();
          go(i);
        },
        center: widget.center,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.items, required this.index, required this.onTap, this.center});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;
  final ({IconData icon, String label, VoidCallback onTap})? center;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final slots = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (center != null && i == items.length ~/ 2) slots.add(_CenterAction(center!));
      slots.add(
        Expanded(
          child: _Tab(item: items[i], active: i == index, onTap: () => onTap(i)),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: C.card,
        border: Border(top: BorderSide(color: C.line, width: 1.5)),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: slots),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});
  final NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      haptic: false,
      semanticLabel: item.label,
      scale: 0.94,
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: M.base,
                  curve: M.out,
                  width: active ? 52 : 32,
                  height: 30,
                  decoration: BoxDecoration(color: active ? C.ink : Colors.transparent, borderRadius: BorderRadius.circular(R.pill)),
                  child: AnimatedSwitcher(
                    duration: M.fast,
                    transitionBuilder: (c, a) => ScaleTransition(
                      scale: Tween(begin: .7, end: 1.0).animate(CurvedAnimation(parent: a, curve: M.out)),
                      child: FadeTransition(opacity: a, child: c),
                    ),
                    child: Icon(active ? item.activeIcon : item.icon, key: ValueKey(active), size: 20, color: active ? C.paper : C.inkSoft),
                  ),
                ),
                if (item.badge > 0)
                  Positioned(
                    right: -2,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: C.orange,
                        borderRadius: BorderRadius.circular(R.pill),
                        border: Border.all(color: C.ink, width: 1.2),
                      ),
                      child: Text(
                        '${item.badge}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: C.ink),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: M.fast,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? C.ink : C.inkSoft,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  const _CenterAction(this.c);
  final ({IconData icon, String label, VoidCallback onTap}) c;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Pressable(
        onTap: c.onTap,
        semanticLabel: c.label,
        scale: 0.92,
        child: Container(
          width: 58,
          height: 50,
          decoration: BoxDecoration(
            color: C.orange,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: C.ink, width: 2),
            boxShadow: tagShadow,
          ),
          child: Icon(c.icon, color: C.ink, size: 26),
        ),
      ),
    );
  }
}
