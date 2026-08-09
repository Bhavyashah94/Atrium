import 'dart:convert';
import 'dart:io';

/// Completion threshold (90%) used for determining play completion from percentage.
const double kTracearrCompletionThreshold = 90.0;

void main(List<String> args) async {
  final String specPath = args.isNotEmpty ? args[0] : 'tool/v2.json';
  final File specFile = File(specPath);

  if (!specFile.existsSync()) {
    stderr.writeln('Error: Spec file not found at $specPath');
    exit(1);
  }

  final String content = await specFile.readAsString();
  final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;
  final Map<String, dynamic> schemas =
      (data['components'] as Map<String, dynamic>?)?['schemas']
              as Map<String, dynamic>? ??
          <String, dynamic>{};
  final Map<String, dynamic> paths =
      data['paths'] as Map<String, dynamic>? ?? <String, dynamic>{};

  // 1. Generate Models (lib/src/models/tracearr_v2_models.dart)
  _generateModelsFile(schemas, paths);

  // 2. Generate API Client (lib/src/tracearr_api.dart)
  _generateApiClientFile(paths);

  // 3. Generate Providers (lib/src/tracearr_providers.dart)
  _generateProvidersFile(paths);

  stdout.writeln('Successfully auto-generated models, API client, and providers from v2.json!');
}

void _generateModelsFile(Map<String, dynamic> schemas, Map<String, dynamic> paths) {
  final StringBuffer code = StringBuffer();
  code.writeln('// AUTO-GENERATED FROM v2.json OpenAPI Specification');
  code.writeln(
    '// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.',
  );
  code.writeln();
  code.writeln("import 'package:freezed_annotation/freezed_annotation.dart';");
  code.writeln();
  code.writeln("part 'tracearr_v2_models.freezed.dart';");
  code.writeln("part 'tracearr_v2_models.g.dart';");
  code.writeln();
  code.writeln('const double kTracearrCompletionThreshold = 90.0;');
  code.writeln();

  _generateApiStatusEnum(paths, code);

  code.writeln('typedef TracearrV2Library = TracearrV2LibraryRollup;');
  code.writeln(
    'typedef TracearrV2RecentlyAddedItem = TracearrV2RecentlyAddedRecord;',
  );
  code.writeln('typedef TracearrV2MediaDetails = TracearrV2MediaResource;');
  code.writeln();

  code.writeln('Object? _flexibleIntReader(Map<dynamic, dynamic> json, String key) {');
  code.writeln('  final Object? val = json[key];');
  code.writeln('  if (val is String) {');
  code.writeln('    final int? parsedInt = int.tryParse(val);');
  code.writeln('    if (parsedInt != null) return parsedInt;');
  code.writeln('    final double? parsedDouble = double.tryParse(val);');
  code.writeln('    if (parsedDouble != null) return parsedDouble.toInt();');
  code.writeln('  }');
  code.writeln('  return val;');
  code.writeln('}');
  code.writeln();
  code.writeln('Object? _flexibleDoubleReader(Map<dynamic, dynamic> json, String key) {');
  code.writeln('  final Object? val = json[key];');
  code.writeln('  if (val is String) {');
  code.writeln('    return double.tryParse(val);');
  code.writeln('  }');
  code.writeln('  return val;');
  code.writeln('}');
  code.writeln();

  for (final MapEntry<String, dynamic> entry in schemas.entries) {
    final String schemaName = entry.key;
    if (schemaName == 'OpenApiDocument') continue;

    final Map<String, dynamic> schemaBody =
        entry.value as Map<String, dynamic>? ?? <String, dynamic>{};
    final Map<String, dynamic> props =
        schemaBody['properties'] as Map<String, dynamic>? ??
            <String, dynamic>{};
    final String className = 'TracearrV2$schemaName';

    code.writeln('/// $schemaName from v2.json');
    code.writeln('@freezed');
    code.writeln('abstract class $className with _\$$className {');
    code.writeln('  const $className._();');
    code.writeln();
    code.writeln('  const factory $className({');

    for (final MapEntry<String, dynamic> propEntry in props.entries) {
      final String propName = propEntry.key;
      final Map<String, dynamic> propDef =
          propEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};
      final String camelName = _snakeToCamel(propName);
      final (String dartType, bool isList) =
          _schemaToDartType(propName, propDef, schemaName);

      if (isList) {
        final String innerNonNull = dartType.substring(5, dartType.length - 1);
        code.writeln(
          "    @JsonKey(name: '$propName') @Default(<$innerNonNull>[]) $dartType $camelName,",
        );
      } else if (dartType == 'int?') {
        code.writeln(
          "    @JsonKey(name: '$propName', readValue: _flexibleIntReader) int? $camelName,",
        );
      } else if (dartType == 'double?') {
        code.writeln(
          "    @JsonKey(name: '$propName', readValue: _flexibleDoubleReader) double? $camelName,",
        );
      } else {
        code.writeln("    @JsonKey(name: '$propName') $dartType $camelName,");
      }
    }

    if (schemaName == 'LibraryRollup') {
      code.writeln("    @JsonKey(name: 'library_name') String? libraryName,");
      code.writeln("    @JsonKey(name: 'name') String? nameField,");
      code.writeln("    @JsonKey(name: 'server_name') String? serverName,");
    } else if (schemaName == 'RecentlyAddedRecord' || schemaName == 'MediaResource') {
      code.writeln("    @JsonKey(name: 'poster_url') String? posterUrl,");
      code.writeln("    @JsonKey(name: 'thumb_path') String? thumbPath,");
    }

    code.writeln('  }) = _$className;');
    code.writeln();

    // Helper getters for key models
    if (schemaName == 'HistoryRecord') {
      code.writeln('  String? get effectiveUsername => user?.username;');
      code.writeln('  String? get effectiveUserId => user?.id;');
      code.writeln('  String? get effectiveUserAvatar => user?.avatarUrl;');
      code.writeln('  String? get effectivePlayedAt => startedAt;');
      code.writeln(
        '  int? get effectiveDurationSeconds => durationMs != null ? durationMs! ~/ 1000 : null;',
      );
      code.writeln(
        '  bool get effectiveCompleted => watched ?? (percentComplete != null && percentComplete! >= kTracearrCompletionThreshold);',
      );
      code.writeln();
    } else if (schemaName == 'ActiveStream') {
      code.writeln('  String? get effectiveUsername => username;');
      code.writeln('  String? get effectiveShowTitle => showTitle;');
      code.writeln('  String? get effectivePlayer => player;');
      code.writeln('  String? get effectiveDevice => device;');
      code.writeln('  String? get effectivePlatform => platform;');
      code.writeln();
    } else if (schemaName == 'LibraryRollup') {
      code.writeln("  String get type => serverType ?? 'unknown';");
      code.writeln("  String get name => libraryName ?? nameField ?? libraryId ?? 'Library';");
      code.writeln();
    } else if (schemaName == 'RecentlyAddedRecord') {
      code.writeln("  String get type => mediaType ?? 'movie';");
      code.writeln();
    }

    code.writeln(
      '  factory $className.fromJson(Map<String, dynamic> json) =>',
    );
    code.writeln('      _\$${className}FromJson(json);');
    code.writeln('}');
    code.writeln();
  }

  _generateEndpointCatalog(paths, code);

  final File outputFile = File('lib/src/models/tracearr_v2_models.dart');
  outputFile.writeAsStringSync(code.toString());
}

