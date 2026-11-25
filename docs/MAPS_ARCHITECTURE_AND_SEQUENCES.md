# Dokumentasi Teknis Arsitektur & Diagram Sequence Integrasi Google Maps Platform — MotoCare

Dokumen ini memuat dokumentasi arsitektur sistem menyeluruh, diagram alur sekuensial (Sequence Diagrams), skema relasi data (ERD), dan panduan deployment Supabase Edge Function untuk integrasi Google Maps Platform pada aplikasi MotoCare (Wilayah Operasional: Kota Lhokseumawe & Kab. Aceh Utara).

---

## 1. Diagram Arsitektur Integrasi Sistem

Arsitektur MotoCare mengedepankan **Keamanan Kunci (Zero-Leakage)**, **Kontrol Biaya (Cost Guard)**, dan **Ketangguhan Offline (Offline-Resilience)**:

```mermaid
flowchart TD
    subgraph ClientLayer["Klien Flutter Android (MotoCare)"]
        UI["Antarmuka Pengguna (Figma 49 Layar)"]
        UserLoc["UserLocationService<br>(Geolocator & Permission Guard)"]
        PlacesSvc["MapsPlacesService<br>(Debounce 300ms + UUID Session Token)"]
        CostCtrl["MapsCostController<br>(MemoryCache 10m TTL + Bounds Guard)"]
        HybridRepo["HybridWorkshopRepository<br>(Google Places + Supabase DB)"]
        NativeSDK["Google Maps SDK for Android<br>(API Key terikat SHA-1 & Package Name)"]
    end

    subgraph SecurityBoundary["Lapisan Keamanan & Proxy"]
        EdgeFunc["Supabase Edge Function: maps-proxy<br>(Deno / TypeScript)"]
        RateLimiter["Rate Limiter In-Memory<br>(Maks. 30 Request / Menit / User)"]
        AuthCheck["Supabase JWT Auth Validator<br>(Tolak pengguna anonim/tanpa login)"]
        BoundsValidator["Server-side Bounding Box Guard<br>(Lat 4.70-5.35, Lng 96.80-97.50)"]
    end

    subgraph GoogleCloud["Google Maps Platform API"]
        GPlaces["Places API (New)<br>(Autocomplete & Details with FieldMask)"]
        GGeocode["Geocoding API<br>(Reverse Geocode to Address & Regency)"]
        GIntent["Google Maps Android Native App<br>(Intent: google.navigation: & geo:)"]
    end

    subgraph SupabaseCloud["Supabase Managed Cloud (acdfesajqkwbsczdiedt)"]
        PostgresDB[("PostgreSQL Database Live<br>(profiles, vehicles, workshops, assistance_requests, etc.)")]
        Vault["Supabase Secrets Vault<br>(GOOGLE_MAPS_SERVER_KEY)"]
    end

    UI --> UserLoc
    UI --> PlacesSvc
    PlacesSvc --> CostCtrl
    PlacesSvc --> EdgeFunc
    UI --> HybridRepo
    HybridRepo --> PostgresDB
    HybridRepo --> PlacesSvc
    UI --> NativeSDK
    UI -.->|Buka Rute Luar| GIntent

    EdgeFunc --> AuthCheck
    AuthCheck --> RateLimiter
    RateLimiter --> BoundsValidator
    BoundsValidator --> Vault
    Vault --> GPlaces
    Vault --> GGeocode
```

---

## 2. Diagram Sequence Alur Utama

### 2.1 Sequence Diagram 1: Geolokasi Pengguna & Autocomplete Alamat (Figma 02.01, 03.01, 03.02)

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna (Pelanggan)
    participant UI as LocationPickerScreen / Home
    participant LocSvc as UserLocationService
    participant PlacesSvc as MapsPlacesService
    participant Cache as MapsMemoryCache
    participant Proxy as Edge Function (maps-proxy)
    participant Google as Google Places / Geocoding API

    User->>UI: Ketuk "Gunakan Lokasi Saya"
    UI->>LocSvc: getCurrentLocation()
    LocSvc->>LocSvc: Cek Izin GPS Kontekstual
    alt Izin Ditolak
        LocSvc-->>UI: PermissionDeniedException
        UI->>User: Tampilkan Dialog Figma 09.06 (Opsi Input Manual)
    else Izin Diberikan
        LocSvc-->>UI: Position(Lat: 5.1801, Lng: 97.1402)
        UI->>PlacesSvc: reverseGeocode(5.1801, 97.1402)
        PlacesSvc->>Proxy: invoke('maps-proxy', action: 'reverse-geocode')
        Proxy->>Google: Geocoding API (result_type=street_address)
        Google-->>Proxy: Format Alamat, Kota Lhokseumawe
        Proxy-->>PlacesSvc: Alamat Teks & Kota/Kabupaten
        PlacesSvc-->>UI: UserLocationState(Kota Lhokseumawe, Dalam Wilayah)
        UI->>User: Tampilkan Header Lokasi & Aktifkan Tombol Lanjut
    end

    opt Pengguna Mengetik Alamat Manual (Autocomplete)
        User->>UI: Ketik "Jl. Merdeka" (keystroke)
        UI->>PlacesSvc: searchPlaces("Jl. Merdeka")
        PlacesSvc->>PlacesSvc: Debounce 300 ms & Ambil Session Token UUID v4
        PlacesSvc->>Cache: get("Jl. Merdeka")
        alt Cache Miss
            PlacesSvc->>Proxy: invoke('maps-proxy', action: 'autocomplete', sessionToken)
            Proxy->>Google: Places Autocomplete (locationBias Lhokseumawe)
            Google-->>Proxy: List Place Suggestions (Maks. 5)
            Proxy-->>PlacesSvc: List<PlaceSuggestion>
            PlacesSvc->>Cache: set("Jl. Merdeka", list, TTL 10m)
        else Cache Hit
            Cache-->>PlacesSvc: List<PlaceSuggestion> dari RAM
        end
        PlacesSvc-->>UI: Tampilkan Dropdown Rekomendasi Tempat
        User->>UI: Pilih Tempat "Jl. Merdeka Barat No. 88"
        UI->>PlacesSvc: getPlaceDetails(placeId)
        PlacesSvc->>Proxy: invoke('maps-proxy', action: 'place-details')
        Proxy->>Google: Place Details (Fields: id, location, formattedAddress)
        Google-->>Proxy: Coordinates (Lat, Lng)
        Proxy-->>PlacesSvc: PlaceDetailResult
        PlacesSvc->>PlacesSvc: consumeSessionToken() [Reset Token]
        PlacesSvc-->>UI: Update MiniMapPickerPreview & Koordinat
    end
```

---

### 2.2 Sequence Diagram 2: Pencarian & Detail Bengkel Hybrid (Figma 05.01, 05.02)

```mermaid
sequenceDiagram
    autonumber
    actor User as Pengguna
    participant UI as WorkshopsScreen (Figma 05.01)
    participant Repo as HybridWorkshopRepository
    participant DB as Supabase PostgreSQL (workshops)
    participant Places as MapsPlacesService
    participant Proxy as Supabase Edge Function
    participant GNav as Google Maps Native App (Intent)

    User->>UI: Buka Tab "Katalog Bengkel" (Filter: Kota Lhokseumawe)
    UI->>Repo: getWorkshops(cityOrRegency: "Kota Lhokseumawe")
    
    par Ambil Bengkel Terverifikasi Lokal
        Repo->>DB: select * from workshops where service_region = 'Kota Lhokseumawe'
        DB-->>Repo: List Bengkel Mitra Resmi MotoCare
    and Ambil Tempat Bengkel Sekitar via Google Places
        Repo->>Places: searchWorkshops("Bengkel Motor", lat, lng)
        Places->>Proxy: invoke('maps-proxy', action: 'places-search')
        Proxy-->>Places: List Tempat Bengkel Google Maps
        Places-->>Repo: List Workshop (source: "Google Maps Platform")
    end

    Repo->>Repo: Gabungkan Hasil & Validasi Bounding Box (Lhokseumawe & Aceh Utara)
    Repo-->>UI: List<Workshop> Gabungan
    UI->>User: Tampilkan Daftar Bengkel (Lencana Demo / Sumber Data: Google Maps)

    User->>UI: Ketuk salah satu Bengkel -> Buka WorkshopDetailScreen (Figma 05.02)
    UI->>User: Tampilkan Info Jam Buka, Rating ⭐, Alamat, dan Attribution Card
    User->>UI: Ketuk "Buka Rute di Google Maps"
    UI->>GNav: launchUrl("google.navigation:q=5.182,97.142" / "geo:5.182,97.142")
    alt Aplikasi Google Maps Terpasang
        GNav->>User: Buka Aplikasi Navigasi Google Maps Asli
    else Aplikasi Tidak Ada
        UI->>User: Buka Fallback Web URL Browser (https://www.google.com/maps/dir/...)
    end
```

---

### 2.3 Sequence Diagram 3: Pembuatan Permintaan Bantuan & Pelacakan Montir Simulasi (Figma 03.04, 03.06–03.11, 07.02)

```mermaid
sequenceDiagram
    autonumber
    actor Cust as Pengguna (Pelanggan)
    participant Form as CreateHelpRequestScreen
    participant ActionNotif as HelpRequestActionNotifier
    participant DB as Supabase DB (assistance_requests)
    actor Mech as Montir / Mekanik
    participant MechUI as MechanicHomeScreen (Figma 07.02)
    participant TrackUI as HelpRequestDetailScreen (Figma 03.08-03.10)
    participant SimCard as SimulatedMechanicTrackingCard

    Cust->>Form: Isi Form & Ketuk "Lanjutkan"
    Form->>Cust: Tampilkan Modal Bottom Sheet "Tinjau Permintaan" (Figma 03.04)
    Note over Form: Tampilkan Mini Map Jemput, Motor, Kendala, & Hitung Mundur 15 Menit
    Cust->>Form: Ketuk "Konfirmasi & Panggil Montir"
    
    Form->>ActionNotif: createRequest(ServiceRequest with idempotencyKey: UUIDv4)
    ActionNotif->>ActionNotif: Cek Cache Idempotensi
    ActionNotif->>DB: insert into assistance_requests (status: 'MENUNGGU', idempotency_key)
    DB-->>ActionNotif: Created ServiceRequest (ID: req-01)
    ActionNotif-->>Form: Sukses
    Form->>TrackUI: Navigasi ke Detail Layar Pelacakan (Status: pending)

    Note over MechUI: Privasi Terlindungi (Figma 07.02)
    MechUI->>DB: Watch active requests
    DB-->>MechUI: Pesanan Baru (req-01, status: 'MENUNGGU')
    MechUI->>Mech: Tampilkan Kartu Pesanan Baru (Nomor Telepon & Rute DISEMBUNYIKAN)
    Mech->>MechUI: Ketuk "Terima Pesanan"
    MechUI->>DB: update assistance_requests set status = 'DITERIMA', mechanic_id = ...
    Note over MechUI: Nomor Telepon & Tombol "Buka Rute di Google Maps" Aktif Pasca Diterima

    DB-->>TrackUI: Status Berubah menjadi 'onTheWay'
    TrackUI->>SimCard: Inisialisasi Pelacakan Simulasi
    Note over SimCard: Tampilkan Banner Wajib: "Simulasi dipercepat - bukan GPS nyata"
    
    loop Pergerakan Montir Setiap 4 Detik
        SimCard->>SimCard: Kurangi Jarak Tersisa (1.5 km -> 0.9 km -> 0.3 km)
        SimCard->>SimCard: Perbarui ETA (5 mnt -> 3 mnt -> 1 mnt)
        SimCard->>TrackUI: Render Rute & Marker Montir Bergerak
    end

    Mech->>MechUI: Tekan "Tiba di Lokasi & Mulai Servis"
    MechUI->>DB: update assistance_requests set status = 'SEDANG_DITANGANI'
    DB-->>TrackUI: Status Berubah menjadi 'inProgress'
    TrackUI->>TrackUI: Tampilkan Banner Figma 03.10 "Montir Sudah Tiba di Lokasi"
    SimCard->>SimCard: Update Status: "0 km (Tiba) - Sudah Tiba"

    Mech->>MechUI: Tekan "Selesaikan Servis"
    MechUI->>DB: update assistance_requests set status = 'SELESAI'
    DB-->>TrackUI: Status Berubah menjadi 'completed'
    TrackUI->>TrackUI: Tampilkan Form Rating ⭐ & Tombol Figma 03.11 "Kembali ke Aktivitas"
    Cust->>TrackUI: Ketuk "Kembali ke Aktivitas" -> Navigasi ke Riwayat /help
```

---

## 3. Entity-Relationship Diagram (ERD) PostgreSQL Supabase Live

Struktur tabel di bawah ini sesuai dengan database live Supabase proyek `acdfesajqkwbsczdiedt`:

```mermaid
erDiagram
    PROFILES ||--o{ VEHICLES : "owns"
    PROFILES ||--o{ MECHANICS : "has profile"
    PROFILES ||--o{ ASSISTANCE_REQUESTS : "requests"
    PROFILES ||--o{ NOTIFICATIONS : "receives"
    PROFILES ||--o{ REVIEWS : "writes"

    VEHICLES ||--o{ ASSISTANCE_REQUESTS : "subject of"
    VEHICLES ||--o{ SERVICE_HISTORIES : "has history"
    VEHICLES ||--o{ SERVICE_REMINDERS : "has reminders"

    MECHANICS ||--o{ ASSISTANCE_REQUESTS : "assigned to"
    MECHANICS ||--o{ REVIEWS : "reviewed in"

    WORKSHOPS ||--o{ SERVICE_HISTORIES : "service venue"
    WORKSHOPS ||--o{ REVIEWS : "reviewed in"

    PROFILES {
        uuid id PK
        text full_name
        text email UK
        text phone_number
        user_role role "owner | mechanic | admin"
        text avatar_url
        boolean is_simulation
        timestamptz created_at
        timestamptz updated_at
    }

    VEHICLES {
        uuid id PK
        uuid owner_id FK
        text brand
        text model
        integer production_year
        text license_plate
        integer current_km
        boolean is_simulation
        timestamptz created_at
        timestamptz updated_at
    }

    MECHANICS {
        uuid id PK
        uuid user_id FK
        text full_name
        text phone_number
        text_array specialties
        text service_area
        float8 latitude
        float8 longitude
        boolean is_available
        boolean is_verified
        boolean is_simulation
        numeric rating_avg
        timestamptz created_at
    }

    WORKSHOPS {
        uuid id PK
        text google_place_id UK
        text name
        text address
        text service_region
        float8 latitude
        float8 longitude
        text phone_number
        text operating_hours
        text_array services_offered
        numeric google_rating
        boolean is_verified_partner
        timestamptz created_at
    }

    ASSISTANCE_REQUESTS {
        uuid id PK
        uuid user_id FK
        uuid vehicle_id FK
        uuid mechanic_id FK
        text issue_category
        text issue_description
        float8 latitude
        float8 longitude
        text manual_address
        request_status status "MENUNGGU | DITERIMA | SEDANG_DITANGANI | SELESAI | DIBATALKAN | DITOLAK"
        text idempotency_key UK
        numeric estimated_cost
        numeric final_cost
        boolean is_simulation
        timestamptz requested_at
        timestamptz accepted_at
        timestamptz completed_at
    }

    SERVICE_HISTORIES {
        uuid id PK
        uuid vehicle_id FK
        uuid workshop_id FK
        text custom_workshop_name
        date service_date
        integer km_at_service
        text service_type
        text_array replaced_parts
        text work_description
        numeric labor_cost
        numeric parts_cost
        numeric total_cost
        boolean is_simulation
        timestamptz created_at
    }

    SERVICE_REMINDERS {
        uuid id PK
        uuid vehicle_id FK
        text service_type
        date target_date
        integer target_km
        reminder_status status "AKTIF | SELESAI | DIABAIKAN"
        text notes
        timestamptz created_at
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        uuid reminder_id FK
        uuid request_id FK
        text title
        text message
        text notification_type
        boolean is_read
        timestamptz created_at
    }

    TUTORIALS {
        uuid id PK
        text title
        text category "mesin | ban | rem | rantai | umum"
        text_array keywords
        text description
        text youtube_url
        text youtube_video_id
        boolean has_safety_warning
        text safety_warning_text
        timestamptz created_at
    }

    REVIEWS {
        uuid id PK
        uuid user_id FK
        uuid request_id FK
        uuid mechanic_id FK
        uuid workshop_id FK
        integer rating "1..5"
        text comment
        boolean is_simulation
        timestamptz created_at
    }
```

---

## 4. Panduan Deployment Supabase Edge Function & Secrets

Edge Function `maps-proxy` bertindak sebagai reverse proxy yang memproteksi Google Maps API Server Key agar tidak terpapar ke klien.

### 4.1 Langkah Konfigurasi Rahasia (Supabase CLI)
Pastikan telah login ke akun Supabase Anda:
```bash
supabase login
supabase link --project-ref acdfesajqkwbsczdiedt
```

Simpan server API key ke dalam Supabase Vault:
```bash
supabase secrets set GOOGLE_MAPS_SERVER_KEY=AIzaSy...YourServerKeyHere
```

### 4.2 Langkah Deploy Edge Function
Deploy fungsi proxy:
```bash
supabase functions deploy maps-proxy --no-verify-jwt=false
```

*Catatan Keamanan*: `--no-verify-jwt=false` memastikan bahwa request tanpa token login Supabase yang sah akan langsung ditolak oleh Supabase Gateway sebelum memicu pemakaian kuota API Google.

