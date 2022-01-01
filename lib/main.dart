import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:CoReader/Vocabs.dart';
import 'quote.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:http/http.dart';
void main(){
  HttpOverrides.global = MyHttpOverrides();
  return runApp(
      MaterialApp(
        home: HomePage(),
        )
  );
}
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin{
  List<Vocab> vocabs = [
    // Vocab([Word(-1,-1,'flummoxed',"", false)], Book(-1,'The Kite Runner')),
    // Vocab(['centurion'], '21 Lessons from the 21st Century')
  ];

  late TabController _tabController;
  TextEditingController _wordController = TextEditingController();
  TextEditingController _bookController = TextEditingController();

  void refreshWords() async {
    List<Book> allbooks = await VocabDatabase.instance.getAllBooks();
    List<Vocab> newvocabs = [];
    print(allbooks);
    setState(() {
      vocabs.clear();
    });
    allbooks.forEach((book) {
      print(book.name+book.id.toString());
      vocabs.firstWhere((element){return element.book.id == book.id;}, orElse: (){
        setState(() {
          vocabs.add(Vocab([], book));
          _tabController = TabController(length: vocabs.length, vsync: this);
        });
        return vocabs.last;
      });
      print(book.name + "Added to ...");
    });
    List<Word> allwords = await VocabDatabase.instance.getAllWords();
    print(allwords);
    // allwords.forEach((element) {
    //   print(element.word+element.bookId.toString());
    // });
    setState(() {
      vocabs.forEach((element) {
        // print(element.words);
        element.words.clear();
      });
    });
    allwords.forEach((e){
      setState(() {
        int i = vocabs.indexWhere((element) => element.book.id==e.bookId);
        print('index:$i book:${vocabs[i].book.name} word: ${e.word}');
        vocabs[i].words.add(e);
      });
    });

    print(vocabs);
    // setState(() {
    //   vocabs = newvocabs;
    //
    // });
  }

  @override
  void initState(){
    super.initState();
    refreshWords();
    _tabController = TabController(length: vocabs.length, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CoReader'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: vocabs.map((s)=>GestureDetector(
            onLongPress: (){
              showDialog(context: context, builder: (BuildContext context){
                _bookController.text = s.book.name;
                return AlertDialog(
                  title: Text("Edit Book"),
                  content: TextField(
                    controller: _bookController,
                  ),
                  actions: [
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                      ),
                      onPressed: ()async{
                        await VocabDatabase.instance.deleteBook(s.book.id);
                        refreshWords();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.delete_forever),
                      label: Text("Delete"),
                    ),
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.yellow[800]),
                      ),
                      onPressed: ()async{
                        setState(() {
                          s.book.archived = true;
                        });
                        _bookController.clear();
                        await VocabDatabase.instance.updateBook(s.book);
                        Navigator.of(context).pop();
                        refreshWords();
                      },
                      icon: Icon(Icons.archive),
                      label: Text("Archive"),
                    ),
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.green),
                      ),
                      onPressed: ()async{
                        setState(() {
                          s.book.name = _bookController.text;
                        });
                        _bookController.clear();
                        await VocabDatabase.instance.updateBook(s.book);
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.delete_forever),
                      label: Text("Save"),
                    )
                  ],
                );
              });
              print("long press");
            },
            child: Tab(
              text: s.book.name,
            ),
          )).toList(),
        ),

      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 30.0),
        child: FloatingActionButton(
          child: Icon(Icons.book),
          onPressed: (){
          // refreshWords();

              showDialog(
              context: context,
              builder: (BuildContext context){
                return AlertDialog(
                  title: Text("New Book"),
                  content: TextField(
                    controller: _bookController,
                    decoration: InputDecoration(
                        hintText: 'The Great Gatsby',
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                        onPressed: () async {
                          Book book = new Book(-1, _bookController.text, false);
                          book = await VocabDatabase.instance.create(book);
                          refreshWords();
                        _bookController.clear();
                        Navigator.of(context).pop();
                        },
                        child: Text('Save'),
                    )
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child:TabBarView(
                controller: _tabController,
                children: vocabs.map((e){
                  return ListView.builder(
                    itemCount: e.words.length,
                    itemBuilder: (context, index){
                      var f = e.words[index];
                      var color = f.known?Colors.green[500]:Colors.blue;
                      return ElevatedButton.icon(
                        icon:Icon(Icons.info),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(color),
                        ),
                        onPressed: ()async{
                          if(f.def==""){
                            var client = Client();
                            var response = await client.get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/'+f.word));
                            print(response.body);
                            DefinitionBox definitionBox = DefinitionBox(response.body, context, f, this.refreshWords);
                          }
                          else{
                            DefinitionBox definitionBox = DefinitionBox("", context, f, this.refreshWords);
                          }


                        },
                        label: Text(
                          f.word,
                          style: TextStyle(
                              fontSize: 20.0,
                          ),
                        ),
                      );
                    },
                  );
                }
              ).toList(),
            )
          ),
          Expanded(
            flex: 1,
            child: Row(
                children: [
                    Expanded(
                      flex: 10,
                      child: TextField(
                        controller: _wordController,
                        onSubmitted: (wordstr)async{
                          var word = new Word(-1, vocabs[_tabController.index].book.id, _wordController.text, "", false);
                          word = await VocabDatabase.instance.createWord(word);
                          refreshWords();
                          setState((){
                            _wordController.clear();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter Word...',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: ()async{
                          var word = new Word(-1, vocabs[_tabController.index].book.id, _wordController.text, "", false);
                          word = await VocabDatabase.instance.createWord(word);
                          refreshWords();
                          setState((){
                            _wordController.clear();
                          });

                        },
                      ),
                    )
                  ],
                ),
          )
        ],
      ),
    );
  }
}

class DefinitionBox{
  DefinitionBox(String output, BuildContext context, Word wordobj, dynamic refresher){
    String word;
    String definition = wordobj.def;
    bool updated = false;
    word = "";
    if(output!=""){
      dynamic data = jsonDecode(output);
      try{
        definition = data.map((d){
          return d['word']+': \n'+d["meanings"].map((m){
            int numdef = 0;
            return m["definitions"].map((def){
              numdef+=1;
              return '${numdef}. ['+ m["partOfSpeech"] +"] "+ def["definition"];
            }).toList().join("\n");
          }).toList().join("\n\n");
        }).toList().join("\n");
      }
      catch(e){
        word = data['title'];
        definition = data['message'];
      }
    }

    // print(definition);

    var alertDialog = AlertDialog(
      title: Text("Definitions"),
      content: SingleChildScrollView(
          child: Text(definition),
        scrollDirection: Axis.vertical,
      ),
      actions: [
        ElevatedButton.icon(
            onPressed: ()async{
                Navigator.of(context).pop();
                wordobj.def = definition;
                await VocabDatabase.instance.updateWord(wordobj);
            },
            icon: Icon(Icons.thumb_up),
            label: Text("Got it.")
        ),
        ElevatedButton.icon(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(wordobj.known?Colors.yellow:Colors.green),
          ),
            onPressed: ()async{
              wordobj.known = !wordobj.known;
              await VocabDatabase.instance.updateWord(wordobj);
              //mark as known in database.
              Navigator.of(context).pop();
              refresher();
            },
            icon: Icon(wordobj.known?Icons.indeterminate_check_box:Icons.check_box),
            label: wordobj.known?Text("Forgotten"):Text("Known"),
        ),
        ElevatedButton.icon(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.redAccent),
          ),
          onPressed: ()async{
            await VocabDatabase.instance.deleteWord(wordobj.id);
            refresher();
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.delete_forever),
          label: Text("Delete"),
        )
      ],

    );
    showDialog(
        context: context,
        builder: (BuildContext context){
          return alertDialog;
        }
    );
  }
}