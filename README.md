# 🔄 Auto Sync Repository Action

Cuman buat sync antar 2 repository biar saling terhubung. Jadi lu push ke repo A doang, repo B auto ke-update sendiri. Udah gitu doang.

Use case: **Rahasia**

## 🤔 Kenapa Pake Ini?
Gak tau gabut aja mau buat ginian.
Fitur nya kaya gini doang:
- Auto sync antar repo, gak perlu push manual
- Semua ref (branch, tag, dll) ikut kesync (kalau ada conflict bukan urusan gua, benerin sendiri)
- Setup sekali, auto jalan terus, gak perlu langganan, fotocopy ktp, kk, dll
- Support private repo!

## ⚠️ Persiapan

> [!WARNING]
> Lu perlu setup ssh dulu terus ikutin step di bawah, gua gak ngasih tau cara setupnya 
> lu cari sendiri udah gede mandiri.

Kalau udah ada ssh nya, lakuin ini (gak ada ss, males masukin nya):
1. Public key (`.pub`) -> Masukin ke Deploy Keys repo tujuan, **JANGAN LUPA CENTANG ALLOW WRITE ACCESS**
2. Private key -> Masukin ke `Secrets` repo source, nama nya suka suka lu contoh nya gini: `SUKA_SUKA_LU`

## 🚀 Cara Pake

1. Buat file `.github/workflows/sync-repo.yml` di repo source lu, isi nya kek gini:

```yaml
name: Sync Repository

on:
  push:
    branches:
      - '**'  # Sync pas ada push ke branch mana aja
  create:
    tags:
      - '**'  # Sync pas bikin tag baru
  delete:
    tags:
      - '**'  # Sync pas hapus tag
  workflow_dispatch:  # Bisa manual trigger kalo mau

permissions:
  contents: read

jobs:
  sync:
    # Penting! Ganti sesuai repo tujuan lu
    # Biar gak jalan juga actions nya di repo tujuan
    if: github.repository != 'username-lu/repo-tujuan'
    runs-on: ubuntu-latest
    name: Sync Repository
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Sync to Target Repository
        uses: rianllauo/github-actions-auto-push@main
        with:
          destination_repo: 'username-lu/repo-tujuan'  # Ganti sama repo tujuan
          ssh_private_key: ${{ secrets.SSH_PRIVATE_KEY }}
          target_branch: 'main'  # Optional, default ke 'main'
          github_token: ${{ secrets.GITHUB_TOKEN }}  # Ini udah auto ada, gausah diapa-apain
```

2. Commit & push file itu ke repo source lu
3. Kelas 🔥! Sekarang tiap lu push ke repo source, repo tujuan bakal auto ke-update

## 🤔 FAQ

**Q: Gw udah setup tapi error pas clone source repo?**
A: Mungkin anda kurang tampan!

**Q: Repo gw private, bisa gak?**
A: Bisa lah kocak udah di tulis di atas!

**Q: Kalo gw push ke repo tujuan, bakal infinite loop gak?**
A: Kagak! Udah gua kasih note di script nya baca makanya!

kalau ada pertanyaan lain di simpen aja, gak nerima pertanyaan lagi!

## 🐛 Ada Bug?

Yo nda tau ko tanya saya

## 📝 License
Gak pake License, suka suka lu mau di apain. Gak nerima info bug jadi jangan buat issue, fork aja terus lu benerin sendiri 