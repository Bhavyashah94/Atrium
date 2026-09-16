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
