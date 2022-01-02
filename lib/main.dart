import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:CoReader/Vocabs.dart';
import 'quote.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
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
class WordList extends StatelessWidget{
  final dynamic e;
  final dynamic refresher;
  WordList({@required this.e, this.refresher});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
            image:  _HomePageState.getImageWidget(e.book),
            fit: BoxFit.fill,
            opacity: 0.3
        ),
      ),
      child: ListView.builder(
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
                DefinitionBox definitionBox = DefinitionBox(response.body, context, f, this.refresher);
              }
              else{
                DefinitionBox definitionBox = DefinitionBox("", context, f, this.refresher);
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
      ),
    );
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
  List<Vocab> archivedVocabs = [];
  late TabController _tabController;
  TextEditingController _wordController = TextEditingController();
  TextEditingController _bookController = TextEditingController();
  void refreshWords() async {
    int tabindex = _tabController.index;
    List<Book> allbooks = await VocabDatabase.instance.getAllBooks();
    print('${allbooks.length} is all books');
    List<Word> allwords = await VocabDatabase.instance.getAllWords();

    List<Book> openBooks = allbooks.where((element) => !element.archived).toList();
    List<Book> archivedBooks = allbooks.where((element) => element.archived).toList();

    setState(() {
      vocabs.clear();
      archivedVocabs.clear();
    });
    for(int i=0;i<openBooks.length;i++){
      setState(() {
        vocabs.add(Vocab(allwords.where((element) => element.bookId==openBooks[i].id).toList(), openBooks[i]));
      });
    }
    for(int i=0;i<archivedBooks.length;i++){
      print(archivedBooks.length);
      setState(() {
        archivedVocabs.add(Vocab(allwords.where((element) => element.bookId==archivedBooks[i].id).toList(), archivedBooks[i]));
      });
    }
    _tabController = TabController(length: vocabs.length, vsync: this);
    if(_tabController.length>0){
      _tabController.animateTo(min(tabindex, _tabController.length-1), duration: Duration());
    }
    setState(() {
      vocabs = vocabs.reversed.toList();
    });
  }
  Future<Book> getCoverPage(Book book)async{
    var client = Client();
    String title = book.name.split(' ').join('+');
    final String url = 'https://bookcoverapi.herokuapp.com/getBookCover?bookTitle=${title}';
    var response = await client.get(Uri.parse(url));
    Map<String, dynamic> data = jsonDecode(response.body);
    if(data['status']=='success'){
      book.cover = data['bookCoverUrl'];
    }
    else{
      book.cover = 'assets/covers/default.jpg';
    }
    return book;
  }
  static dynamic getImageWidget(Book book){
    if(book.cover.startsWith('http')){
      return NetworkImage(book.cover);
    }
    else{
      return AssetImage(book.cover);
    }
  }
  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: vocabs.length, vsync: this);
    refreshWords();
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: Row(
        children: (_tabController.length>0)?[
          Expanded(
            flex: 10,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
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
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(Icons.send),
              onPressed: ()async{
                if(_wordController.text.length==0){return;}
                var word = new Word(-1, vocabs[_tabController.index].book.id, _wordController.text, "", false);
                word = await VocabDatabase.instance.createWord(word);
                refreshWords();
                setState((){
                  _wordController.clear();
                });

              },
            ),
          )
        ] : [],
      ),

      appBar: AppBar(
        title: Text('CoReader'),
        centerTitle: false,
        actions: [
          IconButton(onPressed: (){
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
                        Book book = new Book(-1, _bookController.text, false, Colors.blueAccent.value, "");
                        _bookController.clear();
                        Navigator.of(context).pop();
                        showDialog(context: context, builder:(context){
                          return AlertDialog(
                            title: Text('Wait for the cover page...'),
                            actions: [
                              ElevatedButton(onPressed: (){
                                Navigator.of(context).pop();
                              }, child: Text('OK'))
                            ],

                          );
                        });
                        book = await getCoverPage(book);
                        book = await VocabDatabase.instance.create(book);
                        refreshWords();
                        Navigator.of(context).pop();

                      },
                      child: Text('Save'),
                    )
                  ],
                );
              },
            );
          },
              icon: Icon(Icons.add)),
          IconButton(
            onPressed: (){
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context)=>ArchivePage(data: archivedVocabs,refresher: this.refreshWords,))
              );
            },
            icon: Icon(Icons.archive)
          )
        ],
        bottom: TabBar(
          isScrollable: true,

          controller: _tabController,
          tabs: vocabs.map((s)=>GestureDetector(
            onLongPress: (){
              showDialog(context: context, builder: (BuildContext context){
                _bookController.text = s.book.name;
                return AlertDialog(
                  title: Text("Edit Book"),
                  content: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name: ',),
                        TextField(
                          controller: _bookController,
                        ),

                        // MaterialColorPicker(
                        //   allowShades: false,
                        //   selectedColor: Color(s.book.color),
                        //   onColorChange: (Color color){
                        //     setState(() {
                        //       s.book.color = color.value;
                        //     });
                        //   },
                        // )
                        ColorPicker(
                          paletteType: PaletteType.hueWheel,
                          enableAlpha: false,
                          pickerColor: Color(s.book.color),
                          onColorChanged: (Color color){
                            setState(() {
                              s.book.color = color.value;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton.icon(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                      ),
                      onPressed: ()async{
                        await VocabDatabase.instance.deleteBook(s.book.id);
                        refreshWords();
                        _bookController.clear();
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
                      icon: Icon(Icons.save),
                      label: Text("Save"),
                    )
                  ],
                );
              });
              print("long press");
            },
            child:ElevatedButton(
              child:Text(s.book.name),
              onPressed: (){
                _tabController.animateTo(vocabs.indexOf(s));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(s.book.color))
              ),
            )
          )).toList(),
        ),

      ),
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child:(_tabController.length>0)?TabBarView(
                controller: _tabController,
                children: vocabs.map((e){
                  return WordList(e: e,refresher: this.refreshWords,);
                }
              ).toList(),
            ):Center(
              child: Text(
                'No active books so far. Tap the + icon at the top to add a book.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,),
            )
          ),
          // Expanded(
          //   flex: 1,
          //   child: Row(
          //       children: [
          //
          //         ],
          //       ),
          // )
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

      try{
        dynamic data = jsonDecode(output);
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
        word = wordobj.word;
        definition = "We couldn't get that word. Sorry.";
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
class ArchivePage extends StatefulWidget {
  final dynamic data;
  final dynamic refresher;
  const ArchivePage({Key? key, this.data, this.refresher}) : super(key: key);

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  @override
  Widget build(BuildContext context) {
    List<Vocab> vocabs = widget.data;
    return Scaffold(
      appBar: AppBar(
        title: Text('Archive'),
      ),
      body: (vocabs.length>0)?GridView.count(
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        crossAxisCount: 4,
        children: vocabs.map((vocab){
          return GestureDetector(
            child: GridTile(
              child: ElevatedButton(
                onLongPress: (){
                  showDialog(context: context, builder: (context){
                    return AlertDialog(
                      title: Text(vocab.book.name),
                      actions: [
                        ElevatedButton.icon(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.redAccent),
                          ),
                          onPressed: ()async{
                            await VocabDatabase.instance.deleteBook(vocab.book.id);
                            // refreshWords();
                            Navigator.of(context).pop();
                            setState(() {
                              vocabs.remove(vocab);
                            });
                          },
                          icon: Icon(Icons.delete_forever),
                          label: Text("Delete"),
                        ),
                        ElevatedButton.icon(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.pink[800]),
                          ),
                          onPressed: ()async{
                            // setState(() {
                              vocab.book.archived = false;

                            await VocabDatabase.instance.updateBook(vocab.book);
                            Navigator.of(context).pop();
                            widget.refresher();
                            setState(() {
                              vocabs.remove(vocab);

                            });
                            },
                          icon: Icon(Icons.unarchive),
                          label: Text("UnArchive"),
                        ),
                      ],
                    );
                  });
                },
                onPressed: (){
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context)=>WordListPage(vocab: vocab,))
                  );
                },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(vocab.book.color)),
                  ),
                child: (vocab.book.cover!='assets/cover/default.jpg')?Image(
                  image: _HomePageState.getImageWidget(vocab.book),
                ):Text(vocab.book.name),
              ),
            ),
          );
        }).toList(),
      ):Center(
          child: Text(
            'No books archived yet. Your archived books will appear here. (Long Press the tab to archive the book.)',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 20.0,
              fontWeight: FontWeight.bold,

            ),
            textAlign: TextAlign.center,
          ),
      ),
    );
  }
}


class WordListPage extends StatelessWidget {
  final dynamic vocab;
  WordListPage({this.vocab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vocab.book.name),
      ),
      body: WordList(e: this.vocab,refresher: (){},),
    );
  }
}



