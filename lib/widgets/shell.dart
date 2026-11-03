import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
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

/// Bottom-tab shell shared by the three roles: a flush black bar with a
/// volt indicator that slides to the active tab; pages cut over quickly.
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
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220),
        transitionBuilder: (child, a, b) => FadeThroughTransition(animation: a, secondaryAnimation: b, fillColor: C.bg, child: child),
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
    final n = items.length + (center != null ? 1 : 0);
    // Slot of the active tab, accounting for the centre action.
    final slot = center != null && index >= items.length ~/ 2 ? index + 1 : index;
    final slots = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (center != null && i == items.length ~/ 2) slots.add(Expanded(child: _CenterAction(center!)));
      slots.add(Expanded(child: _Tab(item: items[i], active: i == index, onTap: () => onTap(i))));
    }
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: C.line)),
      ),
      padding: EdgeInsets.only(bottom: bottom + 6),
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth / n;
            return Stack(
              children: [
                // Volt indicator slides along the top edge to the active tab.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: M.out,
                  left: w * slot + w * .25,
                  width: w * .5,
                  top: 0,
                  height: 3,
                  child: ColoredBox(color: C.volt),
                ),
                Row(children: slots),
              ],
            );
          },
        ),
      ),
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
      scale: 0.92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(active ? item.activeIcon : item.icon, size: 22, color: active ? C.volt : C.inkSoft),
              if (item.badge > 0)
                Positioned(
                  right: -9,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    color: C.hot,
                    child: Text('${item.badge}', style: figs(size: 9.5, weight: FontWeight.w700, color: C.onFill)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          AnimatedDefaultTextStyle(
            duration: M.fast,
            style: figs(size: 9.5, weight: FontWeight.w700, color: active ? C.ink : C.inkSoft),
            child: Text(item.label.toUpperCase(), maxLines: 1),
          ),
        ],
      ),
    );
  }
}

/// "Post a job": a volt square with a plus, raised a little above the bar.
class _CenterAction extends StatelessWidget {
  const _CenterAction(this.c);
  final ({IconData icon, String label, VoidCallback onTap}) c;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        onTap: c.onTap,
        semanticLabel: c.label,
        scale: 0.88,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.sm), boxShadow: glow),
          child: Icon(c.icon, color: C.onFill, size: 26),
        ),
      ),
    );
  }
}
