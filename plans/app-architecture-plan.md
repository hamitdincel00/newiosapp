# Yozgat Hakimiyet iOS App - Kapsamlı Mimari Plan

## 📋 Proje Özeti
Mevcut basit haber uygulamasını, tüm API özelliklerini kullanan profesyonel, çok modüllü bir haber platformuna dönüştürme projesi.

## 🎯 Hedefler
1. **Çok Kanallı İçerik**: Haberler, Videolar, Galeriler, Arşiv
2. **Servisler Entegrasyonu**: Hava durumu, Namaz vakitleri, Döviz, Spor, Eczane
3. **Profesyonel UI/UX**: Modern, temiz, kullanıcı dostu tasarım
4. **Performans**: Lazy loading, pagination, caching
5. **Engagement**: Paylaşım, favoriler, bildirimler

---

## 📊 API Endpoint Analizi

### Mevcut Durum ✅
- Posts (Haberler) - Entegre
- Galleries (Galeriler) - Entegre
- Search - Entegre (sadece post)

### Eklenecekler 🚀

#### 1. Videos (Videolar)
```
GET /api/v2/videos/latest/5
GET /api/v2/videos/{id}
GET /api/v2/videos/featured
GET /api/v2/videos/trend
```
**Özellikler:**
- YouTube embed desteği
- Video thumbnail'ları
- Video kategorileri
- Trend videolar

#### 2. Services (Servisler)
```
GET /api/v2/services/weather?city=yozgat
GET /api/v2/services/prayer-times?city=yozgat
GET /api/v2/services/currency
GET /api/v2/services/standings
GET /api/v2/services/fixture
GET /api/v2/services/pharmacy?city=yozgat
```
**Modüller:**
- Hava Durumu Widget
- Namaz Vakitleri Widget
- Döviz/Altın/Kripto Widget
- Lig Puan Durumu Widget
- Maç Fikstürü Widget
- Nöbetçi Eczane Widget

#### 3. Archives (Arşiv)
```
GET /api/v2/archives/latest
GET /api/v2/archives/date/2026-01-08
GET /api/v2/archives/{id}
```

#### 4. Categories (Kategoriler)
```
GET /api/v2/categories
GET /api/v2/categories/{id}
GET /api/v2/posts/category/{id}
```

#### 5. Authors (Yazarlar)
```
GET /api/v2/authors
GET /api/v2/authors/{id}
GET /api/v2/authors/{id}/articles
```

---

## 🏗️ Uygulama Mimarisi

### Modül Yapısı

```
YozgatHakimiyet/
├── Models/
│   ├── Post.swift ✅
│   ├── Gallery.swift ✅
│   ├── Video.swift 🆕
│   ├── Service.swift 🆕
│   ├── Category.swift 🆕
│   ├── Author.swift 🆕
│   └── Archive.swift 🆕
│
├── Services/
│   ├── APIService.swift ✅ (genişletilecek)
│   ├── CacheService.swift 🆕
│   └── FavoriteService.swift 🆕
│
├── ViewModels/
│   ├── HomeViewModel.swift 🆕
│   ├── VideoViewModel.swift 🆕
│   ├── ServicesViewModel.swift 🆕
│   └── CategoryViewModel.swift 🆕
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift ✅ (yenilenecek)
│   │   ├── FeaturedSection.swift 🆕
│   │   └── QuickAccessWidget.swift 🆕
│   │
│   ├── Videos/
│   │   ├── VideoListView.swift 🆕
│   │   ├── VideoDetailView.swift 🆕
│   │   └── VideoPlayerView.swift 🆕
│   │
│   ├── Services/
│   │   ├── ServicesView.swift 🆕
│   │   ├── WeatherWidget.swift 🆕
│   │   ├── PrayerTimesWidget.swift 🆕
│   │   ├── CurrencyWidget.swift 🆕
│   │   ├── SportsWidget.swift 🆕
│   │   └── PharmacyWidget.swift 🆕
│   │
│   ├── Posts/
│   │   ├── PostDetailView.swift ✅
│   │   └── CategoryPostsView.swift 🆕
│   │
│   ├── Galleries/
│   │   ├── GalleryListView.swift ✅
│   │   └── GalleryDetailView.swift ✅
│   │
│   └── Common/
│       ├── SearchView.swift ✅ (genişletilecek)
│       └── CategoryFilterView.swift 🆕
│
├── Components/
│   ├── Cards/
│   │   ├── PostCard.swift ✅
│   │   ├── VideoCard.swift 🆕
│   │   ├── GalleryCard.swift ✅
│   │   └── ServiceCard.swift 🆕
│   │
│   ├── Widgets/
│   │   ├── LoadingView.swift 🆕
│   │   ├── ErrorView.swift 🆕
│   │   └── EmptyStateView.swift 🆕
│   │
│   └── BottomTabView.swift ✅ (güncellenecek)
│
└── Utils/
    ├── Config.swift ✅
    ├── ShareHelper.swift ✅
    ├── ViewExtensions.swift ✅
    └── DateFormatter.swift 🆕
```

