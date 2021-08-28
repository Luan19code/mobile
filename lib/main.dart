import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.dark,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _toDoController = TextEditingController();
  TextEditingController _toEditController = TextEditingController();
  List _toDoList = [];
  //
  Map<String, dynamic> _lastRemove;
  //
  int _lastRemovePos;
  //
  double heightTeme = 20;

  @override
  void initState() {
    super.initState();
    //
   
    //
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
    //
  }

  void _addToDo() {
    if (_toDoController.text.isNotEmpty) {
      setState(() {
        Map<String, dynamic> newToDo = Map();
        newToDo["title"] = _toDoController.text;
        _toDoController.text = "";
        newToDo["ok"] = false;
        _toDoList.add(newToDo);
        _saveData();
      });
    } else {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Não pode ser adicionada uma Tarefa vazia"),
        duration: Duration(seconds: 5),
      ));
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"])
          return 1;
        else if (!a["ok"] && b["ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              controller: _toDoController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "Nova Tarefa",
                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
          ),
          // SizedBox(
          //   height: 10,
          // ),
          Container(
            height: 40,
            margin: EdgeInsets.symmetric(vertical: 10),
            width: MediaQuery.of(context).size.width * 0.8,
            child: ElevatedButton(
              child: Text("Adicionar Tarefa"),
              onPressed: _addToDo,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Column(
      children: [
        Divider(),
        Dismissible(
          key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
          background: Container(
            color: Colors.red,
            child: Align(
              alignment: Alignment(-0.9, 0),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
          direction: DismissDirection.startToEnd,
          child: InkWell(
            onLongPress: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      "Deletar",
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    content: Text(
                      "Deseja deletar essa tarefa?",
                      textAlign: TextAlign.center,
                    ),
                    actions: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: Text("Não"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text("Sim"),
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(
                                () {
                                  _removeItem(index);
                                },
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  );
                },
              );
            },
            child: CheckboxListTile(
              title: InkWell(
                  onTap: () {
                    _toEditController.text = _toDoList[index]["title"];
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            "Editar",
                            textAlign: TextAlign.center,
                          ),
                          content: TextFormField(
                            controller: _toEditController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: "Editar Descrição",
                              alignLabelWithHint: true,
                              labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                          ),
                          actions: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  child: Text("Salvar"),
                                  onPressed: () {
                                    _toDoList[index]["title"] =
                                        _toEditController.text;
                                    Navigator.of(context).pop();
                                    _saveData();
                                  },
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        _toDoList[index]["title"],
                      ),
                    ],
                  )),
              value: _toDoList[index]["ok"],
              secondary: CircleAvatar(
                child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.alarm),
              ),
              onChanged: (value) {
                setState(() {
                  _toDoList[index]["ok"] = value;
                  _saveData();
                });
              },
            ),
          ),
          onDismissed: (direction) {
            setState(
              () {
                _removeItem(index);
              },
            );
          },
        ),
        if (index == 0)
          AnimatedContainer(
            duration: Duration(seconds: 3),
            curve: Curves.fastOutSlowIn,
            height: heightTeme,
            child: Text(
              "| Você pode arrastar para o lado para deletar |",
              style: TextStyle(color: Colors.red[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _removeItem(index) {
    _lastRemove = Map.from(_toDoList[index]);
    _lastRemovePos = index;
    _toDoList.removeAt(index);
    _saveData();
    final snack = SnackBar(
      content: Text("Tarefa ${_lastRemove["title"]} removida!"),
      action: SnackBarAction(
          label: "Desfazer",
          textColor: Colors.red,
          onPressed: () {
            setState(() {
              _toDoList.insert(_lastRemovePos, _lastRemove);
              _saveData();
            });
          }),
      duration: Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
