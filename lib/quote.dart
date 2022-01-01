class Lie{
  late String text;
  late String author;
  late String episode;
  Lie(String t, String a, String e){
    text = t;author = a;episode = e;
  }
}

class Vocab{
  static final List<String> WordColumns = [
    idfield, bookidfield,namefield,deffield, knownfield
  ];
  static final List<String> BookColumns = [
    idfield, namefield, archivedfield, colorfield,coverfield
  ];
  static final bookstableName = "BOOKS";
  static  final namefield = 'NAME';
  static final archivedfield = 'ARCHIVED';
  static final colorfield = 'COLOR';
  static final coverfield = 'COVER';
  static final idfield = '_ID';
  static final  wordstableName = "WORDS";
  static final deffield = "DEF";
  static final knownfield = "KNOWN";
  static final bookidfield = "BOOKID";
  late Book book;
  late List<Word> words;
  Vocab(List<Word> _words, Book _book){
    words = _words; book = _book;
  }
}

class Word{
  late int id;
  late String word;
  late String def;
  late bool known;
  late int bookId;
  Word(int i, int bi,String w, String d, bool k){
    id = i;word = w; known = k;bookId = bi;def = d;
  }
  Map<String, Object> toJson()=>{
    Vocab.idfield: id,
    Vocab.bookidfield: bookId,
    Vocab.namefield:word,
    Vocab.deffield:def,
    Vocab.knownfield: known?1:0
  };
  static Word fromJson(json)=> Word(
    json[Vocab.idfield] as int,
    json[Vocab.bookidfield] as int,
    json[Vocab.namefield] as String,
    json[Vocab.deffield] as String,
    (json[Vocab.knownfield] as int)==1,
  );
}
class Book{
  late int id;
  late String name;
  late bool archived;
  late int color;
  late String cover;
  Book(int i, String n, bool a, int c, String cov){
    id = i; name = n;archived = a;color = c;cover = cov;
  }
  Map<String, Object?> toJson()=>{
    Vocab.idfield: id,
    Vocab.namefield: name,
    Vocab.archivedfield: archived?1:0,
    Vocab.colorfield:color,
    Vocab.coverfield:cover
  };
  static Book fromJson(json)=>Book(
    json[Vocab.idfield.toUpperCase()] as int,
    json[Vocab.namefield.toUpperCase()] as String,
    (json[Vocab.archivedfield] as int)==1,
    json[Vocab.colorfield] as int,
    json[Vocab.coverfield] as String
  );
}
