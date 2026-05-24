import 'dart:io';

void main() {
  final file = File('lib/screens/homework_history_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
      'color: const Color(0xFFF0FDF4), // soft green', 
      'color: AppTheme.isDarkMode ? Colors.green.withOpacity(0.15) : const Color(0xFFF0FDF4), // soft green');
      
  content = content.replaceAll(
      'color: Color(0xFF166534)', 
      'color: AppTheme.isDarkMode ? Colors.green.shade200 : const Color(0xFF166534)');

  content = content.replaceAll(
      'color: const Color(0xFFEFF6FF), // soft light blue', 
      'color: AppTheme.isDarkMode ? Colors.blue.withOpacity(0.15) : const Color(0xFFEFF6FF), // soft light blue');

  content = content.replaceAll(
      'color: Color(0xFF1E40AF)', 
      'color: AppTheme.isDarkMode ? Colors.blue.shade200 : const Color(0xFF1E40AF)');

  content = content.replaceAll(
      'color: const Color(0xFFFAF5FF), // soft light purple', 
      'color: AppTheme.isDarkMode ? Colors.purple.withOpacity(0.15) : const Color(0xFFFAF5FF), // soft light purple');

  content = content.replaceAll(
      'color: Color(0xFF6B21A8)', 
      'color: AppTheme.isDarkMode ? Colors.purple.shade200 : const Color(0xFF6B21A8)');

  content = content.replaceAll(
      'color: const Color(0xFFFEF2F2), // soft light red background', 
      'color: AppTheme.isDarkMode ? Colors.red.withOpacity(0.15) : const Color(0xFFFEF2F2), // soft light red background');

  content = content.replaceAll(
      'color: Colors.red.shade900', 
      'color: AppTheme.isDarkMode ? Colors.red.shade200 : Colors.red.shade900');

  content = content.replaceAll(
      'color: const Color(0xFFFEF2F2),', 
      'color: AppTheme.isDarkMode ? Colors.transparent : const Color(0xFFFEF2F2),');
      
  file.writeAsStringSync(content);
  print('Fixed homework_history_screen pastel colors');
}
