import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/features/tutorials/data/mock_tutorial_repository.dart';
import 'package:motocare/features/tutorials/domain/tutorial.dart';

void main() {
  group('Tutorial Model and Regex Unit Tests (M6)', () {
    test('Validasi regex URL YouTube sesuai PRD 5.1', () {
      expect(
        Tutorial.isValidYoutubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        Tutorial.isValidYoutubeUrl('https://youtu.be/dQw4w9WgXcQ'),
        isTrue,
      );
      expect(
        Tutorial.isValidYoutubeUrl(MockTutorialRepository.placeholderUrl),
        isTrue,
      );
      expect(
        Tutorial.isValidYoutubeUrl('http://invalidsite.com/watch?v=123'),
        isFalse,
      );
      expect(
        Tutorial.isValidYoutubeUrl('ftp://youtube.com/video'),
        isFalse,
      );
    });

    test('Serialisasi Tutorial toJson dan fromJson bekerja konsisten', () {
      final tutorial = Tutorial(
        id: 'tut-test',
        title: 'Tutorial Uji Coba',
        topic: TutorialTopics.gantiOli,
        youtubeUrl: MockTutorialRepository.placeholderUrl,
        thumbnailUrl: 'https://example.com/thumb.jpg',
        description: 'Deskripsi lengkap tutorial uji coba',
        isActive: true,
        createdAt: DateTime(2026, 10, 14, 12, 0),
      );

      final json = tutorial.toJson();
      final parsed = Tutorial.fromJson(json);

      expect(parsed.id, equals(tutorial.id));
      expect(parsed.title, equals(tutorial.title));
      expect(parsed.topic, equals(tutorial.topic));
      expect(parsed.youtubeUrl, equals(tutorial.youtubeUrl));
      expect(parsed.thumbnailUrl, equals(tutorial.thumbnailUrl));
      expect(parsed.description, equals(tutorial.description));
      expect(parsed.isActive, isTrue);
    });
  });

  group('MockTutorialRepository Unit Tests (M6)', () {
    late MockTutorialRepository repository;

    setUp(() {
      repository = MockTutorialRepository();
    });

    test('Memuat minimal 8 tutorial aktif sesuai PRD 5.5', () async {
      final tutorials = await repository.getTutorials();
      expect(tutorials.length, greaterThanOrEqualTo(8));
      for (final tut in tutorials) {
        expect(tut.isActive, isTrue);
        expect(Tutorial.isValidYoutubeUrl(tut.youtubeUrl), isTrue);
      }
    });

    test('Filter topik mengembalikan hanya tutorial yang sesuai', () async {
      final oliTutorials = await repository.getTutorials(
        topic: TutorialTopics.gantiOli,
      );
      expect(oliTutorials, isNotEmpty);
      for (final tut in oliTutorials) {
        expect(tut.topic, equals(TutorialTopics.gantiOli));
      }

      final remTutorials = await repository.getTutorials(
        topic: TutorialTopics.rem,
      );
      expect(remTutorials, isNotEmpty);
      for (final tut in remTutorials) {
        expect(tut.topic, equals(TutorialTopics.rem));
      }
    });

    test('Pencarian query cocok pada judul, topik, atau deskripsi', () async {
      final results = await repository.getTutorials(query: 'busi');
      expect(results, isNotEmpty);
      expect(results.first.title.toLowerCase(), contains('busi'));

      final nonExistent = await repository.getTutorials(
        query: 'xyztidakadasamasekali123',
      );
      expect(nonExistent, isEmpty);
    });

    test('getTutorialById mengembalikan tutorial yang benar atau null', () async {
      final tutorial = await repository.getTutorialById('tut-01');
      expect(tutorial, isNotNull);
      expect(tutorial!.id, equals('tut-01'));

      final missing = await repository.getTutorialById('tut-999');
      expect(missing, isNull);
    });
  });
}
