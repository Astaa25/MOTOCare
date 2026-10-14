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
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Panduan langkah demi langkah mengganti oli mesin motor bebek dan matic dengan aman, memilih kunci pas yang tepat, dan memeriksa volume oli.',
      isActive: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Tutorial(
      id: 'tut-02',
      title: 'Memilih Kekentalan dan Jenis Oli yang Cocok untuk Motor Anda',
      topic: TutorialTopics.gantiOli,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Penjelasan kode SAE, standar JASO MA/MB, serta perbedaan oli mineral, semi sintetis, dan full sintetis untuk performa mesin maksimal.',
      isActive: true,
      createdAt: DateTime(2026, 10, 2),
    ),
    Tutorial(
      id: 'tut-03',
      title: 'Panduan Lengkap Mengganti Kampas Rem Cakram Depan',
      topic: TutorialTopics.rem,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Cara mendeteksi ketebalan kampas rem yang menipis, melepas kaliper rem cakram, memasang kampas baru, dan menguji pakemnya rem.',
      isActive: true,
      createdAt: DateTime(2026, 10, 3),
    ),
    Tutorial(
      id: 'tut-04',
      title: 'Cara Memeriksa dan Menambah Minyak Rem Motor',
      topic: TutorialTopics.rem,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Langkah memeriksa ketinggian minyak rem pada master rem kaca intip, memilih cairan DOT 3 atau DOT 4, dan mencegah gelembung udara masuk.',
      isActive: true,
      createdAt: DateTime(2026, 10, 4),
    ),
    Tutorial(
      id: 'tut-05',
      title: 'Tips Memeriksa Tekanan Angin dan Keausan Alur Ban',
      topic: TutorialTopics.ban,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Cara mengukur tekanan psi ban depan dan belakang sesuai standar pabrikan, membaca tanda TWI (Tread Wear Indicator), dan tips berkendara aman saat hujan.',
      isActive: true,
      createdAt: DateTime(2026, 10, 5),
    ),
    Tutorial(
      id: 'tut-06',
      title: 'Cara Merawat dan Menguji Tegangan Aki Motor',
      topic: TutorialTopics.aki,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Panduan merawat kutub aki dari jamur putih, mengukur tegangan aki dengan multimeter (12.4V - 12.8V), dan tanda-tanda aki perlu dicharge atau diganti.',
      isActive: true,
      createdAt: DateTime(2026, 10, 6),
    ),
    Tutorial(
      id: 'tut-07',
      title: 'Membersihkan dan Melumasi Rantai Roda Motor',
      topic: TutorialTopics.rantai,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Teknik mencuci kotoran rantai menggunakan cairan pembersih khusus, menyetel kelonggaran rantai (20-30 mm), dan mengaplikasikan chain lube.',
      isActive: true,
      createdAt: DateTime(2026, 10, 7),
    ),
    Tutorial(
      id: 'tut-08',
      title: 'Cara Melepas, Membersihkan, dan Menyetel Celah Busi',
      topic: TutorialTopics.busi,
      youtubeUrl: placeholderUrl,
      thumbnailUrl: null,
      description:
          'Cara membuka busi dengan kunci busi standar, membaca warna elektroda (indikasi pembakaran), membersihkan kerak karbon, dan menyetel gap busi 0.7-0.8 mm.',
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
