
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
  static const green = Color(0xFF2EAD76);
}

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  List<Todo> _tasks = [];
  String _filter = 'All';
  bool _isLoading = true;

  static const _filters = ['All', 'High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompletedTasks();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  // Load completed tasks from SQLite.
  Future<void> _loadCompletedTasks() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<TodoViewModel>();

      await viewModel.getCompletedTodos();

      if (!mounted) return;

      setState(() {
        _tasks = List<Todo>.from(viewModel.todos);
      });
    } catch (e) {
      debugPrint('Error loading completed tasks: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load completed tasks'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Todo> get _visible {
    if (_filter == 'All') {
      return _tasks;
    }

    return _tasks
        .where((task) => task.priority == _filter)
        .toList();
  }

  // Move a completed task back to pending.
  Future<void> _undoComplete(Todo task) async {
    if (task.id == null) return;

    try {
      final viewModel = context.read<TodoViewModel>();

      await viewModel.updateTodo(
        task.copyWith(completed: false),
      );

      if (!mounted) return;

      await _loadCompletedTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task moved to pending'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error moving task to pending: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update task'),
          ),
        );
        await _loadCompletedTasks();
      }
    }
  }

  // Delete a completed task from SQLite.
  Future<void> _delete(Todo task) async {
    if (task.id == null) return;

    try {
      final viewModel = context.read<TodoViewModel>();

      await viewModel.deleteTodo(task.id!);

      if (!mounted) return;

      await _loadCompletedTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete task'),
          ),
        );
        await _loadCompletedTasks();
      }
    }
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
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

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
                _C.blue.withValues(alpha: 0.10),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      22, 10, 22, 0,
                    ),
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
                    child: _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: _C.deepBlue,
                      ),
                    )
                        : AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 350,
                      ),
                      child: list.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                        color: _C.deepBlue,
                        onRefresh: _loadCompletedTasks,
                        child: ListView.builder(
                          key: ValueKey(_filter),
                          physics:
                          const AlwaysScrollableScrollPhysics(
                            parent:
                            BouncingScrollPhysics(),
                          ),
                          padding:
                          const EdgeInsets.fromLTRB(
                            22, 4, 22, 30,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final task = list[i];

                            return _CompletedCard(
                              key: ValueKey(task.id),
                              task: task,
                              index: i,
                              onUndo: () =>
                                  _undoComplete(task),
                              onDelete: () =>
                                  _delete(task),
                            );
                          },
                        ),
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
          child: const Icon(
            Icons.task_alt_rounded,
            color: Colors.white,
          ),
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
                    ? 'Your finished tasks appear here'
                    : 'Nice work! You have finished ${_tasks.length} tasks',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: _C.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
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
                colors: [
                  Color(0xFF66DDAA),
                  Color(0xFF159B69),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.green.withValues(alpha: 0.35),
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
        separatorBuilder: (_, __) =>
        const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final selected = _filter == filter;

          return _PressScale(
            onTap: () {
              setState(() => _filter = filter);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
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
                      alpha: selected ? 0.3 : 0.08,
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
            builder: (_, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF66DDAA),
                    Color(0xFF159B69),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.green.withValues(alpha: 0.3),
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
            _tasks.isEmpty
                ? 'Nothing completed yet!'
                : 'No $_filter priority tasks',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tasks.isEmpty
                ? 'Complete a task to see it here 🎉'
                : 'Try another priority filter',
            style: const TextStyle(
              fontSize: 15,
              color: _C.muted,
            ),
          ),
        ],
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

class _CompletedCard extends StatefulWidget {
  final Todo task;
  final int index;
  final VoidCallback onUndo;
  final VoidCallback onDelete;

  const _CompletedCard({
    super.key,
    required this.task,
    required this.index,
    required this.onUndo,
    required this.onDelete,
  });

  @override
  State<_CompletedCard> createState() => _CompletedCardState();
}

class _CompletedCardState extends State<_CompletedCard> {
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

  String get _dueText {
    final due = widget.task.dueDate;

    if (due == null) return 'No due date';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${months[due.month - 1]} ${due.day}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return TweenAnimationBuilder<double>(
      key: ValueKey('animation_${task.id}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
        milliseconds: 420 + widget.index.clamp(0, 8) * 80,
      ),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Dismissible(
          key: ValueKey('completed_${task.id}'),
          background: _swipeBackground(
            color: Colors.orange,
            icon: Icons.undo_rounded,
            label: 'Undo',
            left: true,
          ),
          secondaryBackground: _swipeBackground(
            color: Colors.redAccent,
            icon: Icons.delete_rounded,
            label: 'Delete',
            left: false,
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              widget.onUndo();
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
                  color: _C.green.withValues(alpha: 0.10),
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
                    Container(
                      width: 6,
                      color: _C.green,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          14, 15, 12, 15,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _C.green.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: _C.green,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: _C.muted,
                                      decoration:
                                      TextDecoration.lineThrough,
                                    ),
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
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _chip(
                                        _categoryIcon,
                                        task.category,
                                        _C.blue,
                                      ),
                                      _chip(
                                        Icons.calendar_today_rounded,
                                        _dueText,
                                        _C.muted,
                                      ),
                                      _chip(
                                        Icons.flag_rounded,
                                        task.priority,
                                        _priorityColor,
                                      ),
                                      if (task.important)
                                        _chip(
                                          Icons.star_rounded,
                                          'Important',
                                          Colors.deepPurple,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            PopupMenuButton<String>(
                              tooltip: 'Task options',
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: _C.muted,
                              ),
                              onSelected: (value) {
                                if (value == 'undo') {
                                  widget.onUndo();
                                } else if (value == 'delete') {
                                  widget.onDelete();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'undo',
                                  child: Row(
                                    children: [
                                      Icon(Icons.undo_rounded),
                                      SizedBox(width: 10),
                                      Text('Move to pending'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Delete task'),
                                    ],
                                  ),
                                ),
                              ],
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

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required bool left,
  }) {
    return Container(
      alignment:
      left ? Alignment.centerLeft : Alignment.centerRight,
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
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
