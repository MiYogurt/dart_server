
library render;

part 'render.g.dart';

String h(String tagName,
    [dynamic attrs = const {}, List<String> children = const []]) {
  if (attrs is String) {
    children = [attrs];
    attrs = {};
  }
  if (attrs is List<String>) {
    children = attrs;
    attrs = {};
  }
  var attrsString = attrs.entries.fold('', (acc, kv) {
    acc += " ${kv.key}=\"${kv.value}\"";
    return acc;
  });
  return """<$tagName$attrsString>${children.join()}</$tagName>""";
}
