// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_glean/otel_glean.dart';

/// Traces Glean calls with OpenTelemetry.
///
/// `otel_glean` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Glean call in
/// [tracedGlean]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'glean-example');

  // Wraps a Glean API call in a CLIENT span.
  final gleanId = await tracedGlean<String>(
    operation: 'chat.stream',
    invoke: () async {
      // Make the Glean call here, then report what it returned.
      const id = 'glean_8f3a2c';
      return const GleanCallResult(
          value: id,
          result: GleanResult(
              tenant: 'acme-corp',
              actAsUser: 'example',
              applicationId: 'application_8f3a2c',
              conversationId: 'conversation_8f3a2c',
              messageId: 'message_8f3a2c',
              requestType: 'SEARCH',
              datasourcesSearched: 'example',
              totalResults: 1,
              citationsReturned: 1,
              modelName: 'standard',
              inputTokens: 128,
              outputTokens: 128,
              totalTokens: 128,
              durationMs: 120,
              statusCode: 200));
    },
  );
  OTelLog.info('tracedGlean chat.stream returned $gleanId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGleanInstrumentationAsync.
  await runWithoutGleanInstrumentationAsync(
    () => tracedGlean<String>(
      operation: 'chat.stream',
      invoke: () async {
        const id = 'glean_8f3a2c';
        return const GleanCallResult(
            value: id,
            result: GleanResult(
                tenant: 'acme-corp',
                actAsUser: 'example',
                applicationId: 'application_8f3a2c',
                conversationId: 'conversation_8f3a2c',
                messageId: 'message_8f3a2c',
                requestType: 'SEARCH',
                datasourcesSearched: 'example',
                totalResults: 1,
                citationsReturned: 1,
                modelName: 'standard',
                inputTokens: 128,
                outputTokens: 128,
                totalTokens: 128,
                durationMs: 120,
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}
