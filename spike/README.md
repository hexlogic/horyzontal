# Спайк етапу 0

Одноразовий застосунок, щоб зняти три технічні ризики до основної роботи
(див. [docs/spec.md](../docs/spec.md), розділ «Етапи»). Код звідси в основний застосунок
переноситься вибірково, сам застосунок не розвивається.

- **Мапа:** онлайн OpenFreeMap і офлайн PMTiles (Protomaps) з відмиванням рельєфу з DEM-пакета;
  дотик — висота точки, два довгі натискання — профіль висот.
- **Передавання:** Android піднімає LocalOnlyHotspot і показує QR; другий пристрій
  сканує його, під'єднується до точки й отримує тестовий файл по TCP з AES-256-GCM.

## Збирання

```bash
cd spike && flutter pub get
```

```bash
flutter build apk --debug
```

```bash
flutter build ios --debug
```

iOS: потрібен платний обліковий запис Apple Developer — capability *Hotspot Configuration*
(`Runner.entitlements`) безкоштовній команді недоступна. Виберіть свою команду в Xcode
(`ios/Runner.xcworkspace` → Signing & Capabilities) і додайте там само Hotspot Configuration.

## Пакети мап

Збираються в `tools/map-pipeline` (`./build_region.sh kyiv`), виходять
`out/kyiv.pmtiles` і `out/kyiv-dem.pmtiles`.

- **iPhone:** Finder → пристрій → Файли → «Горизонталь спайк» → перетягнути обидва файли
  (застосунок шукає пакети в `Documents` і `Documents/packs`) або кнопка імпорту на екрані «Мапа».
- **Android:** скопіювати на телефон та імпортувати кнопкою на екрані «Мапа», або для
  debug-збірки: `adb push` + `run-as com.synckord.horyzontal.spike cp … app_flutter/packs/`.

## Автотест без дотиків до екрана

Release-збірка виконує завдання й пише результат у `Documents/autotest.log` і в консоль
(`[autotest]`), див. `lib/autotest.dart`:

```bash
xcrun devicectl device copy to --device <udid> --domain-type appDataContainer --domain-identifier com.synckord.horyzontal.spike --source task.json --destination Documents/autotest.json
```

```bash
adb shell am start -S -n com.synckord.horyzontal.spike/.MainActivity --es autotest "'{\"do\":\"map\",\"bench\":true}'"
```

Завдання: `{"do":"map","lat":…,"lon":…,"zoom":…,"bench":true}`,
`{"do":"host","send":true,"mb":10,"hotspot":true}`, `{"do":"client","invite":"…","mb":10}`.
Системні запити iOS («Під'єднатися до мережі?») однаково натискає людина.

## Чек-лист на реальних пристроях

Пройдено 12.10.2026 на iPhone 16 Pro Max (iOS 27) і POCO F3 (Android 16), результати —
у [docs/stage0-spike.md](../docs/stage0-spike.md).

**Мапа (iPhone і Android):**

- [x] Авіарежим, «Офлайн»: мапа Київської області малюється, підписи українські
- [x] Відмивання рельєфу видно; діагональних смуг, як в емуляторі, немає
- [x] Висоти збігаються з Copernicus (середнє 0.22 м, максимум 1.18 м)
- [x] Профіль з 256 точок швидше за 300 мс у release (36–276 мс холодний, <1 мс повторно)
- [x] Згортання й повернення без вильотів
- [ ] Плавність на z14–15 — на око нормально, але кадри за секунду не виміряно

**Передавання (Android-хост і iPhone):**

- [x] Android піднімає точку й показує QR
- [x] iPhone сканує QR, під'єднується, передавання 10–100 МБ, sha256 збіглися
- [x] Зворотний напрям: iPhone надсилає, Android приймає
- [ ] 2–3 Android інших виробників і Android 8–12 (був один пристрій)
- [ ] Android ↔ Android через WifiNetworkSpecifier (потрібен другий Android)
- [ ] Автоповтор під'єднання на iOS у момент реального збою (збій 2 з 12, у контрольній серії не трапився)