---

## 🎨 UI/UX Tasarım Planı

### Ana Sayfa Yeniden Tasarımı

```
┌─────────────────────────────────┐
│  🏠 Yozgat Hakimiyet           │
│  [☰]                      [🔍] │
├─────────────────────────────────┤
│                                 │
│  📰 Öne Çıkan Haber            │
│  ┌───────────────────────────┐ │
│  │                           │ │
│  │    [BÜYÜK GÖRSEL]        │ │
│  │                           │ │
│  │  Başlık burada...         │ │
│  └───────────────────────────┘ │
│                                 │
│  🎬 Son Videolar               │
│  ┌─────┐ ┌─────┐ ┌─────┐     │
│  │[IMG]│ │[IMG]│ │[IMG]│ ▶   │
│  └─────┘ └─────┘ └─────┘     │
│                                 │
│  📸 Foto Galeriler             │
│  ┌─────┐ ┌─────┐ ┌─────┐     │
│  │[IMG]│ │[IMG]│ │[IMG]│ ▶   │
│  └─────┘ └─────┘ └─────┘     │
│                                 │
│  ⚡ Hızlı Erişim               │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ │
│  │ 🌤 │ │ 🕌 │ │ 💰 │ │ ⚽ │ │
│  │Hava│ │Ezan│ │Döviz│ │Spor│ │
│  └────┘ └────┘ └────┘ └────┘ │
│                                 │
│  📱 Son Haberler               │
│  ┌─────────────────────────┐  │
│  │ [IMG] Haber 1...        │  │
│  ├─────────────────────────┤  │
│  │ [IMG] Haber 2...        │  │
│  ├─────────────────────────┤  │
│  │ [IMG] Haber 3...        │  │
│  └─────────────────────────┘  │
│                                 │
└─────────────────────────────────┘
│ 🏠  ⚡  📰  🎬  📸              │
└─────────────────────────────────┘
```

### Yeni Bottom Tab Yapısı

```
1. 🏠 Ana Sayfa (HomeView)
   - Öne çıkan içerik
   - Son haberler
   - Hızlı erişim widget'ları

2. ⚡ Son Dakika (BreakingNewsView) ✅
   - Anlık haberler
   - Push notification bağlantısı

3. 📰 Haberler (CategoriesView) 🆕
   - Kategori filtreleme
   - Tüm haberler

4. 🎬 Videolar (VideosView) 🆕
   - Son videolar
   - Trend videolar
   - Video kategorileri

5. 💼 Servisler (ServicesView) 🆕
   - Hava durumu
   - Namaz vakitleri
   - Döviz kurları
   - Spor
   - Eczane
```

---

## 🔄 Veri Akışı

### MVVM Pattern

```
View → ViewModel → APIService → API
  ↑        ↓
  └────────┘
   (Binding)
```

