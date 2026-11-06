---
name: web-design-guidelines
description: Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check against best practices". From https://github.com/vercel-labs/agent-skills (skills/web-design-guidelines).
metadata:
  author: vercel
  version: "1.0.0"
  argument-hint: <file-or-pattern>
---

# Web Interface Guidelines

Review files for compliance with Web Interface Guidelines.

## How It Works

1. Fetch the latest guidelines from the source URL below
2. Read the specified files (or prompt user for files/pattern)
3. Check against all rules in the fetched guidelines
4. Output findings in the terse `file:line` format

## Guidelines Source

Fetch fresh guidelines before each review:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

Use WebFetch to retrieve the latest rules. The fetched content contains all the rules and output format instructions.

## Usage

When a user provides a file or pattern argument:
1. Fetch guidelines from the source URL above
2. Read the specified files
3. Apply all rules from the fetched guidelines
4. Output findings using the format specified in the guidelines

If no files specified, ask the user which files to review.

## Catatan untuk proyek ini (Flutter)

Pedoman di atas ditulis untuk web (HTML/CSS/ARIA). Untuk aplikasi Flutter Android,
terjemahkan prinsipnya, bukan markup-nya:

- **A11y**: tombol ikon butuh tooltip/semantic label; kontrol form butuh label;
  gambar dekoratif disembunyikan dari pembaca layar; update async pakai live region.
- **Fokus**: setiap kontrol interaktif punya focus/selected state yang terlihat.
- **Form**: label di atas input (jangan placeholder sebagai label); error inline di
  bawah field dan menyertakan langkah perbaikan; tombol simpan tetap aktif sampai
  request dimulai.
- **Animasi**: hormati reduced motion; animasikan `transform`/`opacity` saja.
- **Tipografi**: pakai elipsis `…`, tanda kutip melengkung, angka tabular untuk kolom
  nominal.
- **Konten**: tangani teks panjang (ellipsis/maxLines), empty state yang jelas.
- **Navigasi & state**: aksi destruktif butuh konfirmasi; state tercermin di UI.
- **Touch**: target sentuh minimal 48 dp; safe area untuk notch.
