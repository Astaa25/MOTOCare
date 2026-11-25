// Supabase Edge Function: maps-proxy
// Berfungsi sebagai proxy aman untuk Google Maps Platform Web Service (Places API New & Geocoding API).
// Mencegah kebocoran server API key ke aplikasi Flutter client.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GOOGLE_MAPS_SERVER_KEY = Deno.env.get("GOOGLE_MAPS_SERVER_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";

// Bounding box geografis Kota Lhokseumawe & Kabupaten Aceh Utara
// Lat: ~4.70 s/d 5.35, Lng: ~96.80 s/d 97.50
const BOUNDS = {
  minLat: 4.70,
  maxLat: 5.35,
  minLng: 96.80,
  maxLng: 97.50,
  centerLat: 5.1801,
  centerLng: 97.1396,
  radiusMeters: 50000, // 50 km mencakup Lhokseumawe & Aceh Utara
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Rate limiter per-user di memory Deno: maks 30 request / menit per pengguna
const userRateLimits = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(userId: string): boolean {
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 menit
  const maxRequests = 30; // 30 req/menit

  const current = userRateLimits.get(userId);
  if (!current || now > current.resetAt) {
    userRateLimits.set(userId, { count: 1, resetAt: now + windowMs });
    return true;
  }
  if (current.count >= maxRequests) {
    return false;
  }
  current.count++;
  return true;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Validasi Autentikasi Pengguna (Wajib Login)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Akses ditolak: Token autentikasi tidak ditemukan." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Akses ditolak: Pengguna tidak terverifikasi." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Proteksi Rate Limit per Pengguna (Maksimal 30 request / menit)
    if (!checkRateLimit(user.id)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Batas permintaan peta tercapai (maksimal 30 request/menit). Silakan tunggu sejenak sebelum mencoba lagi.",
        }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. Periksa Ketersediaan Kunci Server
    if (!GOOGLE_MAPS_SERVER_KEY) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Konfigurasi server belum lengkap: GOOGLE_MAPS_SERVER_KEY belum disetel di Supabase Secrets.",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const action = body.action;

    // 3. Router Action
    switch (action) {
      case "autocomplete": {
        // Places Autocomplete (New)
        const input = (body.input || "").trim();
        const sessionToken = body.sessionToken || "";

        if (!input || input.length < 2 || input.length > 100) {
          return new Response(
            JSON.stringify({ success: false, error: "Input pencarian harus antara 2 hingga 100 karakter." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const url = "https://places.googleapis.com/v1/places:autocomplete";
        const payload = {
          input,
          sessionToken,
          languageCode: "id",
          regionCode: "id",
          locationBias: {
            circle: {
              center: { latitude: BOUNDS.centerLat, longitude: BOUNDS.centerLng },
              radius: BOUNDS.radiusMeters,
            },
          },
        };

        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": GOOGLE_MAPS_SERVER_KEY,
          },
          body: JSON.stringify(payload),
        });

        const data = await res.json();
        // Batasi maksimal 5 saran hasil
        const suggestions = (data.suggestions || []).slice(0, 5).map((s: any) => ({
          placeId: s.placePrediction?.placeId,
          text: s.placePrediction?.text?.text,
          mainText: s.placePrediction?.structuredFormat?.mainText?.text,
          secondaryText: s.placePrediction?.structuredFormat?.secondaryText?.text,
        }));

        return new Response(
          JSON.stringify({ success: true, suggestions }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "place-details": {
        // Place Details (New) dengan FieldMask minimal
        const placeId = body.placeId;
        const sessionToken = body.sessionToken || "";

        if (!placeId) {
          return new Response(
            JSON.stringify({ success: false, error: "placeId wajib disertakan." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        let url = `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?languageCode=id`;
        if (sessionToken) {
          url += `&sessionToken=${encodeURIComponent(sessionToken)}`;
        }

        const res = await fetch(url, {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": GOOGLE_MAPS_SERVER_KEY,
            // FieldMask hemat kuota: hanya data esensial
            "X-Goog-FieldMask": "id,displayName,formattedAddress,location,rating,regularOpeningHours,nationalPhoneNumber",
          },
        });

        const data = await res.json();
        return new Response(
          JSON.stringify({
            success: true,
            place: {
              id: data.id,
              name: data.displayName?.text || "Bengkel Motor",
              formattedAddress: data.formattedAddress || "Belum tersedia",
              latitude: data.location?.latitude,
              longitude: data.location?.longitude,
              rating: data.rating ?? null,
              openNow: data.regularOpeningHours?.openNow ?? null,
              weekdayDescriptions: data.regularOpeningHours?.weekdayDescriptions || [],
              phoneNumber: data.nationalPhoneNumber || null,
            },
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "search-workshops": {
        // Text Search (New) untuk bengkel di Lhokseumawe & Aceh Utara
        const query = (body.query || "bengkel motor").trim();
        const url = "https://places.googleapis.com/v1/places:searchText";

        const payload = {
          textQuery: query,
          languageCode: "id",
          pageSize: 20, // Maks 20 hasil
          locationBias: {
            circle: {
              center: { latitude: BOUNDS.centerLat, longitude: BOUNDS.centerLng },
              radius: BOUNDS.radiusMeters,
            },
          },
        };

        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Goog-Api-Key": GOOGLE_MAPS_SERVER_KEY,
            "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.regularOpeningHours,places.nationalPhoneNumber",
          },
          body: JSON.stringify(payload),
        });

        const data = await res.json();
        const places = (data.places || []).map((p: any) => ({
          id: p.id,
          name: p.displayName?.text || "Bengkel Motor",
          formattedAddress: p.formattedAddress || "Belum tersedia",
          latitude: p.location?.latitude,
          longitude: p.location?.longitude,
          rating: p.rating ?? null,
          openNow: p.regularOpeningHours?.openNow ?? null,
          phoneNumber: p.nationalPhoneNumber || null,
        }));

        return new Response(
          JSON.stringify({ success: true, places }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "reverse-geocode": {
        // Reverse Geocoding
        const lat = parseFloat(body.latitude);
        const lng = parseFloat(body.longitude);

        if (isNaN(lat) || isNaN(lng)) {
          return new Response(
            JSON.stringify({ success: false, error: "Koordinat latitude dan longitude tidak valid." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Validasi batasan geografis wilayah layanan
        const inServiceArea =
          lat >= BOUNDS.minLat && lat <= BOUNDS.maxLat &&
          lng >= BOUNDS.minLng && lng <= BOUNDS.maxLng;

        const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lng}&language=id&key=${GOOGLE_MAPS_SERVER_KEY}`;
        const res = await fetch(url);
        const data = await res.json();

        if (data.status !== "OK" || !data.results || data.results.length === 0) {
          return new Response(
            JSON.stringify({
              success: false,
              inServiceArea,
              error: "Alamat untuk koordinat ini tidak ditemukan.",
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const topResult = data.results[0];
        let administrativeAreaLevel2 = ""; // Kota/Kabupaten
        let subdistrict = ""; // Kecamatan
        let village = ""; // Gampong/Kelurahan

        for (const comp of topResult.address_components || []) {
          if (comp.types.includes("administrative_area_level_2")) {
            administrativeAreaLevel2 = comp.long_name;
          }
          if (comp.types.includes("administrative_area_level_3")) {
            subdistrict = comp.long_name;
          }
          if (comp.types.includes("administrative_area_level_4") || comp.types.includes("sublocality")) {
            village = comp.long_name;
          }
        }

        return new Response(
          JSON.stringify({
            success: true,
            inServiceArea,
            placeId: topResult.place_id,
            formattedAddress: topResult.formatted_address,
            cityRegency: administrativeAreaLevel2,
            subdistrict,
            village,
          }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ success: false, error: `Action '${action}' tidak dikenali.` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error: any) {
    return new Response(
      JSON.stringify({ success: false, error: error.message || "Terjadi kesalahan internal proxy." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

