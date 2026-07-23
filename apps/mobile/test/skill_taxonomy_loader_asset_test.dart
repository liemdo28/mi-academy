import 'package:flutter_test/flutter_test.dart';
import 'package:mi_academy/services/skill_taxonomy_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads taxonomy and curriculum from bundled runtime assets', () async {
    final resolver = await loadActivityMappingResolver();
    final subjectIds =
        resolver.taxonomy.subjects.map((subject) => subject.subjectId).toSet();

    expect(subjectIds, containsAll(['letters', 'math', 'logic']));
    expect(resolver.curriculum.nodes, isNotEmpty);
  });
}
