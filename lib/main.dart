import 'dart:io';
import 'dart:math';
import 'package:CoReader/MinColorPicker.dart';
import 'package:wakelock/wakelock.dart';
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
class Constants{
  static const String localBlankPage= 'assets/covers/default.jpg';
  static double ValueThres = 200;
  static String glossaryState = 'Glossary';
  static String notebookState = 'Notebook';
  static const int dashboard = 0;
  static const int archive = 1;
  static const int about = 2;
  static const int backup = 3;
  static double getVofHSV(Color color){
    int r, g, b;
    r = color.red; g = color.green; b = color.blue;
    return 0.299*r + 0.587*b + 0.114*b;
  }
  static Future<String> getCoverPage(String inTitle)async{
    var client = Client();
    String title = inTitle.split(' ').join('+');
    // List<String> chars = title.characters.toList();
    if(title.toUpperCase().compareTo(title)==0){

      title = title.characters.toList().join('+');
    }
    String coverpage;
    final String url = 'https://book-cover-api.herokuapp.com/getBookCover?bookTitle=${title}';
    try{
      var response = await client.get(Uri.parse(url));
      Map<String, dynamic> data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        coverpage = data['bookCoverUrl'];
      } else {
        coverpage = Constants.localBlankPage;
      }
    }
    catch(e){
      coverpage = Constants.localBlankPage;
    }
    return coverpage;
  }
  static dynamic getImageWidget(String coverpage){
    if(coverpage.startsWith('http')){
      return CachedNetworkImageProvider(
        coverpage,
      );
    }
    else{
      return AssetImage(coverpage);
    }
  }
  static Future<bool> isConnectedToWeb()async{
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      else{
        return false;
      }
    } on SocketException catch (_) {
      return false;
    }
  }
  static void Toast(String text, BuildContext context){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
    ));
  }
  static Future<String> getResponseBody(Word word)async{
    var client = Client();
    var response = await client.get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/'+word.word));
    return response.body;
  }
  static Future<String> getDefinitionTextFromWeb(Word word)async{
    String body = await getResponseBody(word);
    String definition = "";
    try{
      dynamic data = jsonDecode(body);
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
      // word = wordobj.word;
      definition = "We couldn't get that word. Sorry.";
    }
    return definition;
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
//TODO: Favourite words.
// TODO: enable number+abbreviated (21LF21C)
//TODO:add reading stats: offer number of pages read, glossary changes,
//trend. Will have to Make new db table.
//TODO:don't accept duplicate words, offer settings?
//TODO: add export as json and import as json.
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
                    image:  Constants.getImageWidget(activeVocab.book.cover),
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
        pages = allpages.reversed.toList();
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
          child: Center(
            child: Text(
              e.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: (Constants.getVofHSV(Color(widget.book.color))>Constants.ValueThres)?Colors.black:Colors.white),
            ),
          ),
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
  int currentIndex = 0;bool wakelockOn = false;
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
    bool temp = await Wakelock.enabled;
    setState((){
      wakelockOn = temp;
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
      case (Constants.backup):
        page = MinColorPicker(choices: [], onSelect: (){});
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
          IconButton(
            icon: Icon(
              Icons.download_rounded,
            ),
            onPressed: ()async{
              if(await Constants.isConnectedToWeb()){
                int undefinedWords = 0;
                List<Word> allwords = await VocabDatabase.instance.getAllWords(-1);
                undefinedWords = allwords.where((element) => element.def.length==0).length;
                if(undefinedWords==0){
                  Constants.Toast('All definitions already downloaded', context);
                  return;
                }
                Constants.Toast('Downloading definitions for the glossary.', context);
                for(int i=0;i<allwords.length;i++){
                  if(allwords[i].def.length==0){
                    allwords[i].def = await Constants.getDefinitionTextFromWeb(allwords[i]);
                    VocabDatabase.instance.updateWord(allwords[i]);
                    undefinedWords-=1;
                  }
                  if(undefinedWords==0){
                    Constants.Toast('All definitions downloaded!', context);
                    break;
                  }
                }
                // while(){
                //   //show notif?
                // }

              }
              else{
                Constants.Toast('Not connected to internet.????', context);
              }
            },
          ),
          IconButton(
            icon: Icon(
              (wakelockOn)?Icons.timer:Icons.timer_off,
            ),
            onPressed: ()async{
              if(await Wakelock.enabled){
                await Wakelock.disable();
                setState(() {
                  wakelockOn = false;
                });
                Constants.Toast('Screen timeout enabled.', context);
              }
              else{
                await Wakelock.enable();
                setState(() {
                  wakelockOn = true;
                });
                Constants.Toast('Screen timeout disabled.', context);
              }
            },
          )
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
                    SizedBox(height: 30,),
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
                      'Your reading companion',
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
                    ),
                    menuItem(
                        iconData: Icons.star_border,
                        text: 'Favourites',
                        onTap: (){
                          setState(() {
                            currentSection = Constants.backup;
                          });
                        })
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
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Icon(
                    iconData,
                    color: Colors.black
                ),
              ),
            Text(
                  text,
                  style: TextStyle(
                    fontSize: 20
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



