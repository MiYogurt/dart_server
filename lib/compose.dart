import 'dart:io';

Function compose(List<Function> middlewares) {
  return (HttpRequest req, Map data) async {
    var i = 0;
    void next(HttpRequest req, Map data) async {
      if (i >= middlewares.length) {
        return;
      }
      var fn = middlewares[i];
      i++;
      await fn(req, data);
    }
    data['next'] = () async {
      await next(req, data);
    };
    await next(req, data);
  };
}