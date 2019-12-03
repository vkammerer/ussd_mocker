import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

// For Google Cloud Run, set _hostname to '0.0.0.0'.
final _hostname = InternetAddress.anyIPv4;

main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

Future<shelf.Response> _echoRequest(shelf.Request request) async {
  String fileName = 'status.txt';
  if (request.url.path == 'activation') {
    String number = request.url.queryParameters['number'];
    if (number != null) {
      String phoneNumber = number.replaceAll('**21*', '').replaceAll('#', '');
      await File(p.join(p.current, 'bin', fileName)).writeAsString(phoneNumber);
    }
  } else if (request.url.path == 'cancellation') {
    await File(p.join(p.current, 'bin', fileName)).writeAsString('cancelled');
  }
  await Future.delayed(Duration(seconds: 3));
  File config = File(p.join(p.current, 'bin', fileName));
  String contents = await config.readAsString();
  print(contents);

  return shelf.Response.ok(contents);
}
