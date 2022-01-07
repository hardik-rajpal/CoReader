import 'dart:math';

import 'package:CoReader/MinColorPicker.dart';
import 'package:CoReader/Vocabs.dart';
import 'package:CoReader/quote.dart';
import 'package:flutter/cupertino.dart';
import 'package:CoReader/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
class Dashboard extends StatefulWidget {
  final List<Vocab> vocabs;
  Dashboard({required this.vocabs});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late List<Vocab> vocabs;
  late TabController _tabController;
  bool firstRefreshDone = false;
  TextEditingController _bookSizeController = TextEditingController();
  TextEditingController _bookController = TextEditingController();
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
                                    MinColorPicker(
                                      // paletteType: PaletteType.hueWheel,
                                      // enableAlpha: false,
                                      showValueBar: false,
                                      selectedColor: Color(s.book.color),
                                      onSelect: (Color color){
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
                                    s.book = await Constants.getCoverPage(s.book);
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
                        book = await Constants.getCoverPage(book);
                        book = await VocabDatabase.instance.create(book);
                        addBookToVocabs(book);
                      }, altText: '')
                    ],
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
