import 'package:core_models/core_models.dart';

const testInstance = Instance(
  id: 'test-lidarr-instance',
  name: 'My Lidarr Test',
  kind: ServiceKind.lidarr,
  localUrl: 'http://localhost:8686',
  externalUrl: '',
  urlMode: UrlMode.auto,
  auth: InstanceAuthApiKey(apiKey: 'test-api-key'),
);
