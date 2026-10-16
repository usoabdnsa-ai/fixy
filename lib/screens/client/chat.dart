import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';

/// Job chat. Opens only once a job is accepted. [asPro] flips the
/// perspective so the craftsman side can reuse it.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.job, this.asPro = false});
  final Job job;
  final bool asPro;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  int _seen = 0;

  static const _quick = ['Where are you now?', 'Can you bring the part?', 'The door code is 1954', 'Merci!'];

  void _send([String? text]) {
    final t = (text ?? _ctl.text).trim();
    if (t.isEmpty) return;
    context.read<AppState>().sendMessage(widget.job, t);
    _ctl.clear();
    setState(() {});
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: M.base, curve: M.out);
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final job = widget.job;
    final msgs = job.messages;
    final other = widget.asPro ? job.clientName : job.craftsman!.name;
    final typing = msgs.isNotEmpty && msgs.last.fromMe && !widget.asPro;
    if (msgs.length != _seen) {
      _seen = msgs.length;
      _toBottom();
    }
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(12, pad.top + 8, S.gutter, 12),
            decoration: const BoxDecoration(
              color: C.card,
              border: Border(bottom: BorderSide(color: C.line, width: 1.5)),
            ),
            child: Row(
              children: [
                IconCircle(icon: PhosphorIconsBold.arrowLeft, label: 'Back', onTap: () => Navigator.pop(context), bg: C.paper),
                const SizedBox(width: 10),
                if (!widget.asPro) Avatar(craftsman: job.craftsman!, size: 38),
                if (!widget.asPro) const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(other, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${job.id} · ${job.status.label}', style: mono(size: 11, color: C.inkSoft)),
                    ],
                  ),
                ),
                IconCircle(icon: PhosphorIconsBold.phone, label: 'Call', bg: C.paper, onTap: () => toast(context, 'Calling $other… (prototype)')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, S.lg),
              itemCount: msgs.length + 2 + (typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: S.lg),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(color: C.line, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(job.trade.icon, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              job.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (job.price != null) ...[const SizedBox(width: 10), Text(dzd(job.price!), style: mono(size: 12, weight: FontWeight.w700))],
                        ],
                      ),
                    ),
                  );
                }
                if (i == 1) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'TODAY',
                        style: mono(size: 10.5, color: C.inkSoft, weight: FontWeight.w700),
                      ),
                    ),
                  );
                }
                final idx = i - 2;
                if (idx == msgs.length) return const _Typing();
                final m = msgs[idx];
                final mine = widget.asPro ? !m.fromMe && !m.system : m.fromMe;
                final isNew = idx >= msgs.length - 1;
                Widget bubble = m.system ? _System(m.text) : _Bubble(m: m, mine: mine);
                if (isNew && !reduceMotion(context)) {
                  bubble = bubble
                      .animate()
                      .fadeIn(duration: 180.ms)
                      .moveY(begin: 10, end: 0, duration: 220.ms, curve: M.out)
                      .scaleXY(begin: .96, end: 1, alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft);
                }
                return bubble;
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              children: [
                for (final q in _quick)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: Pressable(
                      onTap: () => _send(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: C.card,
                          borderRadius: BorderRadius.circular(R.pill),
                          border: Border.all(color: C.line, width: 1.5),
                        ),
                        child: Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + pad.bottom),
            decoration: const BoxDecoration(
              color: C.card,
              border: Border(top: BorderSide(color: C.line, width: 1.5)),
            ),
            child: Row(
              children: [
                IconCircle(icon: PhosphorIconsBold.camera, label: 'Send photo', bg: C.paper, onTap: () => toast(context, 'Photo picker (prototype)')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      fillColor: C.paper,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.pill), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.pill), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(R.pill),
                        borderSide: const BorderSide(color: C.ink, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedScale(
                  scale: _ctl.text.trim().isEmpty ? 0.85 : 1,
                  duration: M.fast,
                  curve: M.out,
                  child: Pressable(
                    semanticLabel: 'Send',
                    onTap: _ctl.text.trim().isEmpty ? null : _send,
                    child: AnimatedContainer(
                      duration: M.fast,
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _ctl.text.trim().isEmpty ? C.line : C.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.ink, width: 1.5),
                      ),
                      child: const Icon(PhosphorIconsFill.paperPlaneRight, size: 20, color: C.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.m, required this.mine});
  final Message m;
  final bool mine;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .74),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? C.ink : C.card,
          border: mine ? null : Border.all(color: C.line, width: 1.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(m.text, style: TextStyle(color: mine ? C.paper : C.ink, fontSize: 15, height: 1.35)),
            ),
            const SizedBox(height: 3),
            Text(m.time, style: mono(size: 10, color: mine ? const Color(0xFFBDB3A2) : C.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _System extends StatelessWidget {
  const _System(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsFill.sealCheck, size: 13, color: C.teal),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: C.teal, fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: C.card,
          border: Border.all(color: C.line, width: 1.5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: C.inkSoft, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 140).ms).moveY(begin: 0, end: -4, duration: 360.ms, curve: Curves.easeInOut),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 160.ms);
  }
}
