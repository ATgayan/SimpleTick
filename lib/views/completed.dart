import 'package:flutter/material.dart';

class _C {
  static const sky = Color(0xFF5BC0F8);
  static const blue = Color(0xFF2196F3);
  static const deepBlue = Color(0xFF1565C0);
  static const ink = Color(0xFF12315A);
  static const muted = Color(0xFF6B84A3);
  static const green = Color(0xFF43A047);
  static const lightGreen = Color(0xFF81C784);
}

/// Simple completed-task model used by this screen.
/// Replace with your own model / data source.
class CompletedTask {
  final int id;
  final String title;
  final String description;
  final String category; // Personal, Work, Study, Shopping
  final String priority; // Low, Medium, High
  final DateTime completedAt;

  const CompletedTask({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = 'Medium',
    required this.completedAt,
  });
}

class CompletedScreen extends StatefulWidget {
  /// Pass your real completed tasks here. If null, demo data is shown.
  final List<CompletedTask>? tasks;
  const CompletedScreen({super.key, this.tasks});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late List<CompletedTask> _tasks;
  String _filter = 'All';

  static const _filters = ['All', 'Today', 'This week', 'Earlier'];

  @override
  void initState() {
    super.initState();
    _tasks = List.of(widget.tasks ?? _demoTasks());
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  List<CompletedTask> _demoTasks() {
    final now = DateTime.now();
    return [
      CompletedTask(
        id: 1,
        title: 'Submit assignment',
        description: 'Uploaded the final PDF to the student portal.',
        category: 'Study',
        priority: 'High',
        completedAt: now.subtract(const Duration(minutes: 25)),
      ),
      CompletedTask(
        id: 2,
        title: 'Morning workout',
        category: 'Personal',
        priority: 'Low',
        completedAt: now.subtract(const Duration(hours: 5)),
      ),
      CompletedTask(
        id: 3,
        title: 'Send weekly status email',
        description: 'Shared progress with the team and the manager.',
        category: 'Work',
        priority: 'Medium',
        completedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      CompletedTask(
        id: 4,
        title: 'Pay electricity bill',
        category: 'Personal',
        priority: 'High',
        completedAt: now.subtract(const Duration(days: 3)),
      ),
      CompletedTask(
        id: 5,
        title: 'Buy birthday gift',
        description: 'Picked up a book and a card.',
        category: 'Shopping',
        priority: 'Medium',
        completedAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }

  List<CompletedTask> get _visible {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int daysAgo(CompletedTask t) {
      final d = DateTime(
          t.completedAt.year, t.completedAt.month, t.completedAt.day);
      return today.difference(d).inDays;
    }

    switch (_filter) {
      case 'Today':
        return _tasks.where((t) => daysAgo(t) == 0).toList();
      case 'This week':
        return _tasks.where((t) => daysAgo(t) < 7).toList();
      case 'Earlier':
        return _tasks.where((t) => daysAgo(t) >= 7).toList();
      default:
        return _tasks;
    }
  }

  // ───────────────────────── Actions ─────────────────────────
  void _restore(CompletedTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _snack('Moved back to Pending ↩️', onUndo: () {
      setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
    });
    // TODO: mark the task as pending again in your database / provider here.
  }

  void _delete(CompletedTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _snack('Task deleted', onUndo: () {
      setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
    });
    // TODO: delete the task from your database / provider here.
  }

  void _clearAll() {
    if (_tasks.isEmpty) return;
    final backup = List<CompletedTask>.of(_tasks);
    setState(() => _tasks.clear());
    _snack('Cleared all completed tasks', onUndo: () {
      setState(() => _tasks = backup);
    });
    // TODO: delete all completed tasks from your database / provider here.
  }

  void _snack(String text, {VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.deepBlue,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(text),
          action: onUndo == null
              ? null
              : SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: onUndo,
          ),
        ),
      );
  }

  Widget _reveal(Widget child, double begin, double end) {
    final curve = CurvedAnimation(
      parent: _enter,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  // ───────────────────────────── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
    final list = _visible;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBFE6FF), Color(0xFFE6F5FF), Colors.white],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -60,
              child: _blob(220, _C.sky.withValues(alpha: 0.22)),
            ),
            Positioned(
              bottom: -90,
              left: -70,
              child: _blob(260, _C.green.withValues(alpha: 0.10)),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _reveal(_buildTopBar(), 0.0, 0.4),
                        const SizedBox(height: 20),
                        _reveal(_buildHeading(), 0.1, 0.5),
                        const SizedBox(height: 18),
                        _reveal(_buildFilters(), 0.2, 0.6),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: list.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                        key: ValueKey(_filter),
                        physics: const BouncingScrollPhysics(),
                        padding:
                        const EdgeInsets.fromLTRB(22, 4, 22, 30),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final task = list[i];
                          return _CompletedCard(
                            key: ValueKey(task.id),
                            task: task,
                            index: i,
                            onRestore: () => _restore(task),
                            onDelete: () => _delete(task),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _PressScale(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: _C.blue.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _C.deepBlue,
            ),
          ),
        ),
        const Spacer(),
        if (_tasks.isNotEmpty) ...[
          _PressScale(
            onTap: _clearAll,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: _C.blue.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_rounded,
                      size: 18, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text(
                    'Clear all',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.lightGreen, _C.green],
            ),
            boxShadow: [
              BoxShadow(
                color: _C.green.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.verified_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeading() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _tasks.isEmpty
                    ? 'Nothing completed yet'
                    : 'Swipe right to restore, left to delete',
                style: const TextStyle(fontSize: 14.5, color: _C.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: Container(
            key: ValueKey(_tasks.length),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.lightGreen, _C.green],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.green.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              '${_tasks.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = _filter == f;
          return _PressScale(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: selected
                    ? const LinearGradient(colors: [_C.sky, _C.deepBlue])
                    : null,
                color: selected ? null : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _C.blue.withValues(alpha: selected ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : _C.ink,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF64C8FF), Color(0xFF1E88E5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.blue.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.inbox_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _tasks.isEmpty
                ? 'No completed tasks'
                : 'Nothing here for "$_filter"',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Finished tasks will show up here 💪',
            style: TextStyle(fontSize: 15, color: _C.muted),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ─────────────────────────── Task card ───────────────────────────
class _CompletedCard extends StatefulWidget {
  final CompletedTask task;
  final int index;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _CompletedCard({
    super.key,
    required this.task,
    required this.index,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  State<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<_CompletedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1,
    );
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _tapRestore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _exit.reverse();
    if (mounted) widget.onRestore();
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData get _categoryIcon {
    switch (widget.task.category) {
      case 'Work':
        return Icons.work_rounded;
      case 'Study':
        return Icons.school_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String get _completedText {
    final at = widget.task.completedAt;
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(at.year, at.month, at.day);
    final days = today.difference(d).inDays;
    if (days == 0) return '${diff.inHours} h ago';
    if (days == 1) return 'Yesterday';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[at.month - 1]} ${at.day}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final delay = 420 + (widget.index.clamp(0, 8) * 90);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: child,
        ),
      ),
      child: SizeTransition(
        sizeFactor: CurvedAnimation(parent: _exit, curve: Curves.easeInOut),
        child: FadeTransition(
          opacity: _exit,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Dismissible(
              key: ValueKey('dismiss_${task.id}'),
              background: _swipeBg(
                color: _C.blue,
                icon: Icons.undo_rounded,
                label: 'Restore',
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: _swipeBg(
                color: Colors.redAccent,
                icon: Icons.delete_rounded,
                label: 'Delete',
                alignment: Alignment.centerRight,
              ),
              onDismissed: (dir) {
                if (dir == DismissDirection.startToEnd) {
                  widget.onRestore();
                } else {
                  widget.onDelete();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: _C.blue.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 6, color: _C.green),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                            child: Row(
                              children: [
                                _doneBadge(),
                                const SizedBox(width: 12),
                                Expanded(child: _content(task)),
                                const SizedBox(width: 8),
                                _restoreButton(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneBadge() {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_C.lightGreen, _C.green]),
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
    );
  }

  Widget _content(CompletedTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: _C.muted,
            decoration: TextDecoration.lineThrough,
            decorationColor: _C.muted,
          ),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: _C.muted, height: 1.3),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(Icons.check_circle_rounded, _completedText, _C.green),
            _chip(_categoryIcon, task.category, _C.blue),
            _chip(Icons.flag_rounded, task.priority, _priorityColor),
          ],
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _restoreButton() {
    return GestureDetector(
      onTap: _tapRestore,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _restoring ? _C.blue.withValues(alpha: 0.15) : null,
          border: Border.all(color: _C.sky, width: 2),
        ),
        child: AnimatedRotation(
          turns: _restoring ? -0.5 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: const Icon(Icons.undo_rounded, color: _C.deepBlue, size: 18),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    final left = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: left
            ? [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: _swipeText),
        ]
            : [
          Text(label, style: _swipeText),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white),
        ],
      ),
    );
  }

  static const _swipeText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
  );
}

/// Shrinks slightly while pressed.
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}