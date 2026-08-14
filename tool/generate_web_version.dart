import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final version =
      Platform.environment['VERCEL_GIT_COMMIT_SHA'] ??
      Platform.environment['VERCEL_DEPLOYMENT_ID'] ??
      DateTime.now().millisecondsSinceEpoch.toString();

  final file = File('web/version.json');

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'version': version,
    }),
  );

  stdout.writeln('Generated web version: $version');
}
