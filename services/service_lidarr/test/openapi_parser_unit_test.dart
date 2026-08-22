// ignore_for_file: prefer_single_quotes, require_trailing_commas, inference_failure_on_collection_literal, avoid_dynamic_calls
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/openapi_parser.dart';

void main() {
  group('OpenAPI Parser Unit & Edge Case Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lidarr_parser_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. required vs nullable combinations', () {
      final spec = {
        'components': {
          'schemas': {
            'TestNullability': {
              'type': 'object',
              'required': ['reqNonNullable', 'reqNullable'],
              'properties': {
                'reqNonNullable': {'type': 'string'},
                'reqNullable': {'type': 'string', 'nullable': true},
                'optNonNullable': {'type': 'string'},
                'optNullable': {'type': 'string', 'nullable': true},
              }
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final modelFile = File('${tempDir.path}/models/test_nullability.dart');
      expect(modelFile.existsSync(), isTrue);
      final content = modelFile.readAsStringSync();

      // required non-nullable -> required String
      expect(content, contains("required String reqNonNullable,"));
      // required nullable -> String?
      expect(content, contains("String? reqNullable,"));
      // optional non-nullable -> String?
      expect(content, contains("String? optNonNullable,"));
      // optional nullable -> String?
      expect(content, contains("String? optNullable,"));
    });

    test('2. Parameter types and request body typing in API clients', () {
      final spec = {
        'components': {
          'schemas': {
            'ItemDTO': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'}
              }
            }
          }
        },
        'paths': {
          '/api/v1/item/{id}': {
            'get': {
              'tags': ['Item'],
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'integer'}
                },
                {
                  'name': 'active',
                  'in': 'query',
                  'required': false,
                  'schema': {'type': 'boolean'}
                },
                {
                  'name': 'tags',
                  'in': 'query',
                  'required': true,
                  'schema': {
                    'type': 'array',
                    'items': {'type': 'integer'}
                  }
                }
              ],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/ItemDTO'}
                    }
                  }
                }
              }
            },
            'put': {
              'tags': ['Item'],
              'parameters': [
                {
                  'name': 'id',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'integer'}
                }
              ],
              'requestBody': {
                'required': true,
                'content': {
                  'application/json': {
                    'schema': {r'$ref': '#/components/schemas/ItemDTO'}
                  }
                }
              },
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/ItemDTO'}
                    }
                  }
                }
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_item_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final content = apiFile.readAsStringSync();

      // GET method signature with typed path and query parameters
      expect(content, contains('required int id'));
      expect(content, contains('bool? active'));
      expect(content, contains('required List<int> tags'));

      // PUT method signature with typed request body
      expect(content, contains('required ItemDTO body'));
      expect(content, contains('data: body?.toJson(),'));
    });

    test('3. allOf composition and property inheritance', () {
      final spec = {
        'components': {
          'schemas': {
            'BaseEntity': {
              'type': 'object',
              'required': ['id'],
              'properties': {
                'id': {'type': 'integer'}
              }
            },
            'ExtendedEntity': {
              'allOf': [
                {r'$ref': '#/components/schemas/BaseEntity'},
                {
                  'type': 'object',
                  'required': ['name'],
                  'properties': {
                    'name': {'type': 'string'}
                  }
                }
              ]
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final modelFile = File('${tempDir.path}/models/extended_entity.dart');
      expect(modelFile.existsSync(), isTrue);
      final content = modelFile.readAsStringSync();

      expect(content, contains("required int id,"));
      expect(content, contains("required String name,"));
    });

    test('4. Typed additionalProperties (Maps)', () {
      final spec = {
        'components': {
          'schemas': {
            'MapResource': {
              'type': 'object',
              'properties': {
                'stringMap': {
                  'type': 'object',
                  'additionalProperties': {'type': 'string'}
                },
                'nullableStringMap': {
                  'type': 'object',
                  'additionalProperties': {'type': 'string', 'nullable': true}
                },
                'nullableIntMap': {
                  'type': 'object',
                  'additionalProperties': {'type': 'integer', 'nullable': true}
                },
                'genericMap': {'type': 'object', 'additionalProperties': true}
              }
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final modelFile = File('${tempDir.path}/models/map_resource.dart');
      expect(modelFile.existsSync(), isTrue);
      final content = modelFile.readAsStringSync();

      expect(content, contains('Map<String, String>? stringMap,'));
      expect(content, contains('Map<String, String?>? nullableStringMap,'));
      expect(content, contains('Map<String, int?>? nullableIntMap,'));
      expect(content, contains('Map<String, dynamic>? genericMap,'));
    });

    test('5. Integer vs String Enums', () {
      final spec = {
        'components': {
          'schemas': {
            'StringStatus': {
              'type': 'string',
              'enum': ['active', 'paused', 'deleted']
            },
            'IntStatus': {
              'type': 'integer',
              'enum': [0, 1, 2]
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final strEnumFile = File('${tempDir.path}/models/string_status.dart');
      expect(strEnumFile.existsSync(), isTrue);
      final strContent = strEnumFile.readAsStringSync();
      expect(strContent, contains("@JsonValue('active')"));
      expect(strContent, contains("active('active'),"));
      expect(strContent, contains('final String value;'));
      expect(strContent, contains('const StringStatus(this.value);'));

      final intEnumFile = File('${tempDir.path}/models/int_status.dart');
      expect(intEnumFile.existsSync(), isTrue);
      final intContent = intEnumFile.readAsStringSync();
      expect(intContent, contains("@JsonValue(0)"));
      expect(intContent, contains("val0(0),"));
      expect(intContent, contains('final int value;'));
      expect(intContent, contains('const IntStatus(this.value);'));
    });

    test('6. C# generic schema name demangling', () {
      final spec = {
        'components': {
          'schemas': {
            'Lidarr.Api.V1.Artist.ArtistResource': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'}
              }
            },
            'Lidarr.Http.REST.PagingResource`1[[Lidarr.Api.V1.Artist.ArtistResource, Lidarr.Api.V1, Version=1.0.0.0]]':
                {
              'type': 'object',
              'properties': {
                'page': {'type': 'integer'},
                'records': {
                  'type': 'array',
                  'items': {
                    r'$ref':
                        '#/components/schemas/Lidarr.Api.V1.Artist.ArtistResource'
                  }
                }
              }
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final pagingFile =
          File('${tempDir.path}/models/paging_resource_artist_resource.dart');
      expect(pagingFile.existsSync(), isTrue);
      final content = pagingFile.readAsStringSync();
      expect(content, contains('class PagingResourceArtistResource'));
      expect(content, contains('List<ArtistResource>? records,'));
    });

    test('7. Dart reserved keywords sanitization', () {
      final spec = {
        'components': {
          'schemas': {
            'KeywordTest': {
              'type': 'object',
              'properties': {
                'default': {'type': 'string'},
                'case': {'type': 'string'},
                'switch': {'type': 'string'},
                'in': {'type': 'string'},
                'is': {'type': 'string'},
              }
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final modelFile = File('${tempDir.path}/models/keyword_test.dart');
      expect(modelFile.existsSync(), isTrue);
      final content = modelFile.readAsStringSync();

      expect(
          content, contains("@JsonKey(name: 'default') String? defaultVal,"));
      expect(content, contains("@JsonKey(name: 'case') String? caseVal,"));
      expect(content, contains("@JsonKey(name: 'switch') String? switchVal,"));
      expect(content, contains("@JsonKey(name: 'in') String? inVal,"));
      expect(content, contains("@JsonKey(name: 'is') String? isVal,"));
    });

    test('8. Incremental file writing behavior', () {
      final spec = {
        'components': {
          'schemas': {
            'IncTest': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string'}
              }
            }
          }
        },
        'paths': {}
      };

      final parser1 = LidarrOpenApiParser(spec, tempDir.path);
      parser1.generateAll();

      final modelFile = File('${tempDir.path}/models/inc_test.dart');
      expect(modelFile.existsSync(), isTrue);
      final statBefore = modelFile.statSync();

      // Small delay to ensure timestamp comparison is distinguishable if rewritten
      sleep(const Duration(milliseconds: 50));

      final parser2 = LidarrOpenApiParser(spec, tempDir.path);
      parser2.generateAll();

      final statAfter = modelFile.statSync();
      expect(statAfter.modified, equals(statBefore.modified));
    });

    test('9. HTTP HEAD operation semantics (HEAD vs GET)', () {
      final spec = {
        'components': {
          'schemas': {
            'PingResource': {
              'type': 'object',
              'properties': {
                'status': {'type': 'string'}
              }
            }
          }
        },
        'paths': {
          '/ping': {
            'get': {
              'tags': ['Ping'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/PingResource'}
                    }
                  }
                }
              }
            },
            'head': {
              'tags': ['Ping'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {r'$ref': '#/components/schemas/PingResource'}
                    }
                  }
                }
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_ping_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final content = apiFile.readAsStringSync();

      // GET returns ApiResponse<PingResource> with parsed JSON
      expect(content, contains('Future<ApiResponse<PingResource>> getPing('));
      expect(content, contains("await _dio.get<dynamic>("));
      expect(content,
          contains('PingResource.fromJson(resp.data as Map<String, dynamic>)'));

      // HEAD returns ApiResponse<void> with data = null and calls _dio.head
      expect(content, contains('Future<ApiResponse<void>> headPing('));
      expect(content, contains("await _dio.head<dynamic>("));
      expect(content, contains('final void data = null;'));
    });

    test('10. Enum query parameter wire formatting (.value)', () {
      final spec = {
        'components': {
          'schemas': {
            'SortDirection': {
              'type': 'string',
              'enum': ['ascending', 'descending']
            }
          }
        },
        'paths': {
          '/api/v1/queue': {
            'get': {
              'tags': ['Queue'],
              'parameters': [
                {
                  'name': 'sortDirection',
                  'in': 'query',
                  'required': false,
                  'schema': {r'$ref': '#/components/schemas/SortDirection'}
                }
              ],
              'responses': {
                '200': {'description': 'OK'}
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_queue_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final content = apiFile.readAsStringSync();

      // Parameter signature is typed SortDirection?
      expect(content, contains('SortDirection? sortDirection'));
      // Query serialization emits sortDirection.value (the OpenAPI wire value)
      expect(
          content,
          contains(
              "if (sortDirection != null) 'sortDirection': sortDirection.value,"));
    });

    test('11. Path parameter URL encoding with Uri.encodeComponent', () {
      final spec = {
        'paths': {
          '/api/v1/mediacover/artist/{artistId}/{filename}': {
            'get': {
              'tags': ['MediaCover'],
              'parameters': [
                {
                  'name': 'artistId',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'integer'}
                },
                {
                  'name': 'filename',
                  'in': 'path',
                  'required': true,
                  'schema': {'type': 'string'}
                }
              ],
              'responses': {
                '200': {'description': 'OK'}
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_media_cover_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final content = apiFile.readAsStringSync();

      // Path interpolation wraps path parameters in Uri.encodeComponent
      expect(
        content,
        contains(
            "'/api/v1/mediacover/artist/\${Uri.encodeComponent('\$artistId')}/\${Uri.encodeComponent('\$filename')}'"),
      );
    });

    test('12. Primitive List<T> response deserialization with casting', () {
      final spec = {
        'paths': {
          '/api/v1/strings': {
            'get': {
              'tags': ['Strings'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'type': 'string'}
                      }
                    }
                  }
                }
              }
            }
          },
          '/api/v1/ints': {
            'get': {
              'tags': ['Ints'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'type': 'integer'}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final stringsApiFile = File('${tempDir.path}/api/raw_strings_api.dart');
      expect(stringsApiFile.existsSync(), isTrue);
      final stringsContent = stringsApiFile.readAsStringSync();
      expect(stringsContent,
          contains('Future<ApiResponse<List<String>>> getStrings('));
      expect(
          stringsContent,
          contains(
              'final List<String> data = (resp.data as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];'));

      final intsApiFile = File('${tempDir.path}/api/raw_ints_api.dart');
      expect(intsApiFile.existsSync(), isTrue);
      final intsContent = intsApiFile.readAsStringSync();
      expect(intsContent, contains('Future<ApiResponse<List<int>>> getInts('));
      expect(
          intsContent,
          contains(
              'final List<int> data = (resp.data as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? <int>[];'));
    });

    test(
        '13. Enum wire value preservation with special characters and reserved keywords',
        () {
      final spec = {
        'components': {
          'schemas': {
            'SanitizationEnum': {
              'type': 'string',
              'enum': ['default', 'some-value', '123-number', 'UPPER_CASE']
            }
          }
        },
        'paths': {
          '/api/v1/filter': {
            'get': {
              'tags': ['Filter'],
              'parameters': [
                {
                  'name': 'filter',
                  'in': 'query',
                  'required': false,
                  'schema': {r'$ref': '#/components/schemas/SanitizationEnum'}
                }
              ],
              'responses': {
                '200': {'description': 'OK'}
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final enumFile = File('${tempDir.path}/models/sanitization_enum.dart');
      expect(enumFile.existsSync(), isTrue);
      final enumContent = enumFile.readAsStringSync();

      // Dart identifier sanitization vs OpenAPI wire value
      expect(enumContent, contains("@JsonValue('default')"));
      expect(enumContent, contains("defaultVal('default'),"));

      expect(enumContent, contains("@JsonValue('some-value')"));
      expect(enumContent, contains("someValue('some-value'),"));

      expect(enumContent, contains("@JsonValue('123-number')"));
      expect(enumContent, contains("val123Number('123-number'),"));

      expect(enumContent, contains("@JsonValue('UPPER_CASE')"));
      expect(enumContent, contains("uPPERCASE('UPPER_CASE'),"));

      expect(enumContent, contains('final String value;'));
      expect(enumContent, contains('const SanitizationEnum(this.value);'));

      final apiFile = File('${tempDir.path}/api/raw_filter_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final apiContent = apiFile.readAsStringSync();
      expect(
          apiContent, contains("if (filter != null) 'filter': filter.value,"));
    });

    test('14. Enum duplicate identifier collision disambiguation', () {
      final spec = {
        'components': {
          'schemas': {
            'CollisionEnum': {
              'type': 'string',
              'enum': ['foo_bar', 'foo-bar', 'FooBar']
            }
          }
        },
        'paths': {}
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final enumFile = File('${tempDir.path}/models/collision_enum.dart');
      expect(enumFile.existsSync(), isTrue);
      final enumContent = enumFile.readAsStringSync();

      expect(enumContent, contains("@JsonValue('foo_bar')"));
      expect(enumContent, contains("fooBar('foo_bar'),"));

      expect(enumContent, contains("@JsonValue('foo-bar')"));
      expect(enumContent, contains("fooBarAlt('foo-bar'),"));

      expect(enumContent, contains("@JsonValue('FooBar')"));
      expect(enumContent, contains("fooBarAltAlt('FooBar'),"));
    });

    test('15. Full primitive response lists (double, bool, String, int)', () {
      final spec = {
        'paths': {
          '/api/v1/doubles': {
            'get': {
              'tags': ['Primitives'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'type': 'number'}
                      }
                    }
                  }
                }
              }
            }
          },
          '/api/v1/bools': {
            'get': {
              'tags': ['Primitives'],
              'responses': {
                '200': {
                  'description': 'OK',
                  'content': {
                    'application/json': {
                      'schema': {
                        'type': 'array',
                        'items': {'type': 'boolean'}
                      }
                    }
                  }
                }
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_primitives_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final apiContent = apiFile.readAsStringSync();

      expect(apiContent,
          contains('Future<ApiResponse<List<double>>> getDoubles('));
      expect(
          apiContent,
          contains(
              'final List<double> data = (resp.data as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? <double>[];'));

      expect(apiContent, contains('Future<ApiResponse<List<bool>>> getBools('));
      expect(
          apiContent,
          contains(
              'final List<bool> data = (resp.data as List<dynamic>?)?.map((e) => e as bool).toList() ?? <bool>[];'));
    });

    test('16. Enum array query parameter wire serialization', () {
      final spec = {
        'components': {
          'schemas': {
            'Protocol': {
              'type': 'string',
              'enum': ['usenet', 'torrent']
            }
          }
        },
        'paths': {
          '/api/v1/search': {
            'get': {
              'tags': ['Search'],
              'parameters': [
                {
                  'name': 'protocols',
                  'in': 'query',
                  'required': false,
                  'schema': {
                    'type': 'array',
                    'items': {r'$ref': '#/components/schemas/Protocol'}
                  }
                }
              ],
              'responses': {
                '200': {'description': 'OK'}
              }
            }
          }
        }
      };

      final parser = LidarrOpenApiParser(spec, tempDir.path);
      parser.generateAll();

      final apiFile = File('${tempDir.path}/api/raw_search_api.dart');
      expect(apiFile.existsSync(), isTrue);
      final apiContent = apiFile.readAsStringSync();

      expect(apiContent, contains('List<Protocol>? protocols'));
      expect(
          apiContent,
          contains(
              "if (protocols != null) 'protocols': protocols.map((e) => e.value).toList(),"));
    });
  });
}
