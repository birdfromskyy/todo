import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ToDoListsScreen extends StatefulWidget {
  @override
  _ToDoListsScreenState createState() => _ToDoListsScreenState();
}

class _ToDoListsScreenState extends State<ToDoListsScreen> {
  Map<String, List<Map<String, dynamic>>> toDoLists = {};
  TextEditingController listNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadLists();
  }

  Future<void> loadLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLists = prefs.getString('toDoLists');
    if (storedLists != null) {
      setState(() {
        toDoLists = Map<String, List<Map<String, dynamic>>>.from(
          jsonDecode(storedLists).map(
            (key, value) => MapEntry(
              key,
              List<Map<String, dynamic>>.from(
                value.map((task) => Map<String, dynamic>.from(task)),
              ),
            ),
          ),
        );
      });
    }
  }

  Future<void> saveLists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('toDoLists', jsonEncode(toDoLists));
  }

  void addList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Создать список'),
        content: TextField(
          controller: listNameController,
          decoration: InputDecoration(hintText: 'Название списка'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String listName = listNameController.text.trim();
              if (listName.isNotEmpty && !toDoLists.containsKey(listName)) {
                setState(() {
                  toDoLists[listName] = [];
                });
                saveLists();
              }
              listNameController.clear();
              Navigator.pop(context);
            },
            child: Text('Создать'),
          ),
        ],
      ),
    );
  }

  void openList(String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListScreen(
          listName: listName,
          tasks: toDoLists[listName]!,
          onUpdate: (updatedTasks) {
            setState(() {
              toDoLists[listName] = updatedTasks;
            });
            saveLists();
          },
          onDelete: () {
            setState(() {
              toDoLists.remove(listName);
            });
            saveLists();
            Navigator.pop(context);
          },
          onRename: (newName) {
            setState(() {
              toDoLists[newName] = toDoLists.remove(listName)!;
            });
            saveLists();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('To-Do')),
      body: ListView(
        children: toDoLists.keys.map((listName) {
          return ListTile(
            title: Text(listName),
            onTap: () => openList(listName),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addList,
        child: Icon(Icons.add),
      ),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final String listName;
  final List<Map<String, dynamic>> tasks;
  final ValueChanged<List<Map<String, dynamic>>> onUpdate;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  TaskListScreen({
    required this.listName,
    required this.tasks,
    required this.onUpdate,
    required this.onDelete,
    required this.onRename,
  });

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TextEditingController taskController = TextEditingController();
  TextEditingController renameController = TextEditingController();

  void addTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Добавить задачу'),
        content: TextField(
          controller: taskController,
          decoration: InputDecoration(hintText: 'Название задачи'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String taskName = taskController.text.trim();
              if (taskName.isNotEmpty) {
                setState(() {
                  widget.tasks.add({
                    'task': taskName,
                    'date': null,
                    'completed': false,
                  });
                });
                widget.onUpdate(widget.tasks);
              }
              taskController.clear();
              Navigator.pop(context);
            },
            child: Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void manageTask(int index) {
    taskController.text = widget.tasks[index]['task'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать задачу'),
        content: TextField(
          controller: taskController,
          decoration: InputDecoration(hintText: 'Название задачи'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String updatedTask = taskController.text.trim();
              if (updatedTask.isNotEmpty) {
                setState(() {
                  widget.tasks[index]['task'] = updatedTask;
                });
                widget.onUpdate(widget.tasks);
              }
              taskController.clear();
              Navigator.pop(context);
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void deleteTask(int index) {
    setState(() {
      widget.tasks.removeAt(index);
    });
    widget.onUpdate(widget.tasks);
  }

  void openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Переименовать список'),
            onTap: () {
              Navigator.pop(context);
              renameList();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text('Удалить список'),
            onTap: () {
              Navigator.pop(context);
              widget.onDelete();
            },
          ),
        ],
      ),
    );
  }

  void renameList() {
    renameController.text = widget.listName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переименовать список'),
        content: TextField(
          controller: renameController,
          decoration: InputDecoration(hintText: 'Новое название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              String newName = renameController.text.trim();
              if (newName.isNotEmpty && newName != widget.listName) {
                widget.onRename(newName);
                Navigator.pop(context);
              }
            },
            child: Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: openMenu,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.tasks[index]['task']),
            onTap: () => manageTask(index),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteTask(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: Icon(Icons.add),
      ),
    );
  }
}
