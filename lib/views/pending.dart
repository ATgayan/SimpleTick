import 'package:flutter/material.dart';

class _C {
  static const sky = Color(0xFF5BC0F8);
  static const blue = Color(0xFF2196F3);
  static const deepBlue = Color(0xFF1565C0);
  static const ink = Color(0xFF12315A);
  static const muted = Color(0xFF6B84A3);
}

/// Simple task model used by this screen.
/// Replace with your own model / data source.
class PendingTask {
  final int id;
  final String title;
  final String description;
  final String category; // Personal, Work, Study, Shopping
  final String priority; // Low, Medium, High
  final DateTime? due;

  const PendingTask({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Personal',
    this.priority = 'Medium',
    this.due,
  });
}

class PendingScreen extends StatefulWidget {
  /// Pass your real pending tasks here. If null, demo data is shown.
  final List<PendingTask>? tasks;
  const PendingScreen({super.key, this.tasks});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late List<PendingTask> _tasks;
  String _filter = 'All';

  static const _filters = ['All', 'High', 'Medium', 'Low'];

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

  List<PendingTask> _demoTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      PendingTask(
        id: 1,
        title: 'Finish project report',
        description: 'Complete the final section and send it to the team.',
        category: 'Work',
        priority: 'High',
        due: today.subtract(const Duration(days: 1)),
      ),
      PendingTask(
        id: 2,
        title: 'Buy groceries',
        description: 'Milk, eggs, fruits and vegetables.',
        category: 'Shopping',
        priority: 'Medium',
        due: today,
      ),
      PendingTask(
        id: 3,
        title: 'Study Flutter animations',
        description: 'Watch the tutorial and practice implicit animations.',
        category: 'Study',
        priority: 'High',
        due: today.add(const Duration(days: 1)),
      ),
      PendingTask(
        id: 4,
        title: 'Call the dentist',
        category: 'Personal',
        priority: 'Low',
        due: today.add(const Duration(days: 4)),
      ),
      PendingTask(
        id: 5,
        title: 'Plan weekend trip',
        description: 'Check bus times and book a room.',
        category: 'Personal',
        priority: 'Medium',
      ),
    ];
  }

  List<PendingTask> get _visible => _filter == 'All'
      ? _tasks
      : _tasks.where((t) => t.priority == _filter).toList();

  // ───────────────────────── Actions ─────────────────────────
  void _complete(PendingTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _snack('Marked as completed ✅', onUndo: () {
      setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
    });
    // TODO: update the task in your database / provider here.
  }

  void _delete(PendingTask task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;
    setState(() => _tasks.removeAt(index));
    _snack('Task deleted', onUndo: () {
      setState(() => _tasks.insert(index.clamp(0, _tasks.length), task));
    });
    // TODO: delete the task from your database / provider here.
  }

  void _snack(String text, {VoidCallback? onUndo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.deepBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              child: _blob(260, _C.blue.withValues(alpha: 0.10)),
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
                        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final task = list[i];
                          return _PendingCard(
                            key: ValueKey(task.id),
                            task: task,
                            index: i,
                            onComplete: () => _complete(task),
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
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.sky, _C.deepBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: _C.blue.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.task_alt_rounded, color: Colors.white),
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
                'Pending',
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
                    ? 'Nothing left to do'
                    : 'Swipe right to complete, left to delete',
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
                colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
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
                Icons.celebration_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _tasks.isEmpty ? 'All caught up!' : 'No $_filter priority tasks',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enjoy your free time 🎉',
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
class _PendingCard extends StatefulWidget {
  final PendingTask task;
  final int index;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _PendingCard({
    super.key,
    required this.task,
    required this.index,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit;
  bool _checked = false;

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

  Future<void> _tapComplete() async {
    if (_checked) return;
    setState(() => _checked = true);
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _exit.reverse();
    if (mounted) widget.onComplete();
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

  (String, bool) get _dueInfo {
    final due = widget.task.due;
    if (due == null) return ('No due date', false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    final diff = d.difference(today).inDays;
    if (diff < 0) return ('Overdue', true);
    if (diff == 0) return ('Today', false);
    if (diff == 1) return ('Tomorrow', false);
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return ('${m[d.month - 1]} ${d.day}', false);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final (dueText, overdue) = _dueInfo;
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
                color: Colors.green,
                icon: Icons.check_rounded,
                label: 'Complete',
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
                  widget.onComplete();
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
                        Container(width: 6, color: _priorityColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                            child: Row(
                              children: [
                                Expanded(child: _content(task, dueText, overdue)),
                                const SizedBox(width: 8),
                                _checkButton(),
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

  Widget _content(PendingTask task, String dueText, bool overdue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: _checked ? _C.muted : _C.ink,
            decoration: _checked ? TextDecoration.lineThrough : null,
          ),
          child: Text(task.title),
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
            _chip(_categoryIcon, task.category, _C.blue),
            _chip(
              overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              dueText,
              overdue ? Colors.red : _C.muted,
            ),
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

  Widget _checkButton() {
    return GestureDetector(
      onTap: _tapComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _checked
              ? const LinearGradient(colors: [_C.sky, _C.deepBlue])
              : null,
          border: Border.all(
            color: _checked ? Colors.transparent : _C.sky,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: _checked ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
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