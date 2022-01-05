import 'package:expect_error/expect_error.dart';
import 'package:expect_error_plus/src/expect_error_annotation.dart';
import 'dart:io';

import 'package:expect_error_plus/src/lints.dart';

extension ExpectHelperX on Library {
  Code withCodeFrom(String fileName) {
    final content = _getFileContent(fileName);

    final expectRegex = RegExp('@$ExpectError' r'\(\[(.*)\]\)');

    final code = content.replaceAllMapped(expectRegex, (match) {
      final errorsRaw = match.group(1);

      if (errorsRaw == null) {
        return match.input;
      }

      final errors = errorsRaw.split(', ');

      return _lintsToExpect(errors);
    });

    return withCode(code);
  }
}

/// gets the file's content from the given [path].
String _getFileContent(String fileName) {
  var path = fileName;

  if (!path.endsWith('.dart')) {
    path = '$fileName.dart';
  }

  final file = File(path);

  if (!file.existsSync()) {
    throw Exception('File not found: $path');
  }

  final content = file.readAsStringSync();

  return content;
}

String _lintsToExpect(Iterable<String> allErrors) {
  final errors = allErrors.toSet();

  final expects = <String>[];

  for (final lint in Lints.values) {
    if (errors.remove('$lint')) {
      expects.add(lint.asExpect());
    }

    if (errors.isEmpty) {
      break;
    }
  }

  if (errors.isNotEmpty) {
    throw Exception('Could not find ${errors.join(', ')} in lints');
  }

  return '// expect-error: ${expects.join(', ')}';
}
