---
name: design-taste-frontend
description: Anti-slop frontend/UI design taste skill (taste-skill by Leonxlnx). Use when overhauling or reviewing the look of a UI - layout, typography, spacing, motion, color - so the result does not look generic or templated. Adapted from https://github.com/leonxlnx/taste-skill.
---

# design-taste-frontend (taste-skill, adapted)

Sumber asli: https://github.com/leonxlnx/taste-skill (MIT, (c) 2026 Leonxlnx).
Aturan lengkap: fetch `https://raw.githubusercontent.com/leonxlnx/taste-skill/main/skills/taste-skill/SKILL.md`
sebelum dipakai, lalu terapkan.

## When to use

Gunakan saat merombak atau meninjau tampilan UI: struktur layout, tipografi, spasi,
gerak, warna, dan state. Jangan pakai untuk tabel data padat atau backend.

## PENTING - batas cakupan (dari skill aslinya, Section 13)

Skill asli menyatakan dirinya **bukan untuk native mobile**: "Native mobile (use
Apple HIG / Material directly)". Untuk proyek Flutter ini:

- Pakai **Material 3** sebagai fondasi (bukan Tailwind/GSAP/React dari skill asli).
- Ambil **metodenya**, bukan resep web-nya:
  - Section 0 - **Brief inference**: tulis satu baris "Design Read" sebelum mengubah UI
    (jenis layar, audiens, vibe, sistem/aesthetic yang dituju).
  - Section 1 - **Tiga dial**: `DESIGN_VARIANCE`, `MOTION_INTENSITY`, `VISUAL_DENSITY`.
    Untuk aplikasi kasir yang aksesibilitas-kritis dan dipakai di perangkat kelas bawah,
    gunakan dial rendah-sedang (mis. 3-5 / 3-5 / 5-6) dan utamakan keterbacaan.
  - Section 4 - **Bias correction**: tipografi berani (tracking negatif di display),
    satu warna aksen saja, hindari kartu seragam 3-kolom, shadow ditint ke latar,
    state loading/empty/error lengkap, CTA satu baris.
  - Section 5 - **Motion harus punya alasan** (hierarki, cerita, umpan balik, atau
    transisi state), bukan "biar keren". Wajib hormati reduced motion.
  - Section 9 - **AI tells yang dilarang**: tanpa em-dash, tanpa glow neon, tanpa
    pure black, tanpa gradien AI-purple, tanpa "Acme"/"John Doe", tanpa label versi.
  - Section 14 - **Pre-flight check** sebelum menandai selesai.

## Cara pakai di proyek ini

1. Tulis Design Read + nilai dial di deskripsi perubahan.
2. Terapkan prinsip di atas pada widget Flutter, **selalu lewat token** di
   `mobile/lib/core/theme/` (warna, spacing, radius, tipografi). Jangan tulis nilai
   heksadesimal atau ukuran langsung.
3. Teks UI tetap bahasa Indonesia. Istilah domain dan nama komponen `DESIGN.md`
   tidak diganti.
4. Jalankan `flutter analyze` dan `flutter test` setelah perubahan.
