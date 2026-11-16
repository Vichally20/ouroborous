// Checks that every image path referenced by the game exists, and reports
// progress on the art manifest.
//
//   dart tools/art/check_assets.dart   (plain `dart`, not `dart run`, so pubspec.lock is left alone)
//
// Exits with code 1 if code or data reference an image that is not on disk.
import 'dart:convert';
import 'dart:io';

final _assetPath = RegExp(r'''assets/images/[A-Za-z0-9_./-]+\.(?:png|jpe?g|webp)''');

void main() {
  final sources = <File>[
    ..._filesUnder('lib', '.dart'),
    ..._filesUnder('assets/data', '.json'),
    ..._filesUnder('assets/story', '.json'),
  ];

  // path -> files that reference it
  final refs = <String, Set<String>>{};
  for (final file in sources) {
    for (final match in _assetPath.allMatches(file.readAsStringSync())) {
      refs.putIfAbsent(match.group(0)!, () => {}).add(_rel(file.path));
    }
  }

  final missing = refs.keys.where((p) => !File(p).existsSync()).toList()..sort();
  print('Referenced images: ${refs.length}');
  if (missing.isEmpty) {
    print('All referenced images exist.');
  } else {
    print('\nMISSING (${missing.length}):');
    for (final path in missing) {
      print('  $path');
      for (final by in refs[path]!) {
        print('      <- $by');
      }
    }
  }

  final manifestFile = File('tools/art/manifest.json');
  if (manifestFile.existsSync()) {
    final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    final assets = (manifest['assets'] as List).cast<Map<String, dynamic>>();
    final byPriority = <String, List<int>>{}; // priority -> [done, total]
    for (final a in assets) {
      if (a['status'] == 'keep' || a['prompt'] == null) continue;
      final p = a['priority'] as String;
      final bucket = byPriority.putIfAbsent(p, () => [0, 0]);
      bucket[1]++;
      if (File(a['file'] as String).existsSync()) bucket[0]++;
    }
    print('\nArt manifest progress:');
    for (final p in (byPriority.keys.toList()..sort())) {
      print('  $p: ${byPriority[p]![0]}/${byPriority[p]![1]} delivered');
    }
  }

  if (missing.isNotEmpty) exitCode = 1;
}

Iterable<File> _filesUnder(String dir, String ext) {
  final d = Directory(dir);
  if (!d.existsSync()) return const [];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith(ext));
}

String _rel(String path) => path.replaceAll('\\', '/');
