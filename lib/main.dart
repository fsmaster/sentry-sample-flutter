import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const dsn = 'https://1fc736b4ee053e38ec22dd794c97864d@o4512264579579904.ingest.us.sentry.io/4512284738912256';

class Inventory {
  final List<String> shelves = ['A1', 'A2', 'B1'];

  // shelf numbers come from a barcode scanner, nobody checks the range
  String shelf(int index) => shelves[index];
}

Future<SentryId> sendError(String run, {bool fresh = true}) async {
  try {
    Inventory().shelf(7);
  } catch (e, st) {
    return Sentry.captureException(
      e,
      stackTrace: st,
      withScope: (scope) {
        scope.setTag('run_id', run);
        if (fresh) scope.fingerprint = ['{{ default }}', run];
      },
    );
  }
  return const SentryId.empty();
}

Future<void> main(List<String> args) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = 'playground';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      // CI starts the binary with: <app> --run <id> [--keep-issue]
      final i = args.indexOf('--run');
      if (i >= 0 && i + 1 < args.length) {
        final id = await sendError(args[i + 1], fresh: !args.contains('--keep-issue'));
        stdout.writeln('SentrySample event id: $id run: ${args[i + 1]}');
        await Sentry.close();
        exit(0);
      }
      runApp(const SampleApp());
    },
  );
}

class SampleApp extends StatefulWidget {
  const SampleApp({super.key});

  @override
  State<SampleApp> createState() => _SampleAppState();
}

class _SampleAppState extends State<SampleApp> {
  String status = 'ready';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sentry Flutter sample', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final id = await sendError('manual');
                  setState(() => status = 'sent $id');
                },
                child: const Text('Send error'),
              ),
              const SizedBox(height: 12),
              Text(status),
            ],
          ),
        ),
      ),
    );
  }
}
