import 'dart:io';
import 'dart:async';
import 'compose.dart';
import 'router.dart';
import 'context.dart';
import 'render.dart';
import 'i10n/messages_all.dart';
import 'package:intl/intl.dart';
import 'locale.dart';

String Page(String child) {
  return html([
    title('hello my server'),
    body(
      hello(child)
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
      req.response.writeln(Page('${match.params['id']}'));
    }
  };
  await initializeMessages('zh');
  await initializeMessages('en');
  Intl.defaultLocale = 'en';

  var handleRequest = compose([log, handleLocale, handleRoute(router)]);
  await for (HttpRequest request in server) {
    var ctx = Context();
    await handleRequest(request, ctx);
  }
}

handleLocale(HttpRequest req, Context ctx) async {
  Future wrapNext(String locale) async => Intl.withLocale(locale, () async {
    return await ctx.next();
  });
  var lang = req.headers.value('accept-language');
  if (lang.contains(RegExp('zh'))) {
    return await wrapNext('zh');
  }
  return await wrapNext('en');
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






