import 'dart:io';
import 'dart:async';
// Future main(List<String> args) async {
//   var server  = await HttpServer.bind(
//     InternetAddress.loopbackIPv4,
//     4040,
//   );

//   await for (HttpRequest request in server) {
//     request.response
//       ..write('Hello, world!')
//       ..close();
//   }
// }


handleRoute(req, data) {
  if (req['url'] != null) {
    // todo
  }
  data['isGet'] = true;
}

log(req, data) {
  print(data['isGet']);
}


Function piple(List<Function> middlewares){
  return (Map req, Map initData){
    initData = middlewares.fold(initData, (data, fn){
      var ret = fn(req, data);
      if (ret != null) {
        return ret;
      }
      return data;
    });
  };
}


void handleRoute2(req, data) async {
    if (req['url'] != null) {
      // todo
    }
    data['isGet'] = true;
    print('route start');
    await data['next']();
    print('route end');
}


void log2(req, data) async {
    print('log start');
    await Future.delayed(Duration(milliseconds: 2000));
    print("next work");
    await data['next']();
    print('log end');
    print(data['isGet']);
}

Function compose(List<Function> middlewares) {
  return (Map req, Map data) async {
    var i = 0;
    void next(req, data) async {
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


class Pipeline {
  final Pipeline _parent;
  final Function _middleware;

  const Pipeline()
      : _middleware = null,
        _parent = null;

  Pipeline._(this._middleware, this._parent);

  Pipeline addMiddleware(Function middleware) => Pipeline._(middleware, this);

  Function addHandler(Function handler) {
    if (_middleware == null) return handler;
    return _parent.addHandler(_middleware(handler));
  }
}


main(List<String> args) {
  var req = { "url": "/hello" };
  var handle = piple([handleRoute, log]);

  var handleRequest = (Map req){
    var data = {}; 

    // var handle = log2(handleRoute2((req, data) {
    //   print("data, is");
    //   print(data);
    // }));

    // var handle = compose([log2, handleRoute2]);
    // var p = Pipeline()
    // .addMiddleware((Function innerHandler) {
    //   print("1 build");
    //   return (req, data){ 
    //     print("1 start");
    //     innerHandler(req, data);
    //     print("1 end");
    //   };
    // })
    // .addMiddleware((Function innerHandler) {
    //   print("2 build");
    //   return (req, data){ 
    //     print("2 start");
    //     innerHandler(req, data);
    //     print("2 end");
    //   };
    // });
    // var handle = p.addHandler((req, data) => print(req));

    void handle(req, data){
      void innerHandle(req, data) {
        print(req);
      }
      print("2 build");
      void innerHandle2 (req, data){ 
        print("2 start");
        innerHandle(req, data);
        print("2 end");
      };
      print("1 build");
      void innerHandle1 (req, data){ 
        print("1 start");
        innerHandle2(req, data);
        print("1 end");
      };

      innerHandle1(req, data);
    }

    handle(req, data);



    // handle(req, data);
    // print("out data");
    // print(data);
    // handle(req, data);
    // print(data);
  };
  handleRequest(req);
}


