import 'dart:io';

void main() {
  final dir = Directory('lib');
  int filesModified = 0;
  int constsRemoved = 0;

  final regexes = [
    RegExp(r'const\s+(Divider\([^)]*AppTheme\.[a-zA-Z0-9_]+)'),
    RegExp(r'const\s+(_Badge\([^)]*AppTheme\.[a-zA-Z0-9_]+)'),
    RegExp(r'const\s+(Border\([^)]*AppTheme\.[a-zA-Z0-9_]+)'),
  ];

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      for (final regex in regexes) {
        if (regex.hasMatch(content)) {
          final matches = regex.allMatches(content).length;
          constsRemoved += matches;
          content = content.replaceAllMapped(regex, (match) => match.group(1)!);
          modified = true;
        }
      }

      if (modified) {
        entity.writeAsStringSync(content);
        filesModified++;
      }
    }
  }

  print('Modified $filesModified files, removed $constsRemoved consts.');
}
