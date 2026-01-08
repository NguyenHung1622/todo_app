import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  List<Task> _tasks = [];
  bool _showOnlyPending = false;
  String _selectedCategoryFilter = 'Tất cả';
  final List<String> _categories = ['Chung', 'Công việc', 'Học tập', 'Cá nhân'];
  final List<String> _filterOptions = ['Tất cả', 'Chung', 'Công việc', 'Học tập', 'Cá nhân'];

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermission();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await DatabaseService.getTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _addTask(String title, DateTime time, String category) async {
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      time: time,
      category: category,
    );

    await DatabaseService.insertTask(task);
    _loadTasks();

    NotificationService.scheduleNotification(task.id, task.title, task.time);
    if (mounted) Navigator.pop(context);
  }

  void _toggleTask(Task task) async {
    task.isDone = !task.isDone;
    await DatabaseService.updateTask(task);
    _loadTasks();

    if (task.isDone) {
      NotificationService.cancelNotification(task.id);
    } else {
      NotificationService.scheduleNotification(task.id, task.title, task.time);
    }
  }

  void _deleteTask(Task task) async {
    NotificationService.cancelNotification(task.id);
    await DatabaseService.deleteTask(task.id);
    _loadTasks();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa: ${task.title}')),
      );
    }
  }

  void _showAddDialog() {
    String title = '';
    DateTime time = DateTime.now();
    String category = _categories[0];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF3C3A4F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thêm công việc mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Bạn cần làm gì?',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF3C3A4F),
                    value: category,
                    items: _categories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (v) => setDialog(() => category = v!),
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      labelStyle: TextStyle(color: Color(0xFFFF6B81)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFFFF6B81)),
                    title: Text(
                      DateFormat('dd/MM/yyyy - HH:mm').format(time),
                      style: const TextStyle(fontSize: 14),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: time,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date == null) return;

                      final tod = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(time),
                      );
                      if (tod == null) return;

                      setDialog(() {
                        time = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          tod.hour,
                          tod.minute,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B81),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (title.trim().isNotEmpty) {
                    _addTask(title, time, category);
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic lọc dữ liệu
    List<Task> filteredTasks = _tasks;
    if (_showOnlyPending) {
      filteredTasks = filteredTasks.where((t) => !t.isDone).toList();
    }
    if (_selectedCategoryFilter != 'Tất cả') {
      filteredTasks = filteredTasks.where((t) => t.category == _selectedCategoryFilter).toList();
    }

    final completedCount = _tasks.where((e) => e.isDone).length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFF6B81),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Công việc',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(
                      _showOnlyPending ? Icons.check_circle : Icons.check_circle_outline,
                      color: _showOnlyPending ? const Color(0xFFFF6B81) : Colors.white70,
                    ),
                    onPressed: () => setState(() => _showOnlyPending = !_showOnlyPending),
                    tooltip: 'Chỉ hiện việc chưa xong',
                  ),
                ],
              ),
            ),

            // Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B81), Color(0xFFFFA07A)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B81).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tiến độ hoàn thành', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '$completedCount / ${_tasks.length} đã xong',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _tasks.isEmpty ? 0 : completedCount / _tasks.length,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          strokeWidth: 6,
                        ),
                        Text(
                          _tasks.isEmpty ? '0%' : '${((completedCount / _tasks.length) * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Category Filter Bar (NHƯ TRONG ẢNH CỦA BẠN)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  final category = _filterOptions[index];
                  final isSelected = _selectedCategoryFilter == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryFilter = category;
                        });
                      },
                      selectedColor: const Color(0xFF4A90E2).withOpacity(0.8), // Màu xanh giống ảnh của bạn
                      backgroundColor: const Color(0xFF3C3A4F),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // Task List
            Expanded(
              child: filteredTasks.isEmpty
                  ? const Center(
                      child: Text('Không có công việc nào ở mục này', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredTasks.length,
                      itemBuilder: (_, i) {
                        final task = filteredTasks[i];
                        return Dismissible(
                          key: ValueKey(task.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteTask(task),
                          background: Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C3A4F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              leading: Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: task.isDone,
                                  activeColor: const Color(0xFFFF6B81),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  onChanged: (_) => _toggleTask(task),
                                ),
                              ),
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: task.isDone ? TextDecoration.lineThrough : null,
                                  color: task.isDone ? Colors.grey : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('HH:mm - dd/MM').format(task.time),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        task.category,
                                        style: const TextStyle(color: Color(0xFFFF6B81), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