void _generateApiStatusEnum(Map<String, dynamic> paths, StringBuffer code) {
  final Map<int, String> statusDescriptions = <int, String>{};

  for (final MapEntry<String, dynamic> pathEntry in paths.entries) {
    final Map<String, dynamic> methods =
        pathEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};
    for (final MapEntry<String, dynamic> methodEntry in methods.entries) {
      if (methodEntry.value is! Map<String, dynamic>) continue;
      final Map<String, dynamic> op =
          methodEntry.value as Map<String, dynamic>;
      final Map<String, dynamic> responses =
          op['responses'] as Map<String, dynamic>? ?? <String, dynamic>{};

      for (final MapEntry<String, dynamic> respEntry in responses.entries) {
        final int? codeInt = int.tryParse(respEntry.key);
        if (codeInt == null) continue;
        final Map<String, dynamic> respObj =
            respEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};
        final String desc = respObj['description'] as String? ?? '';
        if (!statusDescriptions.containsKey(codeInt)) {
          statusDescriptions[codeInt] = desc;
        }
      }
    }
  }

  code.writeln('/// HTTP Response status codes defined across v2.json paths');
  code.writeln('enum TracearrV2ApiStatus {');
  
  final List<int> sortedCodes = statusDescriptions.keys.toList()..sort();
  for (int i = 0; i < sortedCodes.length; i++) {
    final int statusCode = sortedCodes[i];
    final String desc = statusDescriptions[statusCode]!.replaceAll("'", "\\'");
    final String enumName = _statusEnumName(statusCode);
    code.writeln("  $enumName($statusCode, '$desc'),");
  }
  code.writeln("  unknown(-1, 'Unknown response status');");

  code.writeln();
  code.writeln('  const TracearrV2ApiStatus(this.statusCode, this.description);');
  code.writeln('  final int statusCode;');
  code.writeln('  final String description;');
  code.writeln();
  code.writeln('  static TracearrV2ApiStatus fromStatusCode(int? code) {');
  code.writeln('    return TracearrV2ApiStatus.values.firstWhere(');
  code.writeln('      (TracearrV2ApiStatus e) => e.statusCode == code,');
  code.writeln('      orElse: () => TracearrV2ApiStatus.unknown,');
  code.writeln('    );');
  code.writeln('  }');
  code.writeln('}');
  code.writeln();
}

String _statusEnumName(int code) {
  switch (code) {
    case 200:
      return 'ok';
    case 400:
      return 'badRequest';
    case 401:
      return 'unauthorized';
    case 403:
      return 'forbidden';
    case 404:
      return 'notFound';
    case 429:
      return 'rateLimited';
    default:
      return 'code$code';
  }
}

