import 'package:intl/intl.dart';
import 'i10n/messages_all.dart';

String  hello(yourName) => Intl.message(
    "Hello, $yourName",
    name: "hello",
    args: [yourName],
    desc: "Say hello",
    examples: const {"yourName": "Sparky"}
);

String good(int some) => Intl.plural(
  some, 
  zero: 'is zeore $some',
  one: "is one $some",
  two: 'is two $some',
  other: 'is other $some',
  name: 'good',
  desc: 'is good some func',
  args: [some],
  examples: const { "some": 1 }
);

main(List<String> args) async {
  Intl.defaultLocale = 'zh';
  await initializeMessages('zh');
  await initializeMessages('en');
  print(hello('job'));
  Intl.defaultLocale = 'en';
  print(hello('job'));

  Intl.withLocale('zh', (){
    print(hello('inner'));
  });

}