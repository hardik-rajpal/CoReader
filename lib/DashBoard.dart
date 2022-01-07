import 'dart:math';

import 'package:CoReader/MinColorPicker.dart';
import 'package:CoReader/Vocabs.dart';
import 'package:CoReader/quote.dart';
import 'package:flutter/cupertino.dart';
import 'package:CoReader/main.dart';
import 'package:flutter/material.dart';
class Dashboard extends StatefulWidget {
  final List<Vocab> vocabs;
  Dashboard({required this.vocabs});

  @override
  _DashboardState createState() => _DashboardState();
}
class CreateDialog extends StatefulWidget {
  Function onAdd;
  CreateDialog({required this.onAdd});
  @override
  _CreateDialogState createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog> {
  TextEditingController _bookController = TextEditingController();
  TextEditingController _bookSizeController = TextEditingController();
  String coverURL = Constants.localBlankPage;
  bool CoverChecked = false;
  @override
  void initState() {

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // _bookController.clear(); _bookSizeController.clear();
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
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: Constants.getImageWidget(coverURL)
                )
              ),
              child: Row(
                children: [Expanded(
                  child: Container(),
                ),]
              ),
            ),
          )
        ],
      ),
      actions: [
        ElevatedButton.icon(
          icon: Icon(Icons.network_wifi),
            label: Text('Get Cover'),
            onPressed: ()async{
            setState(() {
              CoverChecked = true;
            });
              if(!(await Constants.isConnectedToWeb())){
                Constants.Toast("No internet connection", context);
                return;
              }
              Constants.Toast('Getting cover page', context);
              String newCoverURL = await Constants.getCoverPage(_bookController.text);
              setState(() {
                coverURL = newCoverURL;
                // print(newCoverURL);
                // _bookController. = widget.bookTitle;
                // print(widget.bookTitle);
                // _bookSizeController.text = widget.numPages.toString();
              });
            },
        ),
        CoverChecked?SaveButton(onSave: ()async{
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
          book.cover = coverURL;
          book = await VocabDatabase.instance.create(book);
          widget.onAdd(book);
        }, altText: ''):Container()
      ],
    );
  }
}

class EditDialog extends StatefulWidget {
  // Function onSave;
  Vocab activeVocab;
  Function refresher;
  EditDialog({required this.refresher, required this.activeVocab});

  @override
  _EditDialogState createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late Vocab s;
  TextEditingController _bookController  = TextEditingController();
  TextEditingController _bookSizeController = TextEditingController();
  dynamic updateCoverButton;
  bool titleChanged = false;
  Color bookColor = Colors.grey;
  Future<Book> updateCover()async{
    if(!(await Constants.isConnectedToWeb())){
      Constants.Toast('No internet connection.', context);
      return s.book;
    }
    Constants.Toast("Updating cover page. Please wait...", context);
    String cover = await Constants.getCoverPage(_bookController.text);
    setState(() {
      bookColor = Color(s.book.color);
      s.book.cover = cover;
    });
    return s.book;
  }
  @override
  void initState() {
    s = widget.activeVocab;
    setState(() {
      _bookController.text = s.book.name;
      _bookSizeController.text = s.book.size.toString();
      bookColor = Color(s.book.color);
      _bookController.addListener(() {
        setState(() {
          titleChanged = _bookController.text.compareTo(s.book.name)==0;
        });
      });
    });
    updateCoverButton = ElevatedButton.icon(
        onPressed: ()async{
          await updateCover();
        },
        icon: Icon(Icons.network_wifi),
        label: Text('Get Cover')
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
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
            MinColorPicker(
              // paletteType: PaletteType.hueWheel,
              // enableAlpha: false,
              showValueBar: true,
              selectedColor: bookColor,
              onSelect: (Color color){
                setState(() {
                  bookColor = color;
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: Constants.getImageWidget(s.book.cover)
                        )
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: updateCoverButton,
                )
              ],
            )
          ],
        ),
      ),
      actions: [
        DeleteButton(onDelete: ()async{
          await VocabDatabase.instance.deleteBook(s.book.id);
          widget.refresher();
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
            widget.refresher();
          },
          icon: Icon(Icons.archive),
          label: Text("Archive"),
        ),
        SaveButton(altText: '',onSave: ()async{
          int size = 1;
          print(_bookController.text + s.book.name);
          setState(() {
            titleChanged = !(_bookController.text.compareTo(s.book.name)==0);
          });
          if(titleChanged){
            await updateCover();
          }
          print(titleChanged);
          try{
            size = int.parse(_bookSizeController.text);
          }
          catch(e){
            return;
          }
          Navigator.of(context).pop();
          setState(() {
            s.book.name = _bookController.text;
            s.book.size =  size;
            s.book.color = bookColor.value;
          });
          _bookController.clear();_bookSizeController.clear();
          print(titleChanged);
          await VocabDatabase.instance.updateBook(s.book);
          widget.refresher();
        })
      ],
    );
  }
}


class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late List<Vocab> vocabs;
  late TabController _tabController;
  bool firstRefreshDone = false;
  void refreshWords() async {
    int tabindex = _tabController.index;
    List<Book> allbooks = await VocabDatabase.instance.getAllBooks();
    print('${allbooks.length} is all books');
    List<Word> allwords = await VocabDatabase.instance.getAllWords(-1);
    List<Book> openBooks = allbooks.where((element) => !element.archived).toList();
    setState(() {
      vocabs.clear();
    });
    for(int i=0;i<openBooks.length;i++){
      setState(() {
        vocabs.add(Vocab(
            allwords.where((element) => element.bookId==openBooks[i].id).toList().reversed.toList(),
            openBooks[i]
        ));
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
      // currentIndex = _tabController.index;
    });
  }
  void addBookToVocabs(Book book){
    List<Vocab> temp = vocabs.reversed.toList();
    temp.add(Vocab([], book));
    setState(() {
      // currentIndex = _tabController.index;
      vocabs = temp.reversed.toList();
      _tabController = TabController(length: vocabs.length, vsync: this);
      // _tabController.addListener(_handleTabSelection);
      // if(_tabController.length>0){
      //   _tabController.animateTo(currentIndex, duration: Duration());
      // }

    });
  }
  @override
  void initState() {
    vocabs = widget.vocabs;
    _tabController = TabController(vsync: this, length: vocabs.length);
    refreshWords();

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[100],
                child: TabBar(
                  isScrollable: true,
                  controller: _tabController,
                  padding: EdgeInsets.all(0),
                  indicatorPadding: EdgeInsets.all(0),
                  tabs: vocabs.map((s){
                    return GestureDetector(
                        onLongPress: (){
                          showDialog(context: context, builder: (BuildContext context){
                            return EditDialog(
                              refresher:this.refreshWords,
                              activeVocab: s,
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
            ),
            ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(CircleBorder())
              ),
              child: Icon(Icons.add),
                onPressed: (){
              showDialog(
                context: context,
                builder: (BuildContext context){

                  return CreateDialog(
                    onAdd: (Book book){
                      addBookToVocabs(book);
                    },
                  );
                },
              );
            },
          ),

          ],
        ),
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
    );
  }
}