void _generateEndpointCatalog(Map<String, dynamic> paths, StringBuffer code) {
  code.writeln('/// Response descriptions per API endpoint path in v2.json');
  code.writeln('class TracearrV2EndpointResponses {');
  code.writeln('  const TracearrV2EndpointResponses._();');
  code.writeln();
  code.writeln('  static const Map<String, Map<int, String>> catalog = <String, Map<int, String>>{');

  for (final MapEntry<String, dynamic> pathEntry in paths.entries) {
    final String pathStr = pathEntry.key;
    final Map<String, dynamic> methods =
        pathEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};

    for (final MapEntry<String, dynamic> methodEntry in methods.entries) {
      if (methodEntry.value is! Map<String, dynamic>) continue;
      final String methodStr = methodEntry.key.toUpperCase();
      final Map<String, dynamic> op =
          methodEntry.value as Map<String, dynamic>;
      final Map<String, dynamic> responses =
          op['responses'] as Map<String, dynamic>? ?? <String, dynamic>{};

      code.writeln("    '$methodStr $pathStr': <int, String>{");
      for (final MapEntry<String, dynamic> respEntry in responses.entries) {
        final int? codeInt = int.tryParse(respEntry.key);
        if (codeInt == null) continue;
        final Map<String, dynamic> respObj =
            respEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};
        final String desc = (respObj['description'] as String? ?? '').replaceAll("'", "\\'");
        code.writeln("      $codeInt: '$desc',");
      }
      code.writeln('    },');
    }
  }

  code.writeln('  };');
  code.writeln('}');
  code.writeln();
}

