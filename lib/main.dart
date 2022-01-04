import 'dart:io';
import 'dart:math';
import 'package:CoReader/About.dart';
import 'package:CoReader/Archive.dart';
import 'package:CoReader/DashBoard.dart';
import 'package:CoReader/WordList.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
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
  static const int dashboard = 0;
  static const int archive = 1;
  static const int about = 2;
  static double getVofHSV(Color color){
    int r, g, b;
    r = color.red; g = color.green; b = color.blue;
    return 100*(max(r, max(g, b)))/255.0;
  }
  static Future<Book> getCoverPage(Book book)async{
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
//TODO: fix messagebar bug in phone
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
    activeVocab = widget.activeVocab;
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
                    image:  Constants.getImageWidget(activeVocab.book),
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
                  if(widget.book.archived){return;}
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
    try{
      setState(() {
        pages = allpages;
      });
    }catch(e){}
  }
  @override
  void initState(){
    super.initState();
    refreshPages();
  }
  @override
  Widget build(BuildContext context) {
    refreshPages();
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
              widget.book.archived?Container():SaveButton(onSave: ()async{
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
                  autofocus: false,
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
  List<Vocab> vocabs = [];
  String coverPageDialogUrl = 'assets/covers/default.jpg';
  List<Vocab> archivedVocabs = [];
  List<NotePage> pages = [];
  late TabController _tabController;
  int currentIndex = 0;
  TextEditingController _bookSizeController = TextEditingController();
  TextEditingController _bookController = TextEditingController();
  int currentSection = Constants.dashboard;
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
    // _tabController.addListener(_handleTabSelection);
    if(_tabController.length>0){
      _tabController.animateTo(min(tabindex, _tabController.length-1), duration: Duration());
    }
    setState(() {
      vocabs = vocabs.reversed.toList();
    });
  }


  @override
  void initState(){
    super.initState();
    _tabController = TabController(length: vocabs.length, vsync: this);
    // _tabController.addListener(_handleTabSelection);
    // refreshWords();

  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var page;
    switch(currentSection){
      case (Constants.dashboard):
        page = Dashboard(
          vocabs: vocabs,
        );
        break;
      case (Constants.archive):
        page = ArchivePage(
          vocabs: archivedVocabs,
          refresher: refreshWords,
        );
        break;
      case (Constants.about):
        page = AboutPage();
        break;
      default:
        page = Dashboard(vocabs: vocabs,);
        break;
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('CoReader'),
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.archive),
          //   onPressed: (){
          //     Navigator.of(context).push(
          //       MaterialPageRoute(builder: (context)=>ArchivePage(data: archivedVocabs,refresher: this.refreshWords,))
          //     );
          //   },
          //
          // )
        ],
      ),
      body: page,
      drawer:Drawer(
        child: Container(
          child: Column(
            children: [
              Container(
                color: Colors.blueAccent,
                width: double.infinity,
                height: 200,
                padding: EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 10),
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        image: DecorationImage(
                          image: AssetImage('icon/icon.png')
                        )
                      ),
                    ),
                    Text(
                        'CoReader',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,

                        )
                    ),
                    Text(
                      'Your reading companion.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15
                      ),
                    )
                  ],
                ),

              ),
              Container(
                padding: EdgeInsets.only(top: 15),
                child: Column(
                  children: [
                    menuItem(
                      iconData: Icons.dashboard_outlined,
                      text: 'Dashboard',
                      onTap: (){
                        setState(() {
                          currentSection = Constants.dashboard;
                        });
                      },
                    ),
                    menuItem(
                        iconData: Icons.archive,
                        text: 'Archive',
                        onTap: (){
                          setState(() {
                            currentSection = Constants.archive;
                          });
                        },
                    ),
                    menuItem(
                        iconData: Icons.info_outline,
                        text: 'About',
                        onTap: (){
                          setState(() {
                            currentSection = Constants.about;
                          });
                        }
                    )
                  ],
                )
              )

            ],
          ),
        ),
      )
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

class menuItem extends StatelessWidget {
  final IconData iconData;
  final String text;
  final Function onTap;
  menuItem({required this.iconData, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Row(
            children: [
              Expanded(
                child: Icon(
                  iconData,
                  color: Colors.black
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 20
                  ),
                ),
              )
            ]
          )
        ),
      )
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



