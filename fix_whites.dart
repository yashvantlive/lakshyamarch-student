import 'dart:io';

void main() {
  final dir = Directory('lib');
  int filesModified = 0;
  int whitesReplaced = 0;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;
      int localReplacements = 0;

      // Replace backgroundColor: Colors.white -> backgroundColor: AppTheme.surface
      // Replace color: Colors.white inside BoxDecoration, Container, Card, etc.
      // We can safely replace `color: Colors.white` if it's not followed by a `)` in a TextStyle?
      // Actually, standardizing on `AppTheme.surface` for backgrounds:
      
      final regex1 = RegExp(r'backgroundColor:\s*Colors\.white');
      if (regex1.hasMatch(content)) {
        localReplacements += regex1.allMatches(content).length;
        content = content.replaceAll(regex1, 'backgroundColor: AppTheme.surface');
        modified = true;
      }

      // Safe replace: "color: Colors.white," -> "color: AppTheme.surface,"
      // This might hit Icons. But wait, icons in dark mode on a dark surface should be white?
      // No, icons usually match the text color (textBase).
      
      // Let's specifically target BoxDecoration and Container backgrounds.
      // A common pattern is `decoration: BoxDecoration(\s*color: Colors.white`
      final regex2 = RegExp(r'decoration:\s*BoxDecoration\(\s*color:\s*Colors\.white');
      if (regex2.hasMatch(content)) {
        localReplacements += regex2.allMatches(content).length;
        content = content.replaceAll(regex2, 'decoration: BoxDecoration(\ncolor: AppTheme.surface');
        modified = true;
      }

      // Also Card(color: Colors.white
      final regex3 = RegExp(r'Card\(\s*color:\s*Colors\.white');
      if (regex3.hasMatch(content)) {
        localReplacements += regex3.allMatches(content).length;
        content = content.replaceAll(regex3, 'Card(color: AppTheme.surface');
        modified = true;
      }

      // Standalone `color: Colors.white` that is not in TextStyle or Icon? Too risky with regex.
      // Let's replace ANY `color: Colors.white` that is immediately preceded by `BoxDecoration(` or `Container(`
      // (with optional whitespace/newlines)
      
      if (modified) {
        // Ensure AppTheme is imported
        if (!content.contains("import '../theme/app_theme.dart';") && 
            !content.contains("import '../../theme/app_theme.dart';") &&
            !content.contains("import 'package:")) {
            // we'll just let the compiler complain if import is missing and fix it, or we can heuristically add it.
        }
        
        entity.writeAsStringSync(content);
        filesModified++;
        whitesReplaced += localReplacements;
      }
    }
  }

  print('Modified $filesModified files, replaced $whitesReplaced Colors.whites.');
}
