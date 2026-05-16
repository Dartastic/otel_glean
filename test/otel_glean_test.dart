// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_glean/otel_glean.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_glean-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('chat records tenant + datasources + tokens + citations', () async {
    await tracedGlean<String>(
      operation: 'chat',
      invoke: () async => const GleanCallResult(
        value: 'ok',
        result: GleanResult(
          tenant: 'acme-corp',
          actAsUser: 'jdoe@acme.com',
          conversationId: 'conv_1',
          messageId: 'msg_1',
          requestType: 'CHAT',
          datasourcesSearched: 'gdrive,slack,confluence,jira',
          citationsReturned: 6,
          modelName: 'glean-default',
          inputTokens: 1500,
          outputTokens: 320,
          totalTokens: 1820,
          durationMs: 2400,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('glean chat')!);
    expect(a['glean.tenant'], 'acme-corp');
    expect(a['glean.act_as.user'], 'jdoe@acme.com');
    expect(a['glean.request.type'], 'CHAT');
    expect(a['glean.datasources.searched'], 'gdrive,slack,confluence,jira');
    expect(a['glean.citations.returned'], 6);
    expect(a['glean.tokens.total'], 1820);
  });

  test('HTTP 401 sets span error', () async {
    await tracedGlean<String>(
      operation: 'search',
      invoke: () async => const GleanCallResult(
        value: 'ok',
        result: GleanResult(statusCode: 401),
      ),
    );
    expect(
      spans.findSpanByName('glean search')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutGleanInstrumentationAsync(() async {
      await tracedGlean<String>(
        operation: 'autocomplete',
        invoke: () async => const GleanCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('glean '), isEmpty);
  });
}
