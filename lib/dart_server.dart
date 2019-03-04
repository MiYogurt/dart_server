import 'dart:io';
import 'dart:async';
import 'compose.dart';
import 'router.dart';
import 'context.dart';
import 'render.dart';

String Page(String child) {
  return html([
    title('hello my server'),
    body(
      child
    )
  ]);
}

Future main(List<String> args) async {
  var server  = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    4040,
  );

  var router = {
    '/job/:id': (HttpRequest req, RouteMatch match, Context ctx) async {
      req.response.headers.contentType =ContentType.html;
      req.response.writeln(Page('hello ${match.params['id']}'));
    }
  };

  var handleRequest = compose([log, handleRoute(router)]);
  await for (HttpRequest request in server) {
    var ctx = Context();
    await handleRequest(request, ctx);
  }
}

Function handleRoute(Map _router) {
  var router = Router(config: _router);
  return (HttpRequest req, Context ctx) async {
    if(await router.exec(req, ctx)){
      ctx.defaultHandle = false;
    }
    await ctx.next();
  };
}

void log(HttpRequest req, Context ctx) async {
    await ctx.next();
    if (ctx.defaultHandle) {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('404 not found');
    }
    print('[${req.method}] ${req.requestedUri} ${req.response.statusCode}');
    await req.response.close();
}






