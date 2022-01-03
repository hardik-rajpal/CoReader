import 'dart:io';
import 'dart:math';
import 'package:CoReader/WordList.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:CoReader/Vocabs.dart';
import 'quote.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class Constants{
  static double ValueThres = 95;
  static String glossaryState = 'Glossary';
  static String notebookState = 'Notebook';
  static double getVofHSV(Color color){
    int r, g, b;
    r = color.red; g = color.green; b = color.blue;
    return 100*(max(r, max(g, b)))/255.0;
  }
}
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
// TODO: enable number+abbreviated (21LF21C)
//TODO: Add notes widget and toggle button
//TODO: add info/about page with sidenavbar
//TODO: add option for background download of defs
class DeleteButton extends StatelessWidget {
  final Function onDelete;
  DeleteButton({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.redAccent),
      ),
      onPressed: (){
        onDelete();
      },
      icon: Icon(Icons.delete_forever),
      label: Text("Delete"),
    );
  }
}
class SaveButton extends StatelessWidget {
  final Function onSave;
  final String altText;
  SaveButton({required this.onSave, required this.altText});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.green),
      ),
      onPressed: (){
        onSave();
      },
      icon: Icon(Icons.check),
      label: Text(altText.length==0?"Save":altText),
    );
  }
}

class MainContent extends StatefulWidget {
  final Vocab activeVocab;
  MainContent({required this.activeVocab});
  @override
  _MainContentState createState() => _MainContentState();
}
class _MainContentState extends State<MainContent> {
  late Vocab activeVocab = widget.activeVocab;
  late List<NotePage> pages = [];
  late dynamic mainContent;
  String currentState = 'Glossary';
  String otherState = 'Notebook';
  dynamic getMainContent(){
    if(currentState=='Glossary'){
          return WordList(words: activeVocab.words,color: Color(activeVocab.book.color), refresher: this.refreshWords,book: activeVocab.book,);
    }
    else{
          return NotesGrid(book: activeVocab.book);
    }

  }




  void refreshWords()async{
    List<Word> allwords = await VocabDatabase.instance.getAllWords(activeVocab.book.id);
    print(allwords.length);
    setState(() {
      activeVocab = Vocab(allwords, activeVocab.book);
      mainContent = getMainContent();
    });
  }
  void refreshPages()async{
    List<NotePage> allpages = await VocabDatabase.instance.getAllPages(activeVocab.book.id);
    setState(() {
      pages = allpages;
    });
  }



  @override
  initState(){
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    setState(() {
      mainContent = getMainContent();
    });
    return Column(
      children: [
        BookMarkBar(
          book: activeVocab.book,
          otherState:otherState,
          stateChanger: (String state){
            setState(() {
              otherState = currentState;
              currentState = state;
            });
          },
        ),
        Expanded(
          child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image:  _HomePageState.getImageWidget(activeVocab.book),
                    fit: BoxFit.fill,
                    opacity: 0.3
                ),
              ),
              child: Builder(
                builder: (context){
                  return getMainContent();
                },
              )
          ),
        )
      ],
    );
  }
}
class BookMarkBar extends StatefulWidget {
  final Book book;
  final String otherState;
  final Function stateChanger;
  BookMarkBar({required this.book, required this.otherState, required this.stateChanger}){
  }