### Caching Stratejisi

1. **UserDefaults**: Favoriler, ayarlar
2. **NSCache**: Görseller (kısa süreli)
3. **FileManager**: Offline içerik (uzun süreli)

### Pagination

```swift
struct PaginationState {
    var currentPage: Int = 1
    var hasMore: Bool = true
    var isLoading: Bool = false
}
```

---

## 🎬 Video Modülü Detayı

### Video Model
```swift
struct Video {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let image: PostImage
    let categories: [String: String]
    let embed: String // YouTube iframe
    let mediaUrl: String
    let hit: Int
    let author: Author?
    let createdAt: String
}
```

### Video Player
- WKWebView ile YouTube embed
- Tam ekran desteği
- Auto-play seçeneği
- Related videos

---

## 💼 Servisler Modülü Detayı

### 1. Hava Durumu Widget
```
┌─────────────────────┐
│ 🌤  Yozgat          │
│ ─────────────────── │
│ 15°C  Güneşli       │
│ ─────────────────── │
│ Nem: %45  Rüzgar: 5 │
└─────────────────────┘
```

### 2. Namaz Vakitleri Widget
```
┌─────────────────────┐
│ 🕌 Namaz Vakitleri  │
│ ─────────────────── │
│ İmsak:  06:45       │
│ Güneş:  08:12       │
│ Öğle:   13:15  ⏰   │
│ İkindi: 15:30       │
│ Akşam:  17:45       │
│ Yatsı:  19:15       │
└─────────────────────┘
```

### 3. Döviz Widget
```
┌─────────────────────┐
│ 💰 Döviz Kurları    │
│ ─────────────────── │
│ $ Dolar    34.25 ↑  │
│ € Euro     37.50 ↓  │
│ ₺ Altın   2,450 ↑   │
│ ₿ Bitcoin 42k   ↑   │
└─────────────────────┘
```

### 4. Spor Widget
```
┌─────────────────────┐
│ ⚽ Süper Lig        │
│ ─────────────────── │
│ 1. Galatasaray 45   │
│ 2. Fenerbahçe  42   │
│ 3. Beşiktaş    38   │
│ [Tümünü Gör]        │
└─────────────────────┘
```

---

## 🔍 Arama Modülü Geliştirmeleri

### Arama Filtreleri
- Haberler
- Videolar
- Galeriler
- Tarih aralığı
- Kategori

### Arama Sonuç Kartları
- Farklı içerik tiplerini ayırt etme
- İkon ile tip gösterimi (📰 haber, 🎬 video, 📸 galeri)

---

## 📱 Özellik Listesi

### Temel Özellikler ✅
- [x] Haber listesi ve detay
- [x] Galeri listesi ve detay
- [x] Paylaşım özelliği
- [x] Arama (temel)

### Yeni Özellikler 🚀

#### Faz 1: Video Modülü
- [ ] Video listesi
- [ ] Video detay ve player
- [ ] YouTube embed entegrasyonu
- [ ] Related videos

#### Faz 2: Servisler Modülü
- [ ] Hava durumu widget
- [ ] Namaz vakitleri widget
- [ ] Döviz kurları widget
- [ ] Spor puan durumu widget
- [ ] Eczane widget

#### Faz 3: Kategoriler ve Filtreleme
- [ ] Kategori listesi
- [ ] Kategori bazlı içerik filtreleme
- [ ] Alt kategoriler
- [ ] Kategori ikonları

#### Faz 4: Gelişmiş Özellikler
- [ ] Favoriler
- [ ] Offline okuma
- [ ] Karanlık mod
- [ ] Yazı boyutu ayarı
- [ ] Push notifications

#### Faz 5: Sosyal Özellikler
- [ ] Yorum sistemi
- [ ] Beğeni/Dislike
- [ ] Kullanıcı profili
- [ ] Okuma geçmişi

---

## 🎯 Öncelik Sırası

