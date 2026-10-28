import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../viewmodels/todo_viewmodel.dart';
import '../models/todo.dart';
import 'add_task_screen.dart';

class _C {
  static const sky = Color(0xFF5BC0F8);
  static const blue = Color(0xFF2196F3);
  static const deepBlue = Color(0xFF1565C0);
  static const ink = Color(0xFF12315A);
  static const muted = Color(0xFF6B84A3);
  static const green = Color(0xFF43A047);
  static const lightGreen = Color(0xFF81C784);
}




class AllTodoScreen extends StatefulWidget {
  final List<Todo>? todos;
  const AllTodoScreen({super.key, this.todos});

  @override
  State<AllTodoScreen> createState() => _AllTodoScreenState();
}

class _AllTodoScreenState extends State<AllTodoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late List<Todo> _todos;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Pending', 'Completed'];
  static const _categories = ['Personal', 'Work', 'Study', 'Shopping'];
  static const _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();

    _todos = [];

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoViewModel>().getAllTodos();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }



  int get _doneCount => _todos.where((t) => t.completed).length;
  int get _pendingCount => _todos.length - _doneCount;

  List<Todo> get _visible {
    Iterable<Todo> list = _todos;
    if (_filter == 'Pending') list = list.where((t) => !t.completed);
    if (_filter == 'Completed') list = list.where((t) => t.completed);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) =>
      t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q));
    }
    return list.toList();
  }

  // ───────────────────────── Actions ─────────────────────────
  void _toggle(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    setState(() => _todos[index] = todo.copyWith(completed: !todo.completed));

  }

  void _delete(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;
    setState(() => _todos.removeAt(index));
    _snack('Task deleted', onUndo: () {
      setState(() => _todos.insert(index.clamp(0, _todos.length), todo));
    });

  }

  void _add(Todo todo) {
    setState(() => _todos.insert(0, todo));
    _snack('Task added');

  }


  int _nextId() {
    if (_todos.isEmpty) return 1;

    final ids = _todos
        .map((todo) => todo.id)
        .whereType<int>()
        .toList();

    if (ids.isEmpty) return 1;

    return ids.reduce((a, b) => a > b ? a : b) + 1;
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

  Future<void> _openAddSheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Personal';
    String priority = 'Medium';
    DateTime? due;

    final result = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            Widget choice(String label, bool selected, VoidCallback onTap) {
              return _PressScale(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: selected
                        ? const LinearGradient(colors: [_C.sky, _C.deepBlue])
                        : null,
                    color: selected ? null : const Color(0xFFEAF5FF),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: selected ? Colors.white : _C.ink,
                    ),
                  ),
                ),
              );
            }

            InputDecoration deco(String hint) => InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _C.muted),
              filled: true,
              fillColor: const Color(0xFFEAF5FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            );

            String dueLabel() {
              if (due == null) return 'No due date';
              return '${due!.day}/${due!.month}/${due!.year}';
            }

            return Padding(
              padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _C.muted.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'New task',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _C.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: deco('Task title'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: deco('Description (optional)'),
                      ),
                      const SizedBox(height: 18),
                      const Text('Category',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: _C.ink)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in _categories)
                            choice(c, category == c,
                                    () => setSheet(() => category = c)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Priority',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: _C.ink)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in _priorities)
                            choice(p, priority == p,
                                    () => setSheet(() => priority = p)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PressScale(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: due ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) setSheet(() => due = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  color: _C.deepBlue, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                dueLabel(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _C.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _PressScale(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddTodoScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                                colors: [_C.sky, _C.deepBlue]),
                            boxShadow: [
                              BoxShadow(
                                color: _C.blue.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Add task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    if (result != null) _add(result);
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

    final viewModel = context.watch<TodoViewModel>();
    if (viewModel.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    _todos = viewModel.todos;
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
                        const SizedBox(height: 16),
                        _reveal(_buildProgressCard(), 0.15, 0.55),
                        const SizedBox(height: 16),
                        _reveal(_buildSearch(), 0.2, 0.6),
                        const SizedBox(height: 14),
                        _reveal(_buildFilters(), 0.25, 0.65),
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
                        key: ValueKey('$_filter|$_query'),
                        physics: const BouncingScrollPhysics(),
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                        padding:
                        const EdgeInsets.fromLTRB(22, 4, 22, 100),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final todo = list[i];
                          return _TodoCard(
                            key: ValueKey(todo.id),
                            todo: todo,
                            index: i,
                            onToggle: () => _toggle(todo),
                            onDelete: () => _delete(todo),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Positioned(
            //   right: 22,
            //   bottom: 26,
            //   child: SafeArea(
            //     child: _reveal(_buildFab(), 0.5, 1.0),
            //   ),
            // ),
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
          child: const Icon(Icons.checklist_rounded, color: Colors.white),
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
                'All Todos',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _todos.isEmpty
                    ? 'Add your first task'
                    : 'Tap the circle to complete, swipe left to delete',
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
            key: ValueKey(_todos.length),
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF64C8FF), Color(0xFF1E88E5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.blue.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              '${_todos.length}',
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

  Widget _buildProgressCard() {
    final total = _todos.length;
    final progress = total == 0 ? 0.0 : _doneCount / total;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
      child: Column(
        children: [
          Row(
            children: [
              _stat('Pending', _pendingCount, Colors.orange),
              _divider(),
              _stat('Completed', _doneCount, _C.green),
              _divider(),
              _stat('Total', total, _C.blue),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE3F1FD),
                      valueColor: const AlwaysStoppedAnimation(_C.green),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: _C.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
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
    height: 30,
    color: _C.muted.withValues(alpha: 0.2),
  );

  Widget _buildSearch() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _C.blue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(
            fontWeight: FontWeight.w600, color: _C.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: const TextStyle(color: _C.muted),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.deepBlue),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
            icon: const Icon(Icons.close_rounded, color: _C.muted),
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
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

  // Widget _buildFab() {
  //   return _PressScale(
  //     onTap: _openAddSheet,
  //     child: Container(
  //       height: 58,
  //       padding: const EdgeInsets.symmetric(horizontal: 22),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(20),
  //         gradient: const LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [_C.sky, _C.deepBlue],
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: _C.blue.withValues(alpha: 0.45),
  //             blurRadius: 20,
  //             offset: const Offset(0, 10),
  //           ),
  //         ],
  //       ),
  //       child: const Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(Icons.add_rounded, color: Colors.white, size: 26),
  //           SizedBox(width: 6),
  //           Text(
  //             'Add task',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w900,
  //               fontSize: 15,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildEmpty() {
    final searching = _query.trim().isNotEmpty;
    final title = _todos.isEmpty
        ? 'No tasks yet'
        : searching
        ? 'No results found'
        : 'No $_filter tasks';
    final subtitle = _todos.isEmpty
        ? 'Tap "Add task" to get started...'
        : 'Try a different search or filter';

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
              child: Icon(
                searching ? Icons.search_off_rounded : Icons.checklist_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _C.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 15, color: _C.muted),
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

// ─────────────────────────── Todo card ───────────────────────────
class _TodoCard extends StatelessWidget {
  final Todo todo;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoCard({
    super.key,
    required this.todo,
    required this.index,
    required this.onToggle,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (todo.priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData get _categoryIcon {
    switch (todo.category) {
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
    final due = todo.dueDate;
    if (due == null) return ('No due date', false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    final diff = d.difference(today).inDays;
    if (diff < 0) return (todo.completed ? _fmt(d) : 'Overdue', !todo.completed);
    if (diff == 0) return ('Today', false);
    if (diff == 1) return ('Tomorrow', false);
    return (_fmt(d), false);
  }

  String _fmt(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final (dueText, overdue) = _dueInfo;
    final delay = 420 + (index.clamp(0, 8) * 90);
    final done = todo.completed;

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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Dismissible(
          key: ValueKey('dismiss_${todo.id}'),
          direction: DismissDirection.endToStart,
          background: const SizedBox.shrink(),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.delete_rounded, color: Colors.white),
              ],
            ),
          ),
          onDismissed: (_) => onDelete(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: done ? 0.8 : 0.95),
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 6,
                      color: done ? _C.green : _priorityColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                        child: Row(
                          children: [
                            _checkButton(),
                            const SizedBox(width: 12),
                            Expanded(child: _content(dueText, overdue)),
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

  Widget _content(String dueText, bool overdue) {
    final done = todo.completed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: done ? _C.muted : _C.ink,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: _C.muted,
          ),
          child: Text(todo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (todo.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            todo.description,
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
            _chip(_categoryIcon, todo.category, _C.blue),
            _chip(
              overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
              dueText,
              overdue ? Colors.red : _C.muted,
            ),
            _chip(Icons.flag_rounded, todo.priority, _priorityColor),
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
    final done = todo.completed;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done
              ? const LinearGradient(colors: [_C.lightGreen, _C.green])
              : null,
          border: Border.all(
            color: done ? Colors.transparent : _C.sky,
            width: 2,
          ),
        ),
        child: AnimatedScale(
          scale: done ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}


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