import 'package:postgres/postgres.dart';
import 'dart:mirrors';

PostgreSQLConnection connection = new PostgreSQLConnection("localhost", 5432, "dart", username: "postgres", password: "postgres");

Future<PostgreSQLConnection> init() async {
  await connection.open();
  return connection;
}

abstract class Model {
  exec(sql, {Map attrs}){
    return connection.query(sql, substitutionValues: attrs);
  }
  static createTable<T>() async {
    var attrsMap = getAttrsMap<T>();
    String fieldsString = attrsMap.keys.fold('', (acc, key) {
      acc+="  $key ${attrsMap[key]},\n";
      return acc;
    });
    fieldsString = fieldsString.substring(0, fieldsString.length - 2);
    var sql = """
      create table app_${getSymbolName(reflectClass(T).simpleName)} (
        $fieldsString
      )
    """;
    print(sql);
    return await connection.execute(sql);
  }
  static Map<String, String> getAttrsMap<T>([ClassMirror cls]) {
    if (cls == null) {
      cls = reflectClass(T);
    }
    Map<String, String> attrsMap = {};
    cls.declarations.forEach((symbol, decl){
      if (symbol == cls.simpleName) {
        return;
      }
      if (decl.metadata.isEmpty) {
        return;
      }
      attrsMap[getSymbolName(symbol)] = decl.metadata.single.getField(#type).reflectee;
    });
    return attrsMap;
  }

  save() async {
    var data = reflect(this);
    ClassMirror cls = data.type;
    var attrsMap = getAttrsMap(cls);
    var keys = attrsMap.keys.skipWhile((k){
      if (data.getField(#id)?.reflectee == null) {
        return k == 'id';
      }
      return false;
    });
    print(keys);
    var fields = keys.join(',');
    var values = getValues(keys.toList(), data);
    var sql = """
      insert into app_${getSymbolName(cls.simpleName)} ($fields)
        values ($values) returning "id", ${keys.map((k) => "\"$k\"").join(',')}
    """;
    print(sql);
    var results = await connection.query(sql);
    syncDataToModel(attrsMap.keys.toList(), results.first, reflect(this));
  }

  update() async {
    var data = reflect(this);
    ClassMirror cls = data.type;
    var attrsMap = getAttrsMap(cls);
    var keys = attrsMap.keys.skipWhile((k) => k == 'id');
    var values = getValues(keys.toList(), data);
    var sql = """
      update app_${getSymbolName(cls.simpleName)} set $values where id=${data.getField(#id).reflectee}
    """;
    print(sql);
    return await connection.query(sql);
  }

  delete() async {
    var data = reflect(this);
    ClassMirror cls = data.type;
    var sql = "delete from app_${getSymbolName(cls.simpleName)} where id = @id";
    return connection.execute(sql, substitutionValues: {"id": data.getField(#id).reflectee});
  }


  static Future<T> findById<T>(id) async {
    var cls = reflectClass(T);
    var attrsMap = getAttrsMap(cls);
    var keys = attrsMap.keys.toList();
    var fieldsString = keys.join(',');
    var sql = "select $fieldsString from app_${getSymbolName(cls.simpleName)} where id=$id";
    print(sql);
    var list = await connection.query(sql);
    if (list.isEmpty) {
      return null;
    }
    var data = list.first;
    if (data.isNotEmpty) {
      var model = cls.newInstance(Symbol(''), []);
      syncDataToModel(keys, data, model);
      if (model.type.declarations.keys.contains(#prepare)) {
        await model.invoke(#prepare, [model.reflectee]).reflectee;
      }
      return model.reflectee as T;
    }
    return null;
  }
}

class Type{
  final String type;
  const Type(this.type);
}

class Book extends Model {
  @Type('serial primary key')
  int id;

  @Type('varchar(255)')
  String name;

  @Type('int')
  int author_id;

  User author;

  Future<Book> prepare(Book book) async {
    book.author = await Model.findById<User>(book.author_id);
    return book;
  }
}

class User extends Model {
  @Type('serial primary key')
  int id;

  @Type('varchar(255)')
  String username;
}

String getSymbolName(Symbol symbol){
  return RegExp(r'Symbol\(\"(.*)\"\)$').firstMatch(symbol.toString()).group(1);
}

syncDataToModel(List keys, List datas, InstanceMirror model) {
  for (var i = 0; i < datas.length; i++) {
      model.setField(Symbol(keys[i]), datas[i]);
    }
}

String getValues(List keys, InstanceMirror data){
  return keys.map((k){
      var v = data.getField(Symbol(k)).reflectee;
      if (v == null) {
        return 'null';
      }
      return "\'$v\'";
    }).join(',');
}


main(List<String> args) async {
  await init();
  // await Model.createTable<Book>();
  // await Model.createTable<User>();
  // var book = await Model.findById<Book>(1);
  // print(book.id);
  // print(book.author_id);
  // print(book.author);
  var author = User();
  author.username = 'hello';
  await author.save();
  print(author.id);
  var b = Book();
  b.name = "20";
  b.author_id = author.id;
  await b.save();
  var b2 = await Model.findById<Book>(b.id);
  print(b2.author.id);
  // var u = User();
  // u.username = 'hello';
  // var ret = u.save();
  // var user = User();
  // user.username = 'h1';
  // await user.save();
  // print(user.username);
  // user.username = "h2";
  // await user.update();
  // print(user.username);

  // print(user);
  // print(user.username);
  // await user.delete();
}

