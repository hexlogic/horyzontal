# Горизонталь

Безкоштовний застосунок з відкритим кодом для роботи з мапами й координатами на iOS та Android:
системи координат СК-42, УСК-2000, WGS84, MGRS, UTM, офлайн-топомапи, об'єкти APP-6,
обмін без інтернету. Для військових, геодезистів, рятувальників.

Специфікація: [docs/spec.md](docs/spec.md).

## Стан

Етап 4 — розширення, стан у [docs/stage4.md](docs/stage4.md). Етапи 0 (спайк,
[docs/stage0-spike.md](docs/stage0-spike.md)), 1 (координати, конвертер, компас), 2 (мапа й
об'єкти, [docs/stage2.md](docs/stage2.md)) і 3 (інструменти, [docs/stage3.md](docs/stage3.md))
закрито.

Що вже працює: конвертер координат WGS 84 / СК-42 / УСК-2000 / UTM / MGRS, конвертер кутів
(360°, 60-00, 64-00, Г°Х′С″), пряма й обернена геодезичні задачі на площині та еліпсоїді з
дирекційним, істинним і магнітним кутом, компас з істинною й магнітною північчю (WMM2025); Сонце
й Місяць (азимут, висота, фаза, схід, захід, сутінки з таймером); онлайн- і офлайн-мапа з
тепловою мапою висот і кластеризацією, свої джерела мап (XYZ/TMS/WMS із завантаженням області,
MBTiles, PMTiles), об'єкти APP-6, шари, журнал, обмін QR, файлами й по Wi-Fi; лінійка, полілінії,
полігони з площею, профіль висот і видимість між точками з висотою щогл; розкладка для
планшетів; PIN і біометрія, зашифрована база.

## Структура

| Шлях | Що |
| --- | --- |
| `app/` | Застосунок Flutter (iOS 17+, Android 8+) |
| `packages/horyzontal_geo/` | Геодезія на чистому Dart: датуми, сітки, MGRS, кути, задачі, WMM, геоїд, Сонце й Місяць |
| `tools/geo-reference/` | Генерування еталонів для тестів `horyzontal_geo` (PROJ, GeographicLib, NOAA, skyfield) |
| `packages/horyzontal_symbols/` | Умовні знаки APP-6 (порт milsymbol) і каталог кодів з українськими назвами |
| `tools/map-pipeline/` | Нарізання офлайн-пакетів за областями: Protomaps + Copernicus DEM; щомісяця в `.github/workflows/maps.yml` |
| `tools/ci/` | Перевірки CI |
| `spike/` | Одноразовий застосунок етапу 0: офлайн PMTiles з рельєфом, передавання по Wi-Fi |
| `docs/` | Специфікація та звіти |

## Збирання й тести

Репозиторій — pub workspace, залежності встановлюються один раз із кореня.

```bash
flutter pub get
```

```bash
cd packages/horyzontal_geo && dart test
```

```bash
cd app && flutter test
```

```bash
cd app && flutter run
```

База шифрується SQLCipher: `package:sqlite3` підтягує збірку SQLCipher під час компіляції
(налаштування `hooks` у кореневому `pubspec.yaml`). Код Drift і локалізацію згенеровано, вони лежать у
git; після зміни схеми чи рядків: `dart run build_runner build` і `flutter gen-l10n` в `app/`.

## Мережева політика

Застосунок звертається лише до цих хостів (список в `app/lib/core/net/network.dart`, HTTP-клієнт
відмовляє решті й перевіряє кожне перенаправлення; CI `tools/ci/check_domains.sh` стежить, щоб
у коді не з'явилося нових адрес):

- `tiles.openfreemap.org` — онлайн-мапа (стиль, тайли, шрифти)
- `github.com`, `objects.githubusercontent.com`, `release-assets.githubusercontent.com` — офлайн-пакети
  з релізу [`maps`](https://github.com/hexlogic/horyzontal/releases/tag/maps)
- сервери тайлів, які користувач сам додав у «Джерела мапи» (лише https). Їхні адреси
  зберігаються в зашифрованій базі; у коді й репозиторії адрес сторонніх серверів немає. Запити
  до них ідуть лише після повідомлення про приватність і не йдуть у режимі «Тільки офлайн»;
  завантаження області йде через той самий HTTP-клієнт із білим списком

Режим «Тільки офлайн» у налаштуваннях вимикає мережу повністю, зокрема й MapLibre. Передавання шарів
по Wi-Fi йде через локальну точку доступу або Multipeer Connectivity, без інтернету.

Жодної аналітики, реклами й звітів про збої. QR сканується через ZXing (zxing-cpp) на
пристрої, без Google ML Kit; CI стежить, щоб ML Kit не повернувся.

## Дані

- Мапа: © учасники [OpenStreetMap](https://www.openstreetmap.org/copyright) (ODbL),
  [Protomaps](https://protomaps.com), [OpenFreeMap](https://openfreemap.org)
- Висоти: Copernicus DEM GLO-30 © DLR e.V. 2010–2014 і © Airbus Defence and Space GmbH 2014–2018,
  надано в рамках COPERNICUS Європейським Союзом та ESA
- Межі областей: [geoBoundaries](https://www.geoboundaries.org) (OpenStreetMap, ODbL)
- Шрифти Noto Sans (SIL OFL)
- Магнітне поле: World Magnetic Model WMM2025, NOAA NCEI і BGS (суспільне надбання)
- Геоїд: EGM2008, NGA (суспільне надбання)
- Геодезичні задачі: порт GeographicLib, © C. F. F. Karney (MIT)
- Сонце й Місяць: алгоритми J. Meeus (Astronomical Algorithms), ряди ELP-2000/82

## Ліцензія

GPL-3.0, див. [LICENSE](LICENSE).
