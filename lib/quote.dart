class Vocab{
  static final List<String> WordColumns = [
    idfield, bookidfield,namefield,deffield, knownfield
  ];
  static final List<String> BookColumns = [
    idfield, namefield, archivedfield, colorfield,coverfield,bookmarkfield,sizefield
  ];
  static final List<String> PageColumns = [
    idfield, namefield, contentfield, bookidfield
  ];
  static final bookstableName = "BOOKS";
  static  final namefield = 'NAME';
  static final archivedfield = 'ARCHIVED';
  static final colorfield = 'COLOR';
  static final coverfield = 'COVER';
  static final bookmarkfield = 'BOOKMARK';
  static final sizefield = 'SIZE';
  static final idfield = '_ID';

  static final  wordstableName = "WORDS";
  static final deffield = "DEF";
  static final knownfield = "KNOWN";
  static final bookidfield = "BOOKID";

  static final pagesTableName = "PAGES";
  //bookid
  static final contentfield = "CONTENT";

  late Book book;
  late List<Word> words;
  // late List<NotePage> pages;
  Vocab(List<Word> _words, Book _book){
    words = _words; book = _book;
    // pages = _pages;
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
class NotePage{
  late int id;
  late String title;
  late String content;
  late int bookId;
  NotePage(int i, int bi,String c, String t){
    id = i;bookId = bi;content = c;title = t;
  }
  Map<String, Object> toJson()=>{
    Vocab.idfield: id,
    Vocab.bookidfield: bookId,
    Vocab.contentfield: content,
    Vocab.namefield:title
  };
  static NotePage fromJson(json)=> NotePage(
    json[Vocab.idfield] as int,
    json[Vocab.bookidfield] as int,
    json[Vocab.contentfield] as String,
    json[Vocab.namefield] as String
  );
}
class Book{
  late int id;
  late String name;
  late bool archived;
  late int color;
  late String cover;
  late int bookmark;
  late int size;
  Book(int i, String n, bool a, int c, String cov, int bm, int sz){
    id = i; name = n;archived = a;color = c;cover = cov; bookmark = bm;size = sz;
  }
  Map<String, Object?> toJson()=>{
    Vocab.idfield: id,
    Vocab.namefield: name,
    Vocab.archivedfield: archived?1:0,
    Vocab.colorfield:color,
    Vocab.coverfield:cover,
    Vocab.bookmarkfield:bookmark,
    Vocab.sizefield:size
  };
  static Book fromJson(json)=>Book(
    json[Vocab.idfield.toUpperCase()] as int,
    json[Vocab.namefield.toUpperCase()] as String,
    (json[Vocab.archivedfield] as int)==1,
    json[Vocab.colorfield] as int,
    json[Vocab.coverfield] as String,
    json[Vocab.bookmarkfield] as int,
    json[Vocab.sizefield] as int
  );
}
