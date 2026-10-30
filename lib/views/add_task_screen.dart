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
}

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late final AnimationController _enter;

  final _categories = const [
    ('Personal', Icons.person_rounded),
    ('Work', Icons.work_rounded),
    ('Study', Icons.school_rounded),
    ('Shopping', Icons.shopping_bag_rounded),
  ];
  final _priorities = const [
    ('Low', Colors.green),
    ('Medium', Colors.orange),
    ('High', Colors.red),
  ];

  int _category = 0;
  int _priority = 1;
  bool _important = false;
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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

  // ─────────────────────────── Pickers ───────────────────────────
  ThemeData _pickerTheme(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: const ColorScheme.light(
      primary: _C.blue,
      onPrimary: Colors.white,
      onSurface: _C.ink,
    ),
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      builder: (c, child) => Theme(data: _pickerTheme(c), child: child!),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      builder: (c, child) => Theme(data: _pickerTheme(c), child: child!),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ───────────────────────────── Save ─────────────────────────────
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Returned to the previous screen. Replace with your own
    // storage call (database / provider / API) if you have one.
    final todo = Todo(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _categories[_category].$1,
      priority: _priorities[_priority].$1,
      important: _important,
      dueDate: _date,
      dueTime: _time?.format(context),
      completed: false,
    );

    context.read<TodoViewModel>().addTodo(todo);


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _C.deepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text('Todo added successfully ✅'),
      ),
    );
    Navigator.pop(context, todo);
  }

  // ───────────────────────────── UI ─────────────────────────────
  @override
  Widget build(BuildContext context) {
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _reveal(_buildTopBar(), 0.0, 0.35),
                      const SizedBox(height: 22),
                      _reveal(_buildHeading(), 0.08, 0.45),
                      const SizedBox(height: 24),
                      _reveal(_buildInputCard(), 0.16, 0.55),
                      const SizedBox(height: 22),
                      _reveal(_buildLabel('Category'), 0.24, 0.6),
                      const SizedBox(height: 12),
                      _reveal(_buildCategories(), 0.28, 0.65),
                      const SizedBox(height: 22),
                      _reveal(_buildLabel('Priority'), 0.36, 0.7),
                      const SizedBox(height: 12),
                      _reveal(_buildPriorities(), 0.4, 0.75),
                      const SizedBox(height: 22),
                      _reveal(_buildLabel('Due date & time'), 0.48, 0.8),
                      const SizedBox(height: 12),
                      _reveal(_buildDateTimeRow(), 0.52, 0.85),
                      const SizedBox(height: 18),
                      _reveal(_buildImportantTile(), 0.58, 0.9),
                      const SizedBox(height: 28),
                      _reveal(_buildSaveButton(), 0.64, 1.0),
                    ],
                  ),
                ),
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
          child: _glass(
            const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _C.deepBlue),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Todo',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _C.ink,
            height: 1.1,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'What do you want to get done?',
          style: TextStyle(fontSize: 16, color: _C.muted),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextFormField(
            controller: _titleCtrl,
            maxLength: 50,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _C.ink,
            ),
            decoration: _inputDecoration('Task title', Icons.edit_rounded),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter a title'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 15, color: _C.ink),
            decoration:
            _inputDecoration('Description (optional)', Icons.notes_rounded),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.muted, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _C.sky),
      filled: true,
      fillColor: const Color(0xFFF2F9FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_C.blue, 1.6),
      errorBorder: border(Colors.redAccent),
      focusedErrorBorder: border(Colors.redAccent, 1.6),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: _C.ink,
    ),
  );

  Widget _buildCategories() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_categories.length, (i) {
        final selected = _category == i;
        return _PressScale(
          onTap: () => setState(() => _category = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: selected
                  ? const LinearGradient(colors: [_C.sky, _C.deepBlue])
                  : null,
              color: selected ? null : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _C.blue.withValues(alpha: selected ? 0.3 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categories[i].$2,
                  size: 18,
                  color: selected ? Colors.white : _C.sky,
                ),
                const SizedBox(width: 8),
                Text(
                  _categories[i].$1,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : _C.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPriorities() {
    return Row(
      children: List.generate(_priorities.length, (i) {
        final selected = _priority == i;
        final color = _priorities[i].$2;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _priorities.length - 1 ? 0 : 10),
            child: _PressScale(
              onTap: () => setState(() => _priority = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: selected ? color.withValues(alpha: 0.14) : Colors.white,
                  border: Border.all(
                    color: selected ? color : Colors.transparent,
                    width: 1.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.blue.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag_rounded, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      _priorities[i].$1,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: selected ? color : _C.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _pickerTile(
            icon: Icons.calendar_month_rounded,
            text: _date == null ? 'Pick date' : _formatDate(_date!),
            active: _date != null,
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pickerTile(
            icon: Icons.access_time_rounded,
            text: _time == null ? 'Pick time' : _time!.format(context),
            active: _time != null,
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String text,
    required bool active,
    required VoidCallback onTap,
  }) {
    return _PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: _cardDecoration(radius: 18),
        child: Row(
          children: [
            Icon(icon, color: active ? _C.blue : _C.sky, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  color: active ? _C.ink : _C.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              _important ? Icons.star_rounded : Icons.star_border_rounded,
              key: ValueKey(_important),
              color: Colors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Mark as important',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.ink,
              ),
            ),
          ),
          Switch(
            value: _important,
            activeThumbColor: Colors.white,
            activeTrackColor: _C.blue,
            onChanged: (v) => setState(() => _important = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return _PressScale(
      onTap: _save,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64C8FF), Color(0xFF1E88E5)],
          ),
          boxShadow: [
            BoxShadow(
              color: _C.blue.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'Save Todo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Helpers ───────────────────────────
  BoxDecoration _cardDecoration({double radius = 24}) => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white),
    boxShadow: [
      BoxShadow(
        color: _C.blue.withValues(alpha: 0.12),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
    ],
  );

  Widget _glass(Widget child) => Container(
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
    child: child,
  );

  Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}