import '../domain/tutorial.dart';
import '../domain/tutorial_repository.dart';

/// Implementasi mock repositori tutorial dengan 8 data seed demo sesuai PRD Bagian 5.5
class MockTutorialRepository implements TutorialRepository {
  static const String placeholderUrl =
      'https://www.youtube.com/watch?v=GANTI_DENGAN_ID_VALID';

  final List<Tutorial> _tutorials = <Tutorial>[
    Tutorial(
      id: 'tut-01',
      title: 'Cara Mengganti Oli Mesin Motor Sendiri di Rumah',
      topic: TutorialTopics.gantiOli,
      youtubeUrl: 'https://www.youtube.com/watch?v=2Ax9qDmNJ-c',
      thumbnailUrl: 'https://img.youtube.com/vi/2Ax9qDmNJ-c/hqdefault.jpg',
      description:
          'Panduan langkah demi langkah menguras dan mengisi oli mesin motor dengan aman, memilih kunci pas yang tepat, dan memeriksa takaran volume oli.',
      isActive: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Tutorial(
      id: 'tut-02',
      title: 'Memilih Kekentalan dan Jenis Oli yang Cocok untuk Motor Anda',
      topic: TutorialTopics.gantiOli,
      youtubeUrl: 'https://www.youtube.com/watch?v=umf0szoTZ6E',
      thumbnailUrl: 'https://img.youtube.com/vi/umf0szoTZ6E/hqdefault.jpg',
      description:
          '10 hal penting seputar oli mesin motor: penjelasan kode SAE, standar JASO MA/MB, serta perbedaan oli mineral, semi sintetis, dan full sintetis untuk performa mesin maksimal.',
      isActive: true,
      createdAt: DateTime(2026, 10, 2),
    ),
    Tutorial(
      id: 'tut-03',
      title: 'Panduan Lengkap Mengganti Kampas Rem Cakram Depan',
      topic: TutorialTopics.rem,
      youtubeUrl: 'https://www.youtube.com/watch?v=RfXUKgl4L5k',
      thumbnailUrl: 'https://img.youtube.com/vi/RfXUKgl4L5k/hqdefault.jpg',
      description:
          'Trik cepat dan aman mengganti kampas rem cakram motor tanpa perlu melepas roda atau ban, mendeteksi ketebalan kampas, dan menguji pakemnya rem.',
      isActive: true,
      createdAt: DateTime(2026, 10, 3),
    ),
    Tutorial(
      id: 'tut-04',
      title: 'Cara Memeriksa dan Menambah Minyak Rem Motor',
      topic: TutorialTopics.rem,
      youtubeUrl: 'https://www.youtube.com/watch?v=Ef7pHuP0VqA',
      thumbnailUrl: 'https://img.youtube.com/vi/Ef7pHuP0VqA/hqdefault.jpg',
      description:
          'Langkah memeriksa kejernihan dan ketinggian minyak rem pada master rem kaca intip, memilih cairan DOT 3 atau DOT 4, dan mencegah gelembung udara masuk.',
      isActive: true,
      createdAt: DateTime(2026, 10, 4),
    ),
    Tutorial(
      id: 'tut-05',
      title: 'Tips Memeriksa Tekanan Angin dan Keausan Alur Ban',
      topic: TutorialTopics.ban,
      youtubeUrl: 'https://www.youtube.com/watch?v=464DBCyxAjI',
      thumbnailUrl: 'https://img.youtube.com/vi/464DBCyxAjI/hqdefault.jpg',
      description:
          'Cara simpel menjaga ban motor lebih awet, mengukur tekanan psi ban depan dan belakang sesuai standar pabrikan, serta membaca tanda TWI (Tread Wear Indicator).',
      isActive: true,
      createdAt: DateTime(2026, 10, 5),
    ),
    Tutorial(
      id: 'tut-06',
      title: 'Cara Merawat dan Menguji Tegangan Aki Motor',
      topic: TutorialTopics.aki,
      youtubeUrl: 'https://www.youtube.com/watch?v=YB_deLSgHPU',
      thumbnailUrl: 'https://img.youtube.com/vi/YB_deLSgHPU/hqdefault.jpg',
      description:
          'Panduan merawat kutub aki dari jamur putih, mengukur tegangan aki dengan multimeter/voltmeter (12.4V - 12.8V), dan tanda-tanda aki perlu dicharge atau diganti.',
      isActive: true,
      createdAt: DateTime(2026, 10, 6),
    ),
    Tutorial(
      id: 'tut-07',
      title: 'Membersihkan dan Melumasi Rantai Roda Motor',
      topic: TutorialTopics.rantai,
      youtubeUrl: 'https://www.youtube.com/watch?v=5wsjfNE1IwM',
      thumbnailUrl: 'https://img.youtube.com/vi/5wsjfNE1IwM/hqdefault.jpg',
      description:
          'Teknik menyetel kelonggaran rantai roda motor (jarak bebas 20-30 mm), menyelaraskan posisi ban belakang di swing arm, dan tips pelumasan rantai.',
      isActive: true,
      createdAt: DateTime(2026, 10, 7),
    ),
    Tutorial(
      id: 'tut-08',
      title: 'Cara Melepas, Membersihkan, dan Menyetel Celah Busi',
      topic: TutorialTopics.busi,
      youtubeUrl: 'https://www.youtube.com/watch?v=eRUOo6i4uRE',
      thumbnailUrl: 'https://img.youtube.com/vi/eRUOo6i4uRE/hqdefault.jpg',
      description:
          'Cara membuka busi dengan kunci busi standar, membaca warna elektroda (indikasi pembakaran mesin), membersihkan kerak karbon, dan menyetel celah elektroda busi.',
      isActive: true,
      createdAt: DateTime(2026, 10, 8),
    ),
  ];

  @override
  Future<List<Tutorial>> getTutorials({
    String? topic,
    String? query,
  }) async {
    // Simulasi latensi ringan
    await Future<void>.delayed(const Duration(milliseconds: 60));

    var results = _tutorials.where((t) => t.isActive).toList();

    // Filter topik bila bukan 'Semua' dan tidak null/kosong
    if (topic != null &&
        topic.isNotEmpty &&
        topic.toLowerCase() != TutorialTopics.all.toLowerCase()) {
      results = results
          .where((t) => t.topic.toLowerCase() == topic.toLowerCase())
          .toList();
    }

    // Filter query pencarian (pada judul, deskripsi, atau topik)
    if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim().toLowerCase();
      results = results.where((t) {
        final titleMatch = t.title.toLowerCase().contains(cleanQuery);
        final descMatch =
            t.description?.toLowerCase().contains(cleanQuery) ?? false;
        final topicMatch = t.topic.toLowerCase().contains(cleanQuery);
        return titleMatch || descMatch || topicMatch;
      }).toList();
    }

    return results;
  }

  @override
  Future<Tutorial?> getTutorialById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    try {
      return _tutorials.firstWhere((t) => t.id == id && t.isActive);
    } catch (_) {
      return null;
    }
  }
}
