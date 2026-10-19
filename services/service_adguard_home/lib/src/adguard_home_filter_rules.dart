import 'adguard_home_rules.dart';

/// How many rules [text] holds: its lines that are neither blank nor a
/// comment (`!` or `#`).
int adguardHomeRuleCount(String text) => <String>[
      for (final String line in text.split('\n'))
        if (_isRule(line)) line,
    ].length;

bool _isRule(String line) {
  final String rule = line.trim();
  return rule.isNotEmpty && !rule.startsWith('!') && !rule.startsWith('#');
}

/// The custom rules as the server takes them, one per entry, from the text
/// of the editor. Blank lines are dropped, as the web UI drops them; the
/// rest is kept as typed, comments included.
List<String> adguardHomeRulesFromText(String text) => <String>[
      for (final String line in text.replaceAll('\r', '').split('\n'))
        if (line.trim().isNotEmpty) line.trimRight(),
    ];

/// The custom rules as the editor shows them, one to a line.
String adguardHomeRulesToText(List<String> rules) => rules.join('\n');

/// The way a client named [name] appears in a rule's `client` modifier.
String _clientModifier(String name) =>
    "\$client='${adguardHomeEscapedClient(name)}'";

/// How many of [rules] are for the client called [name] alone, the kind
/// "for this client only" writes.
int adguardHomeRulesNamingClient(List<String> rules, String name) {
  final String modifier = _clientModifier(name);
  return rules.where((String rule) => rule.contains(modifier)).length;
}

/// [rules] with the client called [from] named [to] instead, so the rules
/// written for it still apply after a rename. The rest is left alone.
List<String> adguardHomeRenameClientInRules(
  List<String> rules,
  String from,
  String to,
) {
  final String old = _clientModifier(from);
  final String renamed = _clientModifier(to);
  return <String>[
    for (final String rule in rules) rule.replaceAll(old, renamed),
  ];
}
