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
    '/job/:id': (HttpRequest req, RouteMatch match, Map data) async {
      req.response.writeln('good job ${match.params['id']}');
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
    if(await router.exec(req, data)){
      data['defaultHandle'] = false;
    }
    await data['next']();
  };
}

void log(HttpRequest req, data) async {
    await data['next']();
    if (data['defaultHandle']) {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('404 not found');
    }
    print('[${req.method}] ${req.requestedUri} ${req.response.statusCode}');
    await req.response.close();
}






