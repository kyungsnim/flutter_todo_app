import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  bool isDone; // 현재 진행여부
  String title; // 할일

  Todo(this.title, {this.isDone = false});
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: ToDoListPage(),
    );
  }
}

class ToDoListPage extends StatefulWidget {
  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  // 할일 문자열 다룰 컨트롤러
  var _todoController = TextEditingController();

  @override
  void dispose() {
    _todoController.dispose(); // 컨트롤러는 종료시 반드시 해제해줘야 함
    super.dispose();
  }

  Widget _buildItemWidget(DocumentSnapshot doc) { // DocumentSnapshot 추가
    // title은 생성시 필수값, isDone은 옵셔널
    final todo = Todo(doc['title'], isDone: doc['isDone']);

    return ListTile(
      onTap: () => _toggleTodo(doc), // 완료/미완료 상태변경
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _deleteTodo(doc), // 할일 삭제하기
      ),
      title: Text(
        todo.title,
        style: todo.isDone? // 할일 완료 여부로 스타일 변경
          TextStyle(
            decoration: TextDecoration.lineThrough, // 취소선
            fontStyle: FontStyle.italic, // 이탤릭체
          ) : null, // 할일 중이면 아무 작업 안함
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('남은 할 일'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                  ),
                ),
                RaisedButton(
                  onPressed: () => _addTodo(Todo(_todoController.text)),
                  color: Colors.green,
                  child: Text('추가하기', style: TextStyle(color: Colors.white),),
                )
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream: Firestore.instance.collection('todo').snapshots(), // 1
              builder: (context, snapshot) { // 2
                if(!snapshot.hasData) { // 3
                  return CircularProgressIndicator();
                }
                final documents = snapshot.data.documents; // 4
                return Expanded(
                  child: ListView(
                    children: documents.map((doc) => _buildItemWidget(doc)).toList(), // 5
                  ),
                );
              }
            )
          ],
        ),
      ),
    );
  }

  // 할 일 추가 메소드
  void _addTodo(Todo todo) {
    Firestore.instance
      .collection('todo')
      .add({'title': todo.title, 'isDone': todo.isDone});
      _todoController.text = ''; // 할일을 리스트에 추가하며 할일 입력 필드 비우기
  }

  // 할 일 삭제 메소드
  void _deleteTodo(DocumentSnapshot doc) {
    Firestore.instance.collection('todo').document(doc.documentID).delete();
  }

  // 할 일 완료/미완료 메소드
  void _toggleTodo(DocumentSnapshot doc) {
    Firestore.instance
      .collection('todo').document(doc.documentID).updateData({'isDone': !doc['isDone']});
  }
}