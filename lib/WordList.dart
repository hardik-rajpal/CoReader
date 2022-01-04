import 'dart:convert';

import 'package:CoReader/Vocabs.dart';
import 'package:CoReader/main.dart';
import 'package:CoReader/quote.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
class MessageBar extends StatefulWidget {
  final Color color;
  final Function onSubmit;
  MessageBar({required this.color, required this.onSubmit}){

  }

  @override
  State<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> {
  final _wordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: this.widget.color,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: TextField(
                controller: _wordController,
                onSubmitted: (wordstr){widget.onSubmit(wordstr);_wordController.clear();},
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.all(10),
                    hintText: 'Enter Word...',
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color:Colors.red, width: 5.0),
                        borderRadius: BorderRadius.all(Radius.circular(20.0))
                    ),
                    filled: true,
                    fillColor: Colors.grey[200]
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                  color:Colors.black,
                  icon: Icon(Icons.send, color: (Constants.getVofHSV(this.widget.color)>Constants.ValueThres)?Colors.black:Colors.white,),
                  onPressed: () {
                    widget.onSubmit(_wordController.text);
                    _wordController.clear();
                  }
              ),
            )
          ],
        ),
      ),
    );
  }
}
class WordCard extends StatelessWidget {
  const WordCard({
    Key? key,
    required this.archived,
    required this.word,
    required this.refresher,
    required this.color
  }) : super(key: key);
  final Color color;
  final Word word;
  final bool archived;
  final Function refresher;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
      child: ElevatedButton.icon(
        icon:Icon(word.known?Icons.check:Icons.info, color: (Constants.getVofHSV(color)>Constants.ValueThres)?Colors.black:Colors.white,),
        style: ButtonStyle(
          alignment: Alignment.centerLeft,
          foregroundColor: MaterialStateProperty.all((Constants.getVofHSV(color)>Constants.ValueThres)?Colors.black:Colors.white),
          backgroundColor: MaterialStateProperty.all(color),
        ),
        onPressed: ()async{
          if(word.def==""){
            var client = Client();
            var response = await client.get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/'+word.word));
            print(response.body);
            DefinitionBox(response.body, context, word, this.refresher, this.archived);
          }
          else{
            DefinitionBox("", context, word, this.refresher, this.archived);
          }
        },
        label: Text(
          word.word,
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ),
    );
  }
}
class WordList extends StatefulWidget{
  final List<Word> words;
  final Color color;
  final Book book;
  final Function refresher;
  WordList({required this.words, required this.color, required this.refresher, required this.book});
  @override
  State<WordList> createState() => _WordListState();
}
class _WordListState extends State<WordList> {
  List<Word> words = [];
  bool disposed = false;
  void refreshWords()async{
    if(disposed||(!mounted)){return;}
    List<Word> allwords = await VocabDatabase.instance.getAllWords(widget.book.id);
    setState(() {
      words = allwords;
    });
  }
  @override
  void initState() {
    super.initState();
    setState(() {
      words = widget.words;
    });
  }
  @override
  void dispose() {
    super.dispose();
    disposed = true;
  }

  @override
  Widget build(BuildContext context) {
    refreshWords();
    return Container(
      child: Column(
        children: [
          Expanded(
            child:(words.length>0)?ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index){
                var word = words[index];
                return WordCard(word: word,color: widget.color, archived:widget.book.archived,refresher:() {

                  refreshWords();
                });
              },

            ):Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No words added to glossary.\n Add words using the message bar below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          (!widget.book.archived)?MessageBar(
              color:Color(widget.book.color),
              onSubmit: (wordstr)async{
                var word = new Word(-1,widget.book.id, wordstr, "", false);
                word = await VocabDatabase.instance.createWord(word);
                setState(() {
                  words.add(word);
                });
              }
          ):Container()
        ],
      ),
    );
  }
}
class DefinitionBox{
  DefinitionBox(String output, BuildContext context, Word wordobj, dynamic refresher, bool archived){
    // String word;
    String definition = wordobj.def;
    // bool updated = false;
    // word = "";
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
        // word = wordobj.word;
        definition = "We couldn't get that word. Sorry.";
      }
    }

    // print(definition);

    var alertDialog = AlertDialog(
      title: Text("Definitions"),
      content: SingleChildScrollView(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              definition,
            ),
          ),
        ),
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
        archived?Container():ElevatedButton.icon(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(wordobj.known?Colors.yellow[800]:Colors.green),
          ),
          onPressed: ()async{
            wordobj.known = !wordobj.known;
            await VocabDatabase.instance.updateWord(wordobj);
            Navigator.of(context).pop();
            refresher();
          },
          icon: Icon(wordobj.known?Icons.indeterminate_check_box:Icons.check_box),
          label: wordobj.known?Text("Forgotten"):Text("Known"),
        ),
        archived?Container():DeleteButton(onDelete: ()async{
          await VocabDatabase.instance.deleteWord(wordobj.id);
          refresher();
          Navigator.of(context).pop();
        })
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