// Data models for Gluetun HTTP control server API responses.

class GluetunVpnStatus {
  const GluetunVpnStatus({required this.status});

  factory GluetunVpnStatus.fromJson(Map<String, dynamic> json) {
    return GluetunVpnStatus(
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  final String status;

  bool get isRunning => status.toLowerCase() == 'running';
  bool get isStopped => status.toLowerCase() == 'stopped';
}

class GluetunPublicIp {
  const GluetunPublicIp({
    required this.publicIp,
    this.region,
    this.country,
    this.city,
    this.organization,
  });

  factory GluetunPublicIp.fromJson(Map<String, dynamic> json) {
    return GluetunPublicIp(
      publicIp: json['public_ip']?.toString() ?? json['ip']?.toString() ?? '',
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      city: json['city']?.toString(),
      organization: json['organization']?.toString(),
    );
  }

  final String publicIp;
  final String? region;
  final String? country;
  final String? city;
  final String? organization;
}

class GluetunPortForward {
  const GluetunPortForward({
    required this.port,
    this.status,
  });

  factory GluetunPortForward.fromJson(Map<String, dynamic> json) {
    final dynamic portVal = json['port'] ?? json['portforwarded'] ?? 0;
    final int portNum = portVal is int
        ? portVal
        : int.tryParse(portVal?.toString() ?? '') ?? 0;
    return GluetunPortForward(
      port: portNum,
      status: json['status']?.toString(),
    );
  }

  final int port;
  final String? status;
}

class GluetunDnsStatus {
  const GluetunDnsStatus({required this.status});

  factory GluetunDnsStatus.fromJson(Map<String, dynamic> json) {
    return GluetunDnsStatus(
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  final String status;

  bool get isRunning => status.toLowerCase() == 'running';
}

class GluetunUpdaterStatus {
  const GluetunUpdaterStatus({required this.status});

  factory GluetunUpdaterStatus.fromJson(Map<String, dynamic> json) {
    return GluetunUpdaterStatus(
      status: json['status']?.toString() ?? 'idle',
    );
  }

  final String status;

  bool get isRunning => status.toLowerCase() == 'running';
}

class GluetunVpnSettings {
  const GluetunVpnSettings({
    this.providerName,
    this.type,
    this.country,
    this.city,
    this.serverName,
    this.portForwardingEnabled,
  });

  factory GluetunVpnSettings.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? provider =
        json['provider'] is Map ? Map<String, dynamic>.from(json['provider'] as Map) : null;
    final Map<String, dynamic>? serverSelection =
        provider != null && provider['server_selection'] is Map
            ? Map<String, dynamic>.from(provider['server_selection'] as Map)
            : null;
    final Map<String, dynamic>? portForwarding =
        provider != null && provider['port_forwarding'] is Map
            ? Map<String, dynamic>.from(provider['port_forwarding'] as Map)
            : null;

    final dynamic pfEnabled = portForwarding?['enabled'];

    return GluetunVpnSettings(
      providerName: provider?['name']?.toString() ?? json['provider']?.toString(),
      type: json['type']?.toString(),
      country: serverSelection?['country']?.toString() ??
          (serverSelection?['countries'] is List && (serverSelection!['countries'] as List).isNotEmpty
              ? (serverSelection['countries'] as List).first.toString()
              : null),
      city: serverSelection?['city']?.toString() ??
          (serverSelection?['cities'] is List && (serverSelection!['cities'] as List).isNotEmpty
              ? (serverSelection['cities'] as List).first.toString()
              : null),
      serverName: serverSelection?['server_name']?.toString() ??
          (serverSelection?['names'] is List && (serverSelection!['names'] as List).isNotEmpty
              ? (serverSelection['names'] as List).first.toString()
              : null),
      portForwardingEnabled: pfEnabled is bool
          ? pfEnabled
          : (pfEnabled?.toString().toLowerCase() == 'true'),
    );
  }

  final String? providerName;
  final String? type;
  final String? country;
  final String? city;
  final String? serverName;
  final bool? portForwardingEnabled;
}
