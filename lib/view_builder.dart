import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';

var tagNames = [
  'html', 
  'head',
  'div',
  'p',
  'img'
  'script',
  'body',
  'title',
  'meta',
  'link',
  'h1'
];

class RenderTagHLibraryGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    return 'part of render;\n\n' + tagNames.map((v) => buildFn(v)).join();
  }

  buildFn(String tagName){
    return '''
      String $tagName([dynamic attrs = const {}, List<String> children = const []]){
        return h('$tagName', attrs, children);
      }

    ''';
  }
}

Builder renderTagFn(BuilderOptions options) =>
    LibraryBuilder(RenderTagHLibraryGenerator(),
        generatedExtension: '.g.dart');