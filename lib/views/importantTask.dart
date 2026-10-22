
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/todo.dart';
import '../viewmodels/todo_viewmodel.dart';

class _C {
  static const sky = Color(0xFF5BC0F8);
  static const blue = Color(0xFF2196F3);
  static const deepBlue = Color(0xFF1565C0);
  static const ink = Color(0xFF12315A);
  static const muted = Color(0xFF6B84A3);
  static const amber = Color(0xFFFFB300);
  static const amberDark = Color(0xFFF57C00);
  static const red = Color(0xFFE53935);
}

class ImportantScreen extends StatefulWidget {
  const ImportantScreen({super.key});

  @override
  State<ImportantScreen> createState() => _ImportantScreenState();
}

class _ImportantScreenState extends State<ImportantScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  String _filter = 'All';

  static const _filters = [
    'All',
    'Overdue',
    'Today',
    'Upcoming',
  ];

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TodoViewModel>().getImportantTodos();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  int? _daysLeft(Todo task) {
    if (task.dueDate == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final due = task.dueDate!;
    final dueDay = DateTime(due.year, due.month, due.day);

    return dueDay.difference(today).inDays;
  }

  List<Todo> _visibleTasks(List<Todo> tasks) {
    Iterable<Todo> result = tasks.where(
          (task) => task.important && !task.completed,
    );

    switch (_filter) {
      case 'Overdue':
        result = result.where(
              (task) => (_daysLeft(task) ?? 0) < 0,
        );
        break;

      case 'Today':
        result = result.where(
              (task) => _daysLeft(task) == 0,
        );
        break;

      case 'Upcoming':
        result = result.where(
              (task) => (_daysLeft(task) ?? -1) > 0,
        );
        break;
    }

    final sorted = result.toList();

    sorted.sort((a, b) {
      final da = _daysLeft(a);
      final db = _daysLeft(b);

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      return da.compareTo(db);
    });

    return sorted;
  }

  Future<void> _complete(Todo task) async {
    if (task.id == null) return;

    final vm = context.read<TodoViewModel>();

    try {
      await vm.updateTodo(
        task.copyWith(completed: true),
      );

      if (!mounted) return;

      await vm.getImportantTodos();

      if (!mounted) return;
      _snack('Task completed successfully ✅');
    } catch (e) {
      if (mounted) {
        _snack('Could not complete task: $e');
      }
    }
  }

  Future<void> _unmark(Todo task) async {
    if (task.id == null) return;

    final vm = context.read<TodoViewModel>();

    try {
      await vm.updateTodo(
        task.copyWith(important: false),
      );

      if (!mounted) return;

      await vm.getImportantTodos();

      if (mounted) {
        _snack('Removed from important tasks');
      }
    } catch (e) {
      if (mounted) {
        _snack('Could not update task: $e');
      }
    }
  }

  Future<void> _delete(Todo task) async {
    if (task.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: _C.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<TodoViewModel>();

    try {
      await vm.deleteTodo(task.id!);

      if (!mounted) return;

      await vm.getImportantTodos();

      if (mounted) {
        _snack('Task deleted');
      }
    } catch (e) {
      if (mounted) {
        _snack('Could not delete task: $e');
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _C.deepBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  Widget _reveal(Widget child, double begin, double end) {
    final animation = CurvedAnimation(
      parent: _enter,
      curve: Interval(
        begin,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoViewModel>(
      builder: (context, vm, child) {
        // This assumes TodoViewModel exposes its current list
        // through a public `todos` getter.
        final allTasks = vm.todos;

        final tasks = allTasks
            .where((t) => t.important && !t.completed)
            .toList();

        final visible = _visibleTasks(tasks);

        final overdueCount = tasks
            .where((t) => (_daysLeft(t) ?? 0) < 0)
            .length;

        final todayCount = tasks
            .where((t) => _daysLeft(t) == 0)
            .length;

        final upcomingCount = tasks
            .where((t) => (_daysLeft(t) ?? -1) > 0)
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFE6F5FF),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFBFE6FF),
                  Color(0xFFE6F5FF),
                  Colors.white,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -60,
                  child: _blob(
                    220,
                    _C.sky.withValues(alpha: 0.22),
                  ),
                ),
                Positioned(
                  bottom: -90,
                  left: -70,
                  child: _blob(
                    260,
                    _C.amber.withValues(alpha: 0.10),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          22, 10, 22, 0,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            _reveal(_buildTopBar(), 0.0, 0.4),
                            const SizedBox(height: 20),
                            _reveal(
                              _buildHeading(tasks.length),
                              0.1,
                              0.5,
                            ),
                            const SizedBox(height: 16),
                            _reveal(
                              _buildSummary(
                                overdueCount,
                                todayCount,
                                upcomingCount,
                              ),
                              0.15,
                              0.55,
                            ),
                            const SizedBox(height: 16),
                            _reveal(_buildFilters(), 0.2, 0.6),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Expanded(
                        child: vm.isLoading
                            ? const Center(
                          child: CircularProgressIndicator(
                            color: _C.deepBlue,
                          ),
                        )
                            : AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 300,
                          ),
                          child: visible.isEmpty
                              ? _buildEmpty(tasks.isEmpty)
                              : ListView.builder(
                            key: ValueKey(_filter),
                            physics:
                            const BouncingScrollPhysics(),
                            padding:
                            const EdgeInsets.fromLTRB(
                              22, 4, 22, 30,
                            ),
                            itemCount: visible.length,
                            itemBuilder: (context, i) {
                              final task = visible[i];

                              return _ImportantCard(
                                key: ValueKey(task.id),
                                task: task,
                                index: i,
                                onComplete: () =>
                                    _complete(task),
                                onUnmark: () =>
                                    _unmark(task),
                                onDelete: () =>
                                    _delete(task),
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
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _PressScale(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
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
              colors: [Color(0xFFFFCA28), _C.amberDark],
            ),
            boxShadow: [
              BoxShadow(
                color: _C.amber.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.star_rounded,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeading(int count) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Important',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Your starred tasks, all in one place',
                style: TextStyle(
                  fontSize: 14.5,
                  color: _C.muted,
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(count),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCA28), _C.amberDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.amber.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              '$count',
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

  Widget _buildSummary(
      int overdue,
      int today,
      int upcoming,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
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
      child: Row(
        children: [
          _stat(
            'Overdue',
            overdue,
            _C.red,
            Icons.warning_amber_rounded,
          ),
          _divider(),
          _stat(
            'Today',
            today,
            _C.amberDark,
            Icons.today_rounded,
          ),
          _divider(),
          _stat(
            'Upcoming',
            upcoming,
            _C.blue,
            Icons.upcoming_rounded,
          ),
        ],
      ),
    );
  }

  Widget _stat(
      String label,
      int value,
      Color color,
      IconData icon,
      ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 34,
    color: _C.muted.withValues(alpha: 0.2),
  );

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final selected = _filter == filter;

          return _PressScale(
            onTap: () => setState(() => _filter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: selected
                    ? const LinearGradient(
                  colors: [_C.sky, _C.deepBlue],
                )
                    : null,
                color: selected ? null : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: _C.blue.withValues(
                      alpha: selected ? 0.25 : 0.08,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                filter,
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

  Widget _buildEmpty(bool noTasks) {
    return Center(
      key: ValueKey(noTasks ? 'empty' : 'filtered'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCA28), _C.amberDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.amber.withValues(alpha: 0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              noTasks
                  ? 'No important tasks'
                  : 'Nothing in "$_filter"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _C.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Star a task to see it here ⭐',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: _C.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// ------------------------------------------------------------
// Important task card
// ------------------------------------------------------------

class _ImportantCard extends StatefulWidget {
  final Todo task;
  final int index;
  final VoidCallback onComplete;
  final VoidCallback onUnmark;
  final VoidCallback onDelete;

  const _ImportantCard({
    super.key,
    required this.task,
    required this.index,
    required this.onComplete,
    required this.onUnmark,
    required this.onDelete,
  });

  @override
  State<_ImportantCard> createState() => _ImportantCardState();
}

class _ImportantCardState extends State<_ImportantCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exit;
  bool _checked = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  Future<void> _tapComplete() async {
    if (_checked || _busy) return;

    setState(() {
      _checked = true;
      _busy = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    await _exit.reverse();

    if (mounted) {
      widget.onComplete();
    }
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
    final due = widget.task.dueDate;

    if (due == null) return ('No due date', false);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(due.year, due.month, due.day);
    final difference = date.difference(today).inDays;

    if (difference < 0) return ('Overdue', true);
    if (difference == 0) return ('Today', false);
    if (difference == 1) return ('Tomorrow', false);

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return ('${months[due.month - 1]} ${due.day}', false);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final (dueText, overdue) = _dueInfo;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 350 + widget.index.clamp(0, 8) * 70,
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: SizeTransition(
        sizeFactor: CurvedAnimation(
          parent: _exit,
          curve: Curves.easeInOut,
        ),
        child: FadeTransition(
          opacity: _exit,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Dismissible(
              key: ValueKey('important_${task.id}'),
              direction: _busy
                  ? DismissDirection.none
                  : DismissDirection.horizontal,
              background: _swipeBg(
                color: _C.amberDark,
                icon: Icons.star_border_rounded,
                label: 'Unmark',
                left: true,
              ),
              secondaryBackground: _swipeBg(
                color: Colors.redAccent,
                icon: Icons.delete_rounded,
                label: 'Delete',
                left: false,
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  widget.onUnmark();
                } else {
                  widget.onDelete();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: overdue
                        ? _C.red.withValues(alpha: 0.35)
                        : Colors.white,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (overdue ? _C.red : _C.blue)
                          .withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 6,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFCA28),
                                _C.amberDark,
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              14, 14, 12, 14,
                            ),
                            child: Row(
                              children: [
                                _checkButton(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _content(
                                    task,
                                    dueText,
                                    overdue,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.star_rounded,
                                  color: _C.amber,
                                  size: 25,
                                ),
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

  Widget _content(
      Todo task,
      String dueText,
      bool overdue,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _checked ? _C.muted : _C.ink,
            decoration:
            _checked ? TextDecoration.lineThrough : null,
          ),
          child: Text(task.title),
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _C.muted,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(
              overdue
                  ? Icons.warning_amber_rounded
                  : Icons.schedule_rounded,
              dueText,
              overdue ? _C.red : _C.muted,
            ),
            _chip(
              _categoryIcon,
              task.category,
              _C.blue,
            ),
            _chip(
              Icons.flag_rounded,
              task.priority,
              _priorityColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(
      IconData icon,
      String text,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
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
      behavior: HitTestBehavior.opaque,
      onTap: _tapComplete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: _checked
              ? const LinearGradient(
            colors: [_C.sky, _C.deepBlue],
          )
              : null,
          border: Border.all(
            color: _checked ? Colors.transparent : _C.sky,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: _checked ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _swipeBg({
    required Color color,
    required IconData icon,
    required String label,
    required bool left,
  }) {
    return Container(
      alignment: left
          ? Alignment.centerLeft
          : Alignment.centerRight,
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

// ------------------------------------------------------------
// Press animation
// ------------------------------------------------------------

class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PressScale({
    required this.child,
    required this.onTap,
  });

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
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 130),
        child: widget.child,
      ),
    );
  }
}