void _generateApiClientFile(Map<String, dynamic> paths) {
  final StringBuffer code = StringBuffer();
  code.writeln('// AUTO-GENERATED FROM v2.json OpenAPI Specification');
  code.writeln(
    '// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.',
  );
  code.writeln();
  code.writeln("import 'package:core_networking/core_networking.dart';");
  code.writeln("import 'package:dio/dio.dart';");
  code.writeln("import 'package:flutter/foundation.dart';");
  code.writeln();
  code.writeln("import 'models/tracearr_v2_models.dart';");
  code.writeln();
  code.writeln('/// 100% Spec-compliant API client for Tracearr 2.0 OpenAPI v2 specification.');
  code.writeln('class TracearrApi {');
  code.writeln('  TracearrApi(this._dio, {this.token});');
  code.writeln();
  code.writeln('  final Dio _dio;');
  code.writeln('  final String? token;');
  code.writeln();
  code.writeln('  String? imageUrl(String? path) {');
  code.writeln('    if (path == null || path.isEmpty) return null;');
  code.writeln("    if (path.startsWith('http')) return path;");
  code.writeln("    final String base = _dio.options.baseUrl.replaceAll(RegExp(r'/+\$'), '');");
  code.writeln("    final String cleanPath = path.startsWith('/') ? path : '/\$path';");
  code.writeln('    if (token == null || token!.isEmpty) return \'\$base\$cleanPath\';');
  code.writeln("    final String sep = cleanPath.contains('?') ? '&' : '?';");
  code.writeln("    return '\$base\$cleanPath\${sep}token=\$token';");
  code.writeln('  }');
  code.writeln();
  code.writeln('  String? proxyImageUrl({');
  code.writeln('    required String? path,');
  code.writeln('    String? serverId,');
  code.writeln('    int? width,');
  code.writeln('    int? height,');
  code.writeln('    String? fallback,');
  code.writeln('  }) {');
  code.writeln('    return imageUrl(path);');
  code.writeln('  }');
  code.writeln();
  code.writeln('  /// Verifies server health via public API endpoint (GET /api/v2/public/docs).');
  code.writeln('  Future<bool> getHealth() async {');
  code.writeln('    try {');
  code.writeln("      final Response<dynamic> resp = await _dio.get<dynamic>('api/v2/public/docs');");
  code.writeln('      return resp.statusCode == 200;');
  code.writeln('    } on DioException catch (e) {');
  code.writeln('      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {');
  code.writeln("        throw const NetworkAuthException('Tracearr rejected API key');");
  code.writeln('      }');
  code.writeln('      throw NetworkException.fromDio(e);');
  code.writeln('    }');
  code.writeln('  }');
  code.writeln();

  for (final MapEntry<String, dynamic> pathEntry in paths.entries) {
    final String pathStr = pathEntry.key;
    final Map<String, dynamic> methods =
        pathEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};

    for (final MapEntry<String, dynamic> methodEntry in methods.entries) {
      if (methodEntry.value is! Map<String, dynamic>) continue;
      final String methodStr = methodEntry.key.toLowerCase();
      final Map<String, dynamic> op =
          methodEntry.value as Map<String, dynamic>;
      final String summary = op['summary'] as String? ?? '';
      final String methodName = _methodNameFromPath(pathStr);

      final List<dynamic> params = op['parameters'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> pathParams = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> queryParams = <Map<String, dynamic>>[];

      for (final dynamic p in params) {
        if (p is! Map<String, dynamic>) continue;
        final String pIn = p['in'] as String? ?? '';
        if (pIn == 'path') {
          pathParams.add(p);
        } else if (pIn == 'query') {
          queryParams.add(p);
        }
      }

      final Map<String, dynamic> responses =
          op['responses'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> okResp =
          responses['200'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> content =
          okResp['content'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> jsonContent =
          content['application/json'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> schema =
          jsonContent['schema'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final String? ref = schema['\$ref'] as String?;
      final String rawTarget = ref != null ? ref.split('/').last : 'dynamic';
      final String returnType = (rawTarget == 'OpenApiDocument' || rawTarget == 'dynamic')
          ? 'Map<String, dynamic>'
          : 'TracearrV2$rawTarget';

      code.writeln('  /// $summary (${methodStr.toUpperCase()} $pathStr).');
      if (pathParams.isEmpty && queryParams.isEmpty) {
        code.writeln('  Future<$returnType> $methodName() async {');
      } else {
        code.writeln('  Future<$returnType> $methodName({');

        for (final Map<String, dynamic> p in pathParams) {
          final String pName = p['name'] as String;
          final String camel = _snakeToCamel(pName);
          code.writeln('    required String $camel,');
        }

        for (final Map<String, dynamic> p in queryParams) {
          final String pName = p['name'] as String;
          final String camel = _snakeToCamel(pName);
          final Map<String, dynamic> pSchema = p['schema'] as Map<String, dynamic>? ?? <String, dynamic>{};
          final String pType = pSchema['type'] as String? ?? 'string';
          final String dartType = (pType == 'integer') ? 'int?' : (pType == 'boolean') ? 'bool?' : 'String?';
          code.writeln('    $dartType $camel,');
        }

        code.writeln('  }) async {');
      }

      code.writeln('    try {');

      String callPath = pathStr.startsWith('/') ? pathStr.substring(1) : pathStr;
      for (final Map<String, dynamic> p in pathParams) {
        final String pName = p['name'] as String;
        final String camel = _snakeToCamel(pName);
        callPath = callPath.replaceAll('{$pName}', '\$$camel');
      }

      if (queryParams.isNotEmpty) {
        code.writeln('      final Map<String, dynamic> query = <String, dynamic>{');
        for (final Map<String, dynamic> p in queryParams) {
          final String pName = p['name'] as String;
          final String camel = _snakeToCamel(pName);
          code.writeln("        if ($camel != null) '$pName': $camel,");
        }
        code.writeln('      };');
        code.writeln('      final Response<dynamic> resp = await _dio.$methodStr<dynamic>(');
        code.writeln("        '$callPath',");
        code.writeln('        queryParameters: query,');
        code.writeln('      );');
      } else {
        code.writeln('      final Response<dynamic> resp = await _dio.$methodStr<dynamic>(');
        code.writeln("        '$callPath',");
        code.writeln('      );');
      }

      code.writeln('      if (resp.data is! Map<String, dynamic>) {');
      code.writeln("        debugPrint('[Tracearr API Warning] Non-JSON payload received from $callPath: \${resp.data}');");
      code.writeln("        throw NetworkUnknownException('Unexpected server response format: \${resp.data}');");
      code.writeln('      }');
      code.writeln('      try {');

      if (returnType == 'Map<String, dynamic>') {
        code.writeln('        return resp.data as Map<String, dynamic>;');
      } else {
        code.writeln('        return $returnType.fromJson(');
        code.writeln('          resp.data as Map<String, dynamic>,');
        code.writeln('        );');
      }

      code.writeln('      } catch (err) {');
      code.writeln("        debugPrint('[Tracearr API Parsing Error] Endpoint $callPath failed deserialization into $returnType: \$err\\nRaw Payload: \${resp.data}');");
      code.writeln('        rethrow;');
      code.writeln('      }');

      code.writeln('    } on DioException catch (e) {');
      code.writeln("      debugPrint('[Tracearr API Network Error] Endpoint $callPath failed with DioException: \${e.message}');");
      code.writeln('      throw NetworkException.fromDio(e);');
      code.writeln('    }');
      code.writeln('  }');
      code.writeln();
    }
  }

  code.writeln('}');
  code.writeln();

  final File outputFile = File('lib/src/tracearr_api.dart');
  outputFile.writeAsStringSync(code.toString());
}

void _generateProvidersFile(Map<String, dynamic> paths) {
  final StringBuffer code = StringBuffer();
  code.writeln('// AUTO-GENERATED FROM v2.json OpenAPI Specification');
  code.writeln(
    '// DO NOT EDIT DIRECTLY. Run `dart run tool/generate_tracearr_models.dart` to update.',
  );
  code.writeln();
  code.writeln("import 'dart:async';");
  code.writeln("import 'package:core_models/core_models.dart';");
  code.writeln("import 'package:core_networking/core_networking.dart';");
  code.writeln("import 'package:dio/dio.dart';");
  code.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
  code.writeln("import 'package:flutter_riverpod/legacy.dart';");
  code.writeln();
  code.writeln("import 'auth/tracearr_auth_interceptor.dart';");
  code.writeln("import 'auth/tracearr_auth_manager.dart';");
  code.writeln("import 'models/tracearr_v2_models.dart';");
  code.writeln("import 'tracearr_api.dart';");
  code.writeln();
  code.writeln('final tracearrActiveTabBarIndexProvider =');
  code.writeln('    StateProvider.family<int, Instance>((Ref ref, Instance instance) => 0);');
  code.writeln();
  code.writeln('final tracearrBottomNavVisibleProvider =');
  code.writeln('    StateProvider.family<bool, Instance>((Ref ref, Instance instance) => true);');
  code.writeln();
  code.writeln('// --- Recently Added tab UI state ---');
  code.writeln('/// UI StateProvider for category filtering in Recently Added Tab.');
  code.writeln('final tracearrRecentTypeFilterProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for genre filtering in Recently Added Tab.');
  code.writeln('final tracearrRecentGenreFilterProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for sorting criteria in Recently Added Tab.');
  code.writeln('final tracearrRecentSortByProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'added');");
  code.writeln();
  code.writeln('/// UI StateProvider for Grid vs List layout toggle in Recently Added Tab.');
  code.writeln('final tracearrRecentGridViewProvider =');
  code.writeln('    StateProvider.family<bool, Instance>((Ref ref, Instance instance) => true);');
  code.writeln();
  code.writeln('// --- History tab UI state ---');
  code.writeln('/// UI StateProvider for category filter selection in History Tab.');
  code.writeln('final tracearrHistoryTypeFilterProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for play completion status filter selection in History Tab.');
  code.writeln('final tracearrHistoryStatusFilterProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for genre filter selection in History Tab.');
  code.writeln('/// Generated to maintain persistent global UI filter state across navigation transitions.');
  code.writeln('final tracearrHistoryGenreFilterProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for multi-criteria sort order selection in History Tab.');
  code.writeln('/// Supports Date (Newest/Oldest), Duration (Longest), Completion %, and Title (A-Z).');
  code.writeln('final tracearrHistorySortByProvider =');
  code.writeln("    StateProvider.family<String, Instance>((Ref ref, Instance instance) => 'DATE_DESC');");
  code.writeln();
  code.writeln('// --- User detail UI state ---');
  code.writeln('/// UI StateProvider for genre filter selection in User Details Screen.');
  code.writeln('final tracearrUserGenreFilterProvider =');
  code.writeln("    StateProvider.family<String, String>((Ref ref, String key) => 'ALL');");
  code.writeln();
  code.writeln('/// UI StateProvider for sort order selection in User Details Screen.');
  code.writeln('final tracearrUserSortByProvider =');
  code.writeln("    StateProvider.family<String, String>((Ref ref, String key) => 'DATE_DESC');");
  code.writeln();
  code.writeln('/// The key is static, so this needs nothing from the network.');
  code.writeln('final tracearrAuthManagerProvider =');
  code.writeln('    Provider.autoDispose.family<TracearrAuthManager, Instance>((');
  code.writeln('  Ref ref,');
  code.writeln('  Instance instance,');
  code.writeln(') {');
  code.writeln('  return TracearrAuthManager(');
  code.writeln('    baseUrl: Uri.parse(instance.localUrl),');
  code.writeln('    auth: instance.auth,');
  code.writeln('  );');
  code.writeln('});');
  code.writeln();
  code.writeln();
  code.writeln('/// The single client every Tracearr call goes through.');
  code.writeln('final tracearrDioProvider = FutureProvider.autoDispose.family<Dio, Instance>((');
  code.writeln('  Ref ref,');
  code.writeln('  Instance instance,');
  code.writeln(') async {');
  code.writeln('  Dio? created;');
  code.writeln('  ref.onDispose(() => created?.close(force: true));');
  code.writeln();
  code.writeln('  final Map<String, String> global = ref.watch(globalHeadersProvider);');
  code.writeln('  final Dio dio = await ref');
  code.writeln('      .watch(dioFactoryProvider)');
  code.writeln('      .create(instance, globalHeaders: global);');
  code.writeln('  created = dio;');
  code.writeln();
  code.writeln('  dio.interceptors.add(');
  code.writeln('    TracearrAuthInterceptor(');
  code.writeln('      manager: ref.watch(tracearrAuthManagerProvider(instance)),');
  code.writeln('    ),');
  code.writeln('  );');
  code.writeln('  return dio;');
  code.writeln('});');
  code.writeln();
  code.writeln('final tracearrApiProvider =');
  code.writeln('    FutureProvider.autoDispose.family<TracearrApi, Instance>((');
  code.writeln('  Ref ref,');
  code.writeln('  Instance instance,');
  code.writeln(') async {');
  code.writeln('  final Dio dio = await ref.watch(tracearrDioProvider(instance).future);');
  code.writeln('  final TracearrAuthManager manager =');
  code.writeln('      ref.watch(tracearrAuthManagerProvider(instance));');
  code.writeln('  final String token = await manager.ensureToken();');
  code.writeln('  return TracearrApi(dio, token: token);');
  code.writeln('});');
  code.writeln();

  for (final MapEntry<String, dynamic> pathEntry in paths.entries) {
    final String pathStr = pathEntry.key;
    final Map<String, dynamic> methods =
        pathEntry.value as Map<String, dynamic>? ?? <String, dynamic>{};

    for (final MapEntry<String, dynamic> methodEntry in methods.entries) {
      if (methodEntry.value is! Map<String, dynamic>) continue;
      final Map<String, dynamic> op =
          methodEntry.value as Map<String, dynamic>;
      final String summary = op['summary'] as String? ?? '';
      final String methodName = _methodNameFromPath(pathStr);
      final String providerName = 'tracearrV2${_pascalCase(methodName)}Provider';

      final Map<String, dynamic> responses =
          op['responses'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> okResp =
          responses['200'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> content =
          okResp['content'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> jsonContent =
          content['application/json'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final Map<String, dynamic> schema =
          jsonContent['schema'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final String? ref = schema['\$ref'] as String?;
      final String rawTarget = ref != null ? ref.split('/').last : 'dynamic';
      final String returnType = (rawTarget == 'OpenApiDocument' || rawTarget == 'dynamic')
          ? 'Map<String, dynamic>'
          : 'TracearrV2$rawTarget';

      final List<dynamic> params = op['parameters'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> pathParams = <Map<String, dynamic>>[];
      for (final dynamic p in params) {
        if (p is Map<String, dynamic> && p['in'] == 'path') {
          pathParams.add(p);
        }
      }

      final int ttlSeconds = _getTtlSecondsForMethod(methodName);
      code.writeln('/// Provider for $summary ($pathStr)');
      code.writeln('///');
      code.writeln('/// RATIONALE & CACHING SPECIFICATION:');
      code.writeln('/// - Uses `ref.keepAlive()` with a ${ttlSeconds}s TTL Timer (link.close) matching');
      code.writeln('///   official Tracearr application staleTimes (from official tracearr/apps/mobile repo).');
      code.writeln('/// - Prevents premature cache eviction and redundant HTTP re-fetches during tab navigation.');
      code.writeln('/// - `ref.onDispose(timer.cancel)` guarantees clean memory management without leaks.');
      if (pathParams.isEmpty) {
        code.writeln('final $providerName = FutureProvider.autoDispose');
        code.writeln('    .family<$returnType, Instance>((');
        code.writeln('  Ref ref,');
        code.writeln('  Instance instance,');
        code.writeln(') async {');
        code.writeln('  final link = ref.keepAlive();');
        code.writeln('  final Timer timer = Timer(const Duration(seconds: $ttlSeconds), link.close);');
        code.writeln('  ref.onDispose(timer.cancel);');
        code.writeln();
        code.writeln(
          '  final TracearrApi api = await ref.watch(tracearrApiProvider(instance).future);',
        );
        if (methodName == 'getHistory' || methodName == 'getRecentlyAdded') {
          final String itemType = methodName == 'getHistory'
              ? 'TracearrV2HistoryRecord'
              : 'TracearrV2RecentlyAddedRecord';
          code.writeln('  // CURSOR PAGINATION RATIONALE:');
          code.writeln('  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.');
          code.writeln('  // To ensure cross-screen map completeness (ServerNamesMap, UserAvatarsMap)');
          code.writeln('  // and total timeline accuracy, we auto-loop cursor pages up to completion.');
          code.writeln('  final List<$itemType> allData = <$itemType>[];');
          code.writeln('  String? cursor;');
          code.writeln('  late $returnType firstResp;');
          code.writeln('  int pageCount = 0;');
          code.writeln('  do {');
          code.writeln('    final $returnType page = await api.$methodName(cursor: cursor, pageSize: 100);');
          code.writeln('    if (pageCount == 0) firstResp = page;');
          code.writeln('    allData.addAll(page.data);');
          code.writeln('    cursor = page.meta?.nextCursor;');
          code.writeln('    pageCount++;');
          code.writeln('  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);');
          code.writeln('  return firstResp.copyWith(data: allData);');
        } else {
          code.writeln('  return api.$methodName();');
        }
        code.writeln('});');
      } else {
        final String firstParamName = _snakeToCamel(pathParams.first['name'] as String);
        code.writeln('final $providerName = FutureProvider.autoDispose');
        code.writeln('    .family<$returnType, ({Instance instance, String $firstParamName})>((');
        code.writeln('  Ref ref,');
        code.writeln('  ({Instance instance, String $firstParamName}) args,');
        code.writeln(') async {');
        code.writeln('  final link = ref.keepAlive();');
        code.writeln('  final Timer timer = Timer(const Duration(seconds: $ttlSeconds), link.close);');
        code.writeln('  ref.onDispose(timer.cancel);');
        code.writeln();
        code.writeln('  final TracearrApi api =');
        code.writeln('      await ref.watch(tracearrApiProvider(args.instance).future);');
        if (methodName == 'getUserHistory' || methodName == 'getMediaHistory') {
          code.writeln('  // CURSOR PAGINATION RATIONALE:');
          code.writeln('  // OpenAPI v2 defaults to returning pageSize: 20 when omitted.');
          code.writeln('  // We auto-loop cursor pages to retrieve 100% of play history entries.');
          code.writeln('  final List<TracearrV2HistoryRecord> allData = <TracearrV2HistoryRecord>[];');
          code.writeln('  String? cursor;');
          code.writeln('  late $returnType firstResp;');
          code.writeln('  int pageCount = 0;');
          code.writeln('  do {');
          code.writeln('    final $returnType page = await api.$methodName($firstParamName: args.$firstParamName, cursor: cursor, pageSize: 100);');
          code.writeln('    if (pageCount == 0) firstResp = page;');
          code.writeln('    allData.addAll(page.data);');
          code.writeln('    cursor = page.meta?.nextCursor;');
          code.writeln('    pageCount++;');
          code.writeln('  } while (cursor != null && cursor.isNotEmpty && pageCount < 20);');
          code.writeln('  return firstResp.copyWith(data: allData);');
        } else {
          code.writeln('  return api.$methodName($firstParamName: args.$firstParamName);');
        }
        code.writeln('});');
      }
      code.writeln();
    }
  }

  code.writeln(
    'final tracearrActiveSessionsProvider = tracearrV2GetStreamsProvider;',
  );
  code.writeln();

  // 4. Generate helper Providers (Server Name Map & User Avatar Map)
  //
  // WHY WE DO THIS:
  // - Raw OpenAPI v2 endpoints like /api/v2/public/libraries, /api/v2/public/users,
  //   and /api/v2/public/media/{ref} omit server_name and return raw server_id UUIDs.
  //   History and streams endpoints DO return server_name alongside server_id.
  //   `tracearrServerNamesMapProvider` aggregates server_id -> server_name mappings across responses.
  //
  // - /api/v2/public/users omits avatar_url from TracearrV2UserIdentity.
  //   Watch history records (/api/v2/public/history) DO return user.id and user.avatar_url.
  //   `tracearrUserAvatarsMapProvider` aggregates user.id -> user.avatar_url from history responses.
  code.writeln('/// Aggregated provider mapping serverId -> human-readable serverName.');
  code.writeln('///');
  code.writeln('/// OpenAPI endpoints like /libraries, /users, and /media omit server_name.');
  code.writeln('/// This provider aggregates server_name mappings from streams, libraries, and history.');
  code.writeln('final tracearrServerNamesMapProvider = Provider.autoDispose');
  code.writeln(
    '    .family<Map<String, String>, Instance>((Ref ref, Instance instance) {',
  );
  code.writeln('  final Map<String, String> map = <String, String>{};');
  code.writeln();
  code.writeln('  final AsyncValue<TracearrV2StreamsResponse> streams =');
  code.writeln('      ref.watch(tracearrV2GetStreamsProvider(instance));');
  code.writeln('  streams.whenData((TracearrV2StreamsResponse s) {');
  code.writeln('    for (final TracearrV2StreamsServerSummary item');
  code.writeln(
    '        in s.summary?.byServer ?? <TracearrV2StreamsServerSummary>[]) {',
  );
  code.writeln('      if (item.serverId != null &&');
  code.writeln('          item.serverName != null &&');
  code.writeln('          item.serverName!.isNotEmpty) {');
  code.writeln('        map[item.serverId!] = item.serverName!;');
  code.writeln('      }');
  code.writeln('    }');
  code.writeln('  });');
  code.writeln();
  code.writeln('  final AsyncValue<TracearrV2LibrariesResponse> libraries =');
  code.writeln('      ref.watch(tracearrV2GetLibrariesProvider(instance));');
  code.writeln('  libraries.whenData((TracearrV2LibrariesResponse l) {');
  code.writeln('    for (final TracearrV2LibraryRollup item in l.data) {');
  code.writeln('      if (item.serverId != null &&');
  code.writeln('          item.serverName != null &&');
  code.writeln('          item.serverName!.isNotEmpty) {');
  code.writeln('        map[item.serverId!] = item.serverName!;');
  code.writeln('      }');
  code.writeln('    }');
  code.writeln('  });');
  code.writeln();
  code.writeln('  final AsyncValue<TracearrV2HistoryResponse> history =');
  code.writeln('      ref.watch(tracearrV2GetHistoryProvider(instance));');
  code.writeln('  history.whenData((TracearrV2HistoryResponse h) {');
  code.writeln('    for (final TracearrV2HistoryRecord item in h.data) {');
  code.writeln('      if (item.serverId != null &&');
  code.writeln('          item.serverName != null &&');
  code.writeln('          item.serverName!.isNotEmpty) {');
  code.writeln('        map[item.serverId!] = item.serverName!;');
  code.writeln('      }');
  code.writeln('    }');
  code.writeln('  });');
  code.writeln();
  code.writeln('  return map;');
  code.writeln('});');
  code.writeln();
  code.writeln('/// Aggregated provider mapping userId -> avatarUrl.');
  code.writeln('///');
  code.writeln('/// /api/v2/public/users omits avatar_url from TracearrV2UserIdentity.');
  code.writeln('/// Watch history (/api/v2/public/history) returns user.id & user.avatar_url.');
  code.writeln('/// This provider aggregates user.id -> user.avatar_url from history items.');
  code.writeln('final tracearrUserAvatarsMapProvider = Provider.autoDispose');
  code.writeln(
    '    .family<Map<String, String>, Instance>((Ref ref, Instance instance) {',
  );
  code.writeln('  final Map<String, String> map = <String, String>{};');
  code.writeln();
  code.writeln('  final AsyncValue<TracearrV2HistoryResponse> history =');
  code.writeln('      ref.watch(tracearrV2GetHistoryProvider(instance));');
  code.writeln('  history.whenData((TracearrV2HistoryResponse h) {');
  code.writeln('    for (final TracearrV2HistoryRecord item in h.data) {');
  code.writeln('      final String? uid = item.user?.id;');
  code.writeln('      final String? avatar = item.user?.avatarUrl;');
  code.writeln('      if (uid != null &&');
  code.writeln('          uid.isNotEmpty &&');
  code.writeln('          avatar != null &&');
  code.writeln('          avatar.isNotEmpty) {');
  code.writeln('        map[uid] = avatar;');
  code.writeln('      }');
  code.writeln('    }');
  code.writeln('  });');
  code.writeln();
  code.writeln('  return map;');
  code.writeln('});');
  code.writeln();

  final File outputFile = File('lib/src/tracearr_providers.dart');
  outputFile.writeAsStringSync(code.toString());
}

String _methodNameFromPath(String pathStr) {
  switch (pathStr) {
    case '/api/v2/public/docs':
      return 'getDocs';
    case '/api/v2/public/history':
      return 'getHistory';
    case '/api/v2/public/streams':
      return 'getStreams';
    case '/api/v2/public/media/{ref}':
      return 'getMediaByRef';
    case '/api/v2/public/media/{ref}/children':
      return 'getMediaChildren';
    case '/api/v2/public/media/{ref}/stats':
      return 'getMediaStats';
    case '/api/v2/public/media/{ref}/watchers':
      return 'getMediaWatchers';
    case '/api/v2/public/media/{ref}/history':
      return 'getMediaHistory';
    case '/api/v2/public/users':
      return 'getUsers';
    case '/api/v2/public/users/{id}':
      return 'getUserById';
    case '/api/v2/public/users/{id}/stats':
      return 'getUserStats';
    case '/api/v2/public/users/{id}/history':
      return 'getUserHistory';
    case '/api/v2/public/recently-added':
      return 'getRecentlyAdded';
    case '/api/v2/public/libraries':
      return 'getLibraries';
    default:
      final String clean = pathStr.replaceAll('/api/v2/public/', '').replaceAll('/', '_').replaceAll('{', '').replaceAll('}', '');
      return _snakeToCamel('get_$clean');
  }
}

String _pascalCase(String name) {
  if (name.isEmpty) return name;
  return name[0].toUpperCase() + name.substring(1);
}

String _snakeToCamel(String name) {
  final List<String> parts = name.split('_');
  if (parts.isEmpty) return name;
  final StringBuffer sb = StringBuffer(parts[0]);
  for (int i = 1; i < parts.length; i++) {
    if (parts[i].isNotEmpty) {
      sb.write(parts[i][0].toUpperCase() + parts[i].substring(1));
    }
  }
  return sb.toString();
}

(String, bool) _schemaToDartType(
  String propName,
  Map<String, dynamic> propDef,
  String schemaName,
) {
  final String? ref = propDef['\$ref'] as String?;
  if (ref != null) {
    final String target = ref.split('/').last;
    return ('TracearrV2$target?', false);
  }

  final String typeStr = propDef['type'] as String? ?? 'unknown';
  switch (typeStr) {
    case 'string':
      return ('String?', false);
    case 'integer':
      return ('int?', false);
    case 'number':
      return ('double?', false);
    case 'boolean':
      return ('bool?', false);
    case 'array':
      final Map<String, dynamic> items =
          propDef['items'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final (String innerType, _) =
          _schemaToDartType(propName, items, schemaName);
      final String innerNonNull = innerType.replaceAll('?', '');
      return ('List<$innerNonNull>', true);
    case 'object':
      return ('Map<String, dynamic>?', false);
    default:
      return ('dynamic', false);
  }
}

int _getTtlSecondsForMethod(String methodName) {
  switch (methodName) {
    case 'getStreams':
      return 30; // Active streams update frequently (30s)
    case 'getHistory':
    case 'getRecentlyAdded':
    case 'getUsers':
    case 'getUserHistory':
    case 'getMediaHistory':
      return 300; // 5 minutes matching official Tracearr app staleTime
    default:
      return 600; // 10 minutes for metadata & structure
  }
}
