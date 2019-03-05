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
  static Map<String, String> getAttrsMap<T>() {
    var cls = reflectClass(T);
    Map<String, String> attrsMap = {};
    cls.declarations.forEach((symbol, decl){
      if (symbol == cls.simpleName) {
        return;
      }
      attrsMap[getSymbolName(symbol)] = decl.metadata.single.getField(#type).reflectee;
    });
    return attrsMap;
  }
}

class Type{
  final String type;
  const Type(this.type);
}

class User extends Model {
  @Type('varchar(255)')
  String username;
}

String getSymbolName(Symbol symbol){
  return RegExp(r'Symbol\(\"(.*)\"\)$').firstMatch(symbol.toString()).group(1);
}


main(List<String> args) async {
  await init();
  var sql = await Model.createTable<User>();
  print(sql);
}