  @override
  State<BookMarkBar> createState() => _BookMarkBarState();
}
class _BookMarkBarState extends State<BookMarkBar> {
  final TextEditingController _bookmarkController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      child:DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.white
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              TextButton(

                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      color: Colors.blueAccent,
                    ),
                    Text('Now @ Page ${widget.book.bookmark}',),
                  ],
                ),
                onPressed: () {
                  _bookmarkController.text = widget.book.bookmark.toString();
                  showDialog(context: context, builder: (context){
                    return AlertDialog(
                      title: Text('Set Bookmark'),
                      content: TextField(
                        autofocus: true,
                        controller: _bookmarkController,
                        keyboardType: TextInputType.number,
                      ),
                      actions: [
                        SaveButton(altText: '',
                            onSave:(){
                          int page = 1;
                          try{
                            page = int.parse(_bookmarkController.text);
                          }
                          catch(e){
                            return;
                          }
                          setState(() {
                            widget.book.bookmark = page;
                          });
                          VocabDatabase.instance.updateBook(widget.book);
                          Navigator.of(context).pop();
                        })
                      ],
                    );
                  });
                },
              ),
              Expanded(
                child: LinearProgressIndicator(
                  backgroundColor: Colors.green[200],
                  color: Colors.green[800],
                  value: widget.book.bookmark/widget.book.size,
                ),
              ),
              Container(
                child: TextButton(
                  child: Text(widget.otherState),
                  onPressed: (){
                    widget.stateChanger(widget.otherState);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
class NotesGrid extends StatefulWidget {
  final Book book;
  final TextEditingController titleController = TextEditingController();
  NotesGrid({required this.book});
  @override
  _NotesGridState createState() => _NotesGridState();

}
class _NotesGridState extends State<NotesGrid> {
  late List<NotePage> pages = [];
  void refreshPages()async{
    List<NotePage> allpages = await VocabDatabase.instance.getAllPages(widget.book.id);
    setState(() {
      pages = allpages;
    });
  }
  @override
  void initState(){
    super.initState();
    refreshPages();
  }
  @override
  Widget build(BuildContext context) {
    List<GridTile> children = [...pages.map((e) => GridTile(
        child: ElevatedButton(
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Color(widget.book.color))
          ),
          child: Text(e.title, style: TextStyle(color: (Constants.getVofHSV(Color(widget.book.color))>Constants.ValueThres)?Colors.black:Colors.white),),
          onPressed: (){
            Navigator.of(context).push(MaterialPageRoute(builder: (context)=>NotePageEditable(page: e, book: widget.book, refresher: refreshPages,)));
          },
          onLongPress: (){
            showDialog(context: context, builder: (context){
              widget.titleController.text = e.title;
              return AlertDialog(
                title: Text('Rename/Delete Note'),
                content: TextField(
                  controller: widget.titleController,
                  decoration: InputDecoration(
                      label: Text('Title')
                  ),
                ),
                actions: [
                  DeleteButton(onDelete: ()async{
                    await VocabDatabase.instance.deletePage(e.id);
                    refreshPages();
                    Navigator.of(context).pop();

                  }),
                  SaveButton(onSave: ()async{
                    setState(() {
                      e.title = widget.titleController.text;
                    });
                    await VocabDatabase.instance.updatePage(e);
                    Navigator.of(context).pop();

                  }, altText: 'Save Title')
                ],
              );
            });
          },
        ))
    ).toList()];
    if(!widget.book.archived){
      children = children.reversed.toList();
      children.add(GridTile(child: ElevatedButton(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Color(widget.book.color))
        ),
        onPressed: (){
          showDialog(context: context, builder: (context){
            var d = DateTime.now();
            Function padder = (String s)=>(s.length>1)?s:('0'+s);
            widget.titleController.text = d.day.toString() +'/'+ d.month.toString()+'/'+d.year.toString()+' @ '+ padder(d.hour.toString())+":"+padder(d.minute.toString());
            return AlertDialog(
              title: Text("New Note"),
              content: Column(
                children: [
                  TextField(
                    autofocus: true,
                    controller: widget.titleController,
                    decoration: InputDecoration(
                        label: Text('Title')
                    ),
                  ),
                ],
              ),
              actions: [
                SaveButton(altText: '',onSave: ()async{
                  Navigator.of(context).pop();
                  NotePage newpage = await VocabDatabase.instance.createPage(NotePage(-1,widget.book.id, '', widget.titleController.text));
                  var temppages = pages.reversed.toList();
                  temppages.add(newpage);
                  setState(() {
                    pages = temppages.reversed.toList();
                  });
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>NotePageEditable(page: newpage, book: widget.book, refresher:refreshPages)));
                })
              ],
            );
          });
        }, child: Icon(
          Icons.add,
          color: (Constants.getVofHSV(Color(widget.book.color))>Constants.ValueThres)?Colors.black:Colors.white),
      )
      ));
      children = children.reversed.toList();
    }


    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.count(
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          crossAxisCount: 4,
          children:children
      ),
    );
  }
}
class NotePageEditable extends StatefulWidget {
  final TextEditingController textController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final Function refresher;
  final Book book;
  final NotePage page;
  NotePageEditable({required this.page, required this.book, required this.refresher});
  @override
  _NotePageEditableState createState() => _NotePageEditableState();
}
class _NotePageEditableState extends State<NotePageEditable> {
  @override
  Widget build(BuildContext context) {
  widget.textController.text = widget.page.content;
    return Scaffold(
      appBar: AppBar(
        title: Text('Note: '+widget.page.title),
      ),
      bottomSheet: DecoratedBox(
        decoration: BoxDecoration(
            color: Color(Colors.white.value)
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SaveButton(onSave: ()async{
                setState(() {
                  widget.page.content = widget.textController.text;
                });
                await VocabDatabase.instance.updatePage(widget.page);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Saved notes."),
                ));
              }, altText: '')
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Card(
                child: TextFormField(
                  autofocus: true,
                  style: TextStyle(
                  ),
                  controller: widget.textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: double.maxFinite.floor(),
                ),
              ),
            ],
          ),
        ),
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
  ];
  // static double ValueThres = 95;
  bool firstRefreshDone = false;
  String otherState = 'Notebook';//can be 'Glossary'
  String currentState = 'Glossary';//can be 'Notebook'
  String coverPageDialogUrl = 'assets/covers/default.jpg';
  List<Vocab> archivedVocabs = [];
  List<NotePage> pages = [];
  late TabController _tabController;
  int currentIndex = 0;
  TextEditingController _bookSizeController = TextEditingController();
  TextEditingController _bookController = TextEditingController();
  void refreshWords() async {
    int tabindex = _tabController.index;
    List<Book> allbooks = await VocabDatabase.instance.getAllBooks();
    print('${allbooks.length} is all books');
    List<Word> allwords = await VocabDatabase.instance.getAllWords(-1);
    List<Book> openBooks = allbooks.where((element) => !element.archived).toList();
    List<Book> archivedBooks = allbooks.where((element) => element.archived).toList();

    setState(() {
      vocabs.clear();
      archivedVocabs.clear();
    });
    for(int i=0;i<openBooks.length;i++){
      setState(() {
        vocabs.add(Vocab(
          allwords.where((element) => element.bookId==openBooks[i].id).toList().reversed.toList(),
          openBooks[i]
        ));
      });
    }
    for(int i=0;i<archivedBooks.length;i++){
      print(archivedBooks.length);
      setState(() {
        archivedVocabs.add(Vocab(
          allwords.where((element) => element.bookId==archivedBooks[i].id).toList().reversed.toList(),
          archivedBooks[i]));
      });
    }
    _tabController = TabController(length: vocabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    if(_tabController.length>0){
      _tabController.animateTo(min(tabindex, _tabController.length-1), duration: Duration());
    }
    setState(() {
      vocabs = vocabs.reversed.toList();
      firstRefreshDone = true;
    });
  }

  _handleTabSelection(){
    setState(() {
      currentIndex = _tabController.index;
    });
  }
  Future<Book> getCoverPage(Book book)async{
    var client = Client();
    String title = book.name.split(' ').join('+');
    // List<String> chars = title.characters.toList();
    if(title.toUpperCase().compareTo(title)==0){

      title = title.characters.toList().join('+');
    }
    final String url = 'https://book-cover-api.herokuapp.com/getBookCover?bookTitle=${title}';
    try{
      var response = await client.get(Uri.parse(url));
      Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        book.cover = data['bookCoverUrl'];
      } else {
        book.cover = 'assets/covers/default.jpg';
      }
    }
    catch(e){
      book.cover = 'assets/covers/default.jpg';
    }
    return book;
  }
  static dynamic getImageWidget(Book book){
    if(book.cover.startsWith('http')){
      return CachedNetworkImageProvider(
        book.cover,
      );
    }
    else{
      return AssetImage(book.cover);
    }
  }
  void addBookToVocabs(Book book){
    List<Vocab> temp = vocabs.reversed.toList();
    temp.add(Vocab([], book));
    setState(() {
      currentIndex = _tabController.index;
      vocabs = temp.reversed.toList();
      _tabController = TabController(length: vocabs.length, vsync: this);
      _tabController.animateTo(currentIndex, duration: Duration());
      if(currentIndex==0){
        _tabController.animateTo(currentIndex+1, duration: Duration());
        _tabController.animateTo(currentIndex, duration: Duration());
      }
    });
  }
  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: vocabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('CoReader'),
        centerTitle: false,
        actions: [
          IconButton(onPressed: (){
            showDialog(
              context: context,
              builder: (BuildContext context){
                _bookSizeController.clear();_bookController.clear();
                return AlertDialog(
                  title: Text("New Book"),
                  content: Column(
                    children: [
                      TextField(
                        autofocus: true,
                        controller: _bookController,
                        decoration: InputDecoration(
                          hintText: 'Book Title',
                        ),
                      ),
                      TextField(
                        controller: _bookSizeController,
                        decoration: InputDecoration(
                          hintText: 'Number of Pages',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  actions: [
                    SaveButton(onSave: ()async{
                      int numpages=1;
                      try{
                        numpages = int.parse(_bookSizeController.text);
                      }
                      catch(e){
                        return;
                      }
                      Book book = new Book(-1, _bookController.text, false, Colors.deepOrange.value, "assets/covers/default.jpg", 1, numpages);
                      _bookController.clear();_bookSizeController.clear();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Getting cover page. Please wait..."),
                      ));
                      book = await getCoverPage(book);
                      book = await VocabDatabase.instance.create(book);
                      addBookToVocabs(book);
                    }, altText: '')
                  ],
                );
              },
            );
          },
              icon: Icon(Icons.add)),
          IconButton(
            icon: Icon(Icons.archive),
            onPressed: (){
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context)=>ArchivePage(data: archivedVocabs,refresher: this.refreshWords,))
              );
            },

          )
        ],
        bottom: TabBar(
          isScrollable: true,

          controller: _tabController,
          tabs: vocabs.map((s){

            return GestureDetector(
            onLongPress: (){
              showDialog(context: context, builder: (BuildContext context){
                _bookController.text = s.book.name;
                _bookSizeController.text = s.book.size.toString();
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
                        SizedBox.fromSize(size: Size.fromHeight(10),),
                        Text('Number of Pages:'),
                        TextField(
                          controller: _bookSizeController,
                          keyboardType: TextInputType.number,
                        ),
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
                    DeleteButton(onDelete: ()async{
                      await VocabDatabase.instance.deleteBook(s.book.id);
                      refreshWords();
                      _bookController.clear();
                      Navigator.of(context).pop();
                    }),
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
                    SaveButton(altText: '',onSave: ()async{
                      int size = 1;
                      try{
                        size = int.parse(_bookSizeController.text);
                      }
                      catch(e){
                        return;
                      }
                      Navigator.of(context).pop();
                      if(s.book.name!=_bookController.text){
                        s.book.name = _bookController.text;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Updating cover page. Please wait..."),
                        ));
                        s.book = await getCoverPage(s.book);
                      }
                      setState(() {
                        s.book.size =  size;
                      });

                      _bookController.clear();_bookSizeController.clear();
                      await VocabDatabase.instance.updateBook(s.book);
                    })
                  ],
                );
              });
              print("long press");
            },
            child:ElevatedButton(
              child:Text(
                s.book.name,
                style: TextStyle(
                  color: (Constants.getVofHSV(Color(s.book.color))>Constants.ValueThres)?Colors.black:Colors.white
                ),
              ),
              onPressed: (){
                _tabController.animateTo(vocabs.indexOf(s));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Color(s.book.color))
              ),
            )
          );
          }).toList(),
        ),

      ),
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child:(_tabController.length>0)?TabBarView(
                controller: _tabController,
                children: vocabs.map((e){
                  return MainContent(activeVocab: e,);
                }
              ).toList(),
            ):Center(
              child: Text(
                (firstRefreshDone)?'No active books so far. Tap the + icon at the top to add a book.':'Loading active books...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,),
            )
          ),
        ],
      ),
    );
  }

  getBookmarkColor(Book book) {
    Color color;
    int bm = book.bookmark; int totpages = book.size;
    if(bm/totpages>90){
      color = Colors.green;
    }
    else if(bm/totpages>50){
      color = Colors.blueAccent;
    }
    else if(bm/totpages>25){
      color = Colors.blueGrey;
    }
    else{
      color = Colors.black;
    }

    return color;
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
                        DeleteButton(onDelete: ()async{
                          await VocabDatabase.instance.deleteBook(vocab.book.id);
                          // refreshWords();
                          Navigator.of(context).pop();
                          setState(() {
                            vocabs.remove(vocab);
                          });

                        }),
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
                      MaterialPageRoute(builder: (context)=>ArchivedDataPage(vocab: vocab,))
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
class ArchivedDataPage extends StatelessWidget {
  final dynamic vocab;
  ArchivedDataPage({this.vocab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vocab.book.name),
      ),
      body: MainContent(activeVocab: vocab,),
    );
  }
}



