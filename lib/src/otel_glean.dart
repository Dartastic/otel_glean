// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_glean_suppression.dart';

const _tracerName = 'dartastic_otel_libs_glean';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class GleanResult {
  /// Creates a result.
  const GleanResult({
    this.tenant,
    this.actAsUser,
    this.applicationId,
    this.conversationId,
    this.messageId,
    this.requestType,
    this.datasourcesSearched,
    this.totalResults,
    this.citationsReturned,
    this.modelName,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.durationMs,
    this.statusCode,
  });

  /// Glean tenant subdomain (e.g., `acme-corp` for
  /// `acme-corp.glean.com`).
  final String? tenant;

  /// `Act-As-User` header — the end user the SDK is asking on behalf
  /// of (impersonation for backend services).
  final String? actAsUser;

  /// Glean app/scope id for ChatBot apps.
  final String? applicationId;

  final String? conversationId;
  final String? messageId;

  /// `SEARCH` / `CHAT` / `RECOMMEND` / `AUTOCOMPLETE` / `ANSWER` /
  /// `RELATED`.
  final String? requestType;

  /// Comma-separated datasource names that contributed results
  /// (`gdrive,slack,jira,confluence,salesforce,gh,gmail,box,notion,
  /// servicenow,figma,asana,workday,greenhouse`).
  final String? datasourcesSearched;

  final int? totalResults;

  /// For CHAT/ANSWER: number of citations attached to the model
  /// response. Critical signal for hallucination/grounding.
  final int? citationsReturned;

  /// Model used (Glean rotates between vendor models).
  final String? modelName;

  /// Token counts surfaced via the v1 chat usage API.
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;

  final int? durationMs;
  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class GleanCallResult<T> {
  /// Creates a call result.
  const GleanCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final GleanResult? result;
}

/// Wraps a Glean API call in a CLIENT span. [operation] is one of
/// `search`, `chat`, `chat.stream`, `recommend`, `autocomplete`,
/// `answer`, `feedback`, `pin`, `entities.search`.
Future<T> tracedGlean<T>({
  required String operation,
  required Future<GleanCallResult<T>> Function() invoke,
}) async {
  if (gleanInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'glean',
    'rpc.method': operation,
    'glean.operation': operation,
  };

  final span = _tracer().startSpan(
    'glean $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.tenant != null) {
        extras.add(OTelAPI.attributeString('glean.tenant', r.result!.tenant!));
      }
      if (r.result!.actAsUser != null) {
        extras.add(OTelAPI.attributeString(
          'glean.act_as.user',
          r.result!.actAsUser!,
        ));
      }
      if (r.result!.applicationId != null) {
        extras.add(OTelAPI.attributeString(
          'glean.application.id',
          r.result!.applicationId!,
        ));
      }
      if (r.result!.conversationId != null) {
        extras.add(OTelAPI.attributeString(
          'glean.conversation.id',
          r.result!.conversationId!,
        ));
      }
      if (r.result!.messageId != null) {
        extras.add(OTelAPI.attributeString(
          'glean.message.id',
          r.result!.messageId!,
        ));
      }
      if (r.result!.requestType != null) {
        extras.add(OTelAPI.attributeString(
          'glean.request.type',
          r.result!.requestType!,
        ));
      }
      if (r.result!.datasourcesSearched != null) {
        extras.add(OTelAPI.attributeString(
          'glean.datasources.searched',
          r.result!.datasourcesSearched!,
        ));
      }
      if (r.result!.totalResults != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.total.results',
          r.result!.totalResults!,
        ));
      }
      if (r.result!.citationsReturned != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.citations.returned',
          r.result!.citationsReturned!,
        ));
      }
      if (r.result!.modelName != null) {
        extras.add(OTelAPI.attributeString(
          'glean.model.name',
          r.result!.modelName!,
        ));
      }
      if (r.result!.inputTokens != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.tokens.input',
          r.result!.inputTokens!,
        ));
      }
      if (r.result!.outputTokens != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.tokens.output',
          r.result!.outputTokens!,
        ));
      }
      if (r.result!.totalTokens != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.tokens.total',
          r.result!.totalTokens!,
        ));
      }
      if (r.result!.durationMs != null) {
        extras.add(OTelAPI.attributeInt(
          'glean.duration_ms',
          r.result!.durationMs!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Glean HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
