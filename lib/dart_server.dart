import 'dart:io';
import 'dart:async';
import 'compose.dart';
import 'router.dart';

Future main(List<String> args) async {
  var server  = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    4040,
  );

  var router = {
    '/job/:id': (RouteMatch match, Map data) async {
      print(match.path);
      print(match.req.uri);
      match.req.response.writeln('good job ${match.params['id']}');
    }
  };

  var handleRequest = compose([log, handleRoute(router)]);
  await for (HttpRequest request in server) {
    Map data = {
      'defaultHandle': true
    };
    await handleRequest(request, data);
  }
}

Function handleRoute(Map _router) {
  var router = Router(config: _router);
  return (HttpRequest req, Map data) async {
    var path = req.requestedUri.path;
    for (var item in router.config) {
      RouteMatch matcher = item.exec(path, router.matcher);
      if (matcher != null) {
        matcher.req = req;
        data['defaultHandle'] = false;
        await item.callback(matcher, data);
      }
    }
    await data['next']();
  };
}

void log(HttpRequest req, data) async {
    await data['next']();
    print(data['defaultHandle']);
    if (data['defaultHandle']) {
      req.response.write('404 not found');
    }
    print('[${req.method}] ${req.requestedUri} ${req.response.statusCode}');
    await req.response.close();
}






