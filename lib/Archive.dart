import 'package:CoReader/Vocabs.dart';
import 'package:CoReader/main.dart';
import 'package:CoReader/quote.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArchivePage extends StatefulWidget {
  final List<Vocab> vocabs;
  final Function refresher;
  ArchivePage({required this.vocabs, required this.refresher});
  @override
  State<ArchivePage> createState() => _ArchivePageState();
}
class _ArchivePageState extends State<ArchivePage> {
  List<Vocab> archivedVocabs = [];
  void refreshArchivedBooks()async{
    List<Book> allbooks = await VocabDatabase.instance.getAllBooks();
    print('${allbooks.length} is all books');
    List<Word> allwords = await VocabDatabase.instance.getAllWords(-1);
    List<Book> archivedBooks = allbooks.where((element) => element.archived).toList();
    setState(() {
      archivedVocabs.clear();
    });
    for(int i=0;i<archivedBooks.length;i++){
      print(archivedBooks.length);
      setState(() {
        archivedVocabs.add(Vocab(
            allwords.where((element) => element.bookId==archivedBooks[i].id).toList().reversed.toList(),
            archivedBooks[i]));
      });
    }
    setState(() {
      archivedVocabs = archivedVocabs.reversed.toList();
    });
  }

  @override
  void initState() {
    refreshArchivedBooks();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    refreshArchivedBooks();
    return (archivedVocabs.length>0)?GridView.count(
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        crossAxisCount: 4,
        children: archivedVocabs.map((vocab){
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
                            archivedVocabs.remove(vocab);
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
                              archivedVocabs.remove(vocab);

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
                  image: Constants.getImageWidget(vocab.book),
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
      );
  }
}