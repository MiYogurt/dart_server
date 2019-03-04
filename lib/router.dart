import 'dart:io';

class RouteMatch {
  Map<String, String> query;
  Map<String, String> params;
  String path;
  RouteMeta meta;
  empty() {
    query = {};
    params = {};
    path = '';
    meta = null;
  }
}

typedef Future<Null> RouterCallback(HttpRequest req, RouteMatch match, Map meta);

class RouteMeta {
  String path;
  List<String> params = [];
  RegExp matcher;
  RouterCallback callback;
  RouteMeta({this.path, this.callback}) {
    pathToRegExp(path);
  }

  pathToRegExp(String path) {
    var regular = path.replaceAllMapped(RegExp(r"\:(\w*)"), (m) {
      // replace (:param)
      this.params.add(m.group(1));
      return "(\\w*)";
    })
      ..replaceAllMapped(RegExp(r"\/$"), (m) {
        // replace end / is option
        return "\/?\$";
      });

    matcher = RegExp("${regular}");
  }

  exec(String uri, RouteMatch match) {
    List<String> lists;
    matcher.allMatches(uri).forEach((m) {
      var iter = List.generate(m.groupCount, (i) => (i + 1));
      lists = m.groups(iter);
    });
    if (lists != null && lists.length == params.length) {
      match.empty();
      match.params = Map.fromIterables(params, lists);
      match.path = uri;
      match.meta = this;
      return match;
    }
    return null;
  }
}

class Router {
  RouteMatch matcher = RouteMatch();
  List<RouteMeta> config = [];

  Router({Map<String, RouterCallback> config}) {
    if (config != null) {
      this.config = config
          .map((k, v) => MapEntry(k, RouteMeta(path: k, callback: v)))
          .values
          .toList();
    }
  }

  add(String path, RouterCallback callback) {
    var meta = RouteMeta(path: path, callback: callback);
    config.add(meta);
    return this;
  }

  off(String path) {
    config.removeWhere((c) => c.path == path);
    return this;
  }

  Future<bool> exec(HttpRequest req, [Map meta]) async {
    for (var item in config) {
      RouteMatch matcher = item.exec(req.requestedUri.path, this.matcher);
      if (matcher != null) {
        await item.callback(req, matcher, meta);
        return true;
      }
    }
    return false;
  }
}
