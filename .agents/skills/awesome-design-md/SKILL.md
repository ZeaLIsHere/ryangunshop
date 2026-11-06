---
name: awesome-design-md
description: Curated DESIGN.md reference library (awesome-design-md by VoltAgent). Use when a UI needs a specific premium visual language - tokens, typography, elevation, components - modeled on a real product design system. From https://github.com/voltagent/awesome-design-md.
---

# awesome-design-md (reference library)

Sumber: https://github.com/voltagent/awesome-design-md (MIT). Kumpulan `DESIGN.md`
(analisis sistem desain produk nyata) dalam format Stitch DESIGN.md. 119k+ stars.

## Isi

Folder `design-md/<brand>/DESIGN.md` per merek (Apple, Linear, Vercel, Notion,
Stripe, Wise, Superhuman, Raycast, Spotify, dll), masing-masing punya
`preview.html` dan `preview-dark.html`.

Ambil satu berkas dengan pola:

```
https://raw.githubusercontent.com/voltagent/awesome-design-md/main/design-md/<brand>/DESIGN.md
```

Daftar lengkap:
`https://api.github.com/repos/voltagent/awesome-design-md/contents/design-md`

## Pilihan yang cocok untuk RyanGunshop

Aplikasi ini adalah POS/utilitas produk, bukan landing page. Kandidat yang relevan:
`linear.app` (produk, satu aksen, padat, tenang), `vercel` (hitam-putih presisi),
`notion` (hangat minimalis), `wise` (jelas dan ramah), `superhuman` (premium fokus
keyboard).

Referensi acuan yang sudah dipilih: **linear.app** (lihat catatan di bawah).

## Cara pakai di proyek ini

1. Pilih satu sistem acuan. **Jangan gabungkan dua sistem** dalam satu proyek.
2. Ambil **struktur dan aturannya** (skala tipografi + tracking, tangga permukaan,
   ketebalan hairline, skala radius, disiplin aksen tunggal), lalu petakan ke token
   yang sudah ada di `mobile/lib/core/theme/`.
3. **Jangan** mengganti identitas: aksen tetap slate blue `#565C9D` (`AppColors.primary`),
   teks tetap bahasa Indonesia, istilah domain dan nama komponen `DESIGN.md` tetap.
4. Tools lint resmi: `npx @google/design.md lint DESIGN.md`.

## Catatan acuan: linear.app (ringkas)

- Aksen tunggal lavender-blue dipakai **hemat**: brand, CTA utama, focus ring.
  Warna semantik lain hanya success. Tidak ada aksen kedua.
- Ketiadaan shadow diwujudkan lewat **tangga permukaan** (canvas -> surface-1..4)
  plus **garis hairline 1px**, bukan drop shadow berat.
- Tipografi satu suara; display weight 500-600 dengan **tracking negatif** yang
  makin rapat saat ukuran naik (mis. -0.6px pada 28px), body weight 400.
- Radius: 8px tombol/input, 12px kartu, 16px panel besar. Tombol tidak pill.
- Basis spasi 4px. Nominal/ID memakai monospace/tabular.
- Kontras AA minimum, AAA untuk hero; dark mode tidak dipakai sebagai default di sini
  (aplikasi ini terang).

Terjemahan untuk proyek ini:
- Aksen = slate blue. Permukaan = `surface`/`canvas`/`primaryLight` sebagai tangga.
- Kartu pakai hairline `primaryLight` + shadow biru sangat lembut (bukan hitam).
- Judul halaman sans dengan tracking negatif; serif hanya untuk angka total besar.
- Angka nominal pakai fitur tabular agar kolom rapi.