### Yüksek Öncelik (Hemen)
1. ✅ Video Model ve API entegrasyonu
2. ✅ Video liste ve detay sayfaları
3. ✅ Ana sayfa yeniden tasarımı
4. ✅ Bottom tab güncellemesi

### Orta Öncelik (Sonra)
5. Servisler modülü (widget'lar)
6. Kategori filtreleme sistemi
7. Pagination ve lazy loading
8. Gelişmiş arama

### Düşük Öncelik (İleride)
9. Favoriler
10. Offline mod
11. Dark mode
12. Social features

---

## 🔧 Teknik Gereksinimler

### Kütüphaneler
- **Mevcut**: SwiftUI, Combine, WKWebView
- **Eklenecek**:
  - Kingfisher veya SDWebImage (görsel cache)
  - YouTubePlayerKit (YouTube player)
  - Charts (grafik widget'ları için)

### Minimum iOS Version
- iOS 15.0+

### Performans Hedefleri
- Sayfa yüklenme: < 2 saniye
- Görsel yüklenme: Progressive loading
- Memory usage: < 150 MB
- Smooth scrolling: 60 FPS

---

## 📐 Tasarım Sistemi

### Renkler
```swift
// Primary
let primaryColor = Color(hex: "#ca2426") // Hakimiyet kırmızısı
let secondaryColor = Color(hex: "#202227")

// Background
let backgroundColor = Color(.systemBackground)
let cardBackground = Color(.systemGray6)

// Text
let primaryText = Color(.label)
let secondaryText = Color(.secondaryLabel)
```

### Typography
```swift
// Başlıklar
.font(.title) // 28pt, Bold
.font(.title2) // 22pt, Semibold
.font(.title3) // 20pt, Semibold

// İçerik
.font(.body) // 17pt, Regular
.font(.callout) // 16pt, Regular
.font(.subheadline) // 15pt, Regular
.font(.caption) // 12pt, Regular
```

### Spacing
```swift
let spacing4: CGFloat = 4
let spacing8: CGFloat = 8
let spacing12: CGFloat = 12
let spacing16: CGFloat = 16
let spacing24: CGFloat = 24
let spacing32: CGFloat = 32
```

---

## 🚀 Uygulama Aşamaları

### Aşama 1: Video Modülü (2-3 gün)
1. Video model oluştur
2. API servisleri ekle
3. Video liste view
4. Video detay ve player
5. Test ve düzeltmeler

### Aşama 2: Ana Sayfa Yenilemesi (1-2 gün)
1. Yeni layout tasarımı
2. Featured section
3. Quick access widgets
4. Section başlıkları ve navigation

### Aşama 3: Servisler Modülü (3-4 gün)
1. Service models
2. Widget components
3. API entegrasyonları
4. ServicesView container
5. Her widget için UI

### Aşama 4: Kategoriler (1-2 gün)
1. Category model
2. Category filter UI
3. Category-based content loading
4. Category navigation

### Aşama 5: İyileştirmeler (2-3 gün)
1. Pagination
2. Caching
3. Error handling
4. Loading states
5. Empty states
6. Performance optimization

---

## 📝 Sonraki Adımlar

1. ✅ Bu planı gözden geçir ve onayla
2. ✅ Video modülü ile başla (en hızlı değer)
3. ✅ Ana sayfayı yenile (kullanıcı deneyimi)
4. ✅ Servisler modülünü ekle (farklılaşma)
5. ✅ Kategorileri entegre et (içerik organizasyonu)
6. ✅ Polish ve optimizasyon yap

---

## 💡 Notlar

- **Modüler Yaklaşım**: Her modül bağımsız geliştirilebilir
- **Progressive Enhancement**: Temel özellikleri önce, gelişmiş özellikleri sonra
- **User-Centered**: Her karar kullanıcı deneyimini iyileştirmeli
- **Performance First**: Optimizasyon baştan beri düşünülmeli
- **Scalability**: Gelecekteki özellikler için esneklik

