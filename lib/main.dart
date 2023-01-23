// @dart=2.9
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

//Funcao
void main() {
  runApp(const MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  //Criando um controlador
  final _toDoController = TextEditingController();

  //Criando uma lista
  List _toDoList = [];

  //Criar mapa para desfazer remocao de itens
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos; //Saber de qual posicao foi removido

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    //Atualiza a tela assim que adicionar um elemento na tabela
    setState(() {
      Map<String, dynamic> newToDo = Map();
      //Pegando texto do textfield-titulo da tarefa
      newToDo["title"] = _toDoController.text;
      //Zerando texto como vazio
      _toDoController.text = "";
      //Inicializando o valor como falso
      newToDo["ok"] = false;
      //Adicionando um elemento na lista de tarefas
      _toDoList.add(newToDo);
      //Salvar os dados da lista
      _saveData();
    });
  }

  //Funcao _refresh
  Future<Null> _refresh() async{
    //Esperar 1 segundo para atualizar
    await Future.delayed(Duration(seconds: 1));
    //Argumento a e argumento b
    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) {
          return 1;
        } else if(!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      //Salvar lista ordenada
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                /*
                * Descontinuado
                * RaisedButton
                * color: Colors.blueAccent,
                * child? Text("ADD"),
                * textColor: Colors.white,
                * onPressed: (){},
                * */
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blueAccent),
                  ),
                  onPressed: _addToDo,
                  child: Text('ADD'),
                )
              ],
            ),
          ),
          Expanded(
            /*ListView é um widget para fazer uma lista
             builder é um construtor*/
            child: RefreshIndicator(onRefresh: _refresh,
              child: ListView.builder(
                  padding: const EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      //Direcao para o dismissible
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        //Chama funcao quando o status muda de vedadeiro ou falso
        onChanged: (c) {
          setState(() {
            //Se marcamos ok, armazenamos como c
            _toDoList[index]["ok"] = c;
            //Salvando quando selecioanr tarefa
            _saveData();
          });
        },
      ),
      //Funcao quando arrastar o item para a direita
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          //Salvar lista apos removr item
          _saveData();

          //Aparecer uma informacao de remocao do item
          final snack = SnackBar(
            //Conteundo do snackbar é o titulo da tarefa
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            //Defininado a acao
            action: SnackBarAction(label: "Desfazer",
              onPressed: (){
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
              },
            ),
              duration: Duration(seconds: 2),
          );
          /*depreciado - Scaffold.of(context).showSnackBar(snack);*/
          //Atualizado
          ScaffoldMessenger.of(context).showSnackBar(snack);
        });
      },
    );
  }

//Iniciando leitura e salvando dados em json
//Criando funcao que retornara um arquivo para salvar
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

//Criando funcao para salvar os dados
  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

//Obtendo dados da lista
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
