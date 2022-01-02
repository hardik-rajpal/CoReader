import 'package:CoReader/quote.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class VocabDatabase{
  static final VocabDatabase instance = VocabDatabase._init();
  static Database? _database;
  VocabDatabase._init();
  Future<Database> get database async{
    if(_database!=null) return _database!;
    _database = await _initDB('vocab.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version:1, onCreate:  _createDB);
  }

  Future _createDB(Database db, int version) async{
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    await db.execute('''
CREATE TABLE ${Vocab.bookstableName} (
  ${Vocab.idfield} $idType,
  ${Vocab.namefield} TEXT,
  ${Vocab.archivedfield} INTEGER,
  ${Vocab.colorfield} INTEGER,
  ${Vocab.coverfield} TEXT,
  ${Vocab.bookmarkfield} INTEGER
)
''');
    await db.execute('''
CREATE TABLE ${Vocab.wordstableName} (
  ${Vocab.idfield} $idType,
  ${Vocab.bookidfield} INTEGER,
  ${Vocab.namefield} TEXT,
  ${Vocab.deffield} TEXT,
  ${Vocab.knownfield} BOOLEAN
)
''');
    await db.execute('''
CREATE TABLE ${Vocab.pagesTableName} (
  ${Vocab.idfield} $idType,
  ${Vocab.namefield} TEXT,
  ${Vocab.bookidfield} INTEGER,
  ${Vocab.contentfield} TEXT
)
''');
  }
  Future<Book> create(Book book) async{
    final db = await instance.database;
    Map<String,Object?> json = book.toJson();
    json.remove(Vocab.idfield);
    final id = await db.insert(Vocab.bookstableName,json);
    book.id = id;
    return book;
  }
  Future<Word> createWord(Word word) async{
    final db = await instance.database;
    Map<String,Object?> json = word.toJson();
    json.remove(Vocab.idfield);
    final id = await db.insert(Vocab.wordstableName,json);
    word.id = id;
    return word;
  }
  Future<NotePage> createPage(NotePage page) async{
    final db = await instance.database;
    Map<String,Object?> json = page.toJson();
    json.remove(Vocab.idfield);
    final id = await db.insert(Vocab.wordstableName,json);
    page.id = id;
    return page;
  }

  Future<List<Book>> getAllBooks() async{
    final db = await instance.database;
    final maps= await db.query(
      Vocab.bookstableName,
      columns:Vocab.BookColumns,
    );
    List<Book>  books = maps.map((s){
      print(s);
      Book book = Book.fromJson(s);
      return book;
    }).toList();
    return books;
  }
  Future<List<Word>> getAllWords() async{
    final db = await instance.database;
    final maps= await db.query(
      Vocab.wordstableName,
      columns:Vocab.WordColumns,
    );
    List<Word>  words = maps.map((s){
      Word word = Word.fromJson(s);
      return word;
    }).toList();
    return words;
  }
  Future<List<NotePage>> getAllPages() async{
    final db = await instance.database;
    final maps= await db.query(
      Vocab.pagesTableName,
      columns:Vocab.PageColumns,
    );
    List<NotePage>  pages = maps.map((s){
      NotePage page = NotePage.fromJson(s);
      return page;
    }).toList();
    return pages;
  }
  Future<bool> deleteWord(int id) async{
    final db = await instance.database;
    final int b = await db.delete(
      Vocab.wordstableName,
      where:'${Vocab.idfield} = ?',
      whereArgs: [id],
    );
    print(b);
    return b>0;
  }
  Future<bool> deletePage(int id) async{
    final db = await instance.database;
    final int b = await db.delete(
      Vocab.pagesTableName,
      where:'${Vocab.idfield} = ?',
      whereArgs: [id],
    );
    print(b);
    return b>0;
  }
  Future<bool> deleteBook(int id) async{
    final db = await instance.database;
    final int b = await db.delete(
      Vocab.wordstableName,
      where:'${Vocab.bookidfield} = ?',
      whereArgs: [id],
    );
    final int b2 = await db.delete(
      Vocab.bookstableName,
      where:'${Vocab.idfield} = ?',
      whereArgs: [id],
    );
    print(b);
    return b>0;
  }
  Future<int> updateWord(Word word)async{
    final db = await instance.database;
    return db.update(
      Vocab.wordstableName,
      word.toJson(),
      where: '${Vocab.idfield} = ?',
      whereArgs: [word.id]
    );
  }
  Future<int> updatePage(NotePage page)async{
    final db = await instance.database;
    return db.update(
        Vocab.pagesTableName,
        page.toJson(),
        where: '${Vocab.idfield} = ?',
        whereArgs: [page.id]
    );
  }
  Future<int> updateBook(Book book)async{
    final db = await instance.database;
    return db.update(
        Vocab.bookstableName,
        book.toJson(),
        where: '${Vocab.idfield} = ?',
        whereArgs: [book.id]
    );
  }
  Future close() async{
    final db = await instance.database;
    db.close();
  }
}