import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final slots = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (center != null && i == items.length ~/ 2) slots.add(Expanded(child: _CenterAction(center!)));
      slots.add(
        Expanded(
          child: _Tab(item: items[i], active: i == index, onTap: () => onTap(i)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        border: C.isLight ? null : Border(top: BorderSide(color: C.line)),
        boxShadow: C.isLight ? const [BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, -4))] : null,
      ),
      padding: EdgeInsets.only(bottom: bottom + 6, top: 6),
      child: SizedBox(height: 62, child: Row(children: slots)),
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
    final fg = active ? (C.isLight ? C.volt : C.ink) : C.inkSoft;
    return Pressable(
      onTap: onTap,
      haptic: false,
      semanticLabel: item.label,
      scale: 0.92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pill indicator grows behind the active icon.
          AnimatedContainer(
            duration: M.base,
            curve: M.spring,
            width: active ? 56 : 32,
            height: 32,
            decoration: BoxDecoration(color: active ? C.voltWash : Colors.transparent, borderRadius: BorderRadius.circular(R.pill)),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(active ? item.activeIcon : item.icon, size: 22, color: fg),
                if (item.badge > 0)
                  Positioned(
                    right: active ? 10 : -2,
                    top: 0,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: C.red,
                        borderRadius: BorderRadius.circular(R.pill),
                        border: Border.all(color: C.card, width: 1.5),
                      ),
                      child: Text(
                        '${item.badge}',
                        textAlign: TextAlign.center,
                        style: figs(size: 9, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: M.fast,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: fg),
            child: Text(item.label, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

/// "Post a job": a raised blue circle with a plus.
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
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: C.volt,
            shape: BoxShape.circle,
            boxShadow: glow,
            border: Border.all(color: C.card, width: 3),
          ),
          child: Icon(c.icon, color: C.onFill, size: 26),
        ),
      ),
    );
  }
}
