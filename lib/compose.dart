import 'dart:io';
import 'context.dart';

Function compose(List<Function> middlewares) {
  return (HttpRequest req, Context ctx) async {
    var i = 0;
    void next(HttpRequest req, Context data) async {
      if (i >= middlewares.length) {
        return;
      }
      var fn = middlewares[i];
      i++;
      await fn(req, data);
    }
    ctx.next = () async {
      await next(req, ctx);
    };
    await next(req, ctx);
  };
}