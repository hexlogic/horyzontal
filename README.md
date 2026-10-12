# Горизонталь

Бесплатное open source приложение для работы с картами и координатами на iOS и Android:
системы координат СК-42, УСК-2000, WGS84, MGRS, UTM, офлайн-топокарты, объекты APP-6,
обмен без интернета. Для военных, геодезистов, спасателей.

Спецификация: [docs/spec.md](docs/spec.md).

## Статус

Этап 3 — инструменты, состояние в [docs/stage3.md](docs/stage3.md). Этапы 0 (спайк,
[docs/stage0-spike.md](docs/stage0-spike.md)), 1 (координаты, конвертер, компас) и 2 (карта и
объекты, [docs/stage2.md](docs/stage2.md)) закрыты.

Что уже работает: конвертер координат WGS 84 / СК-42 / УСК-2000 / UTM / MGRS, конвертер углов
(360°, 60-00, 64-00, Г°М′С″), прямая и обратная геодезические задачи на плоскости и эллипсоиде с
дирекционным, истинным и магнитным углом, компас с истинным и магнитным севером (WMM2025); онлайн-
и офлайн-карта, объекты APP-6, слои, журнал, обмен QR, файлами и по Wi-Fi; линейка, полилинии,
полигоны с площадью, профиль высот и видимость между точками с высотой мачт; PIN и биометрия,
зашифрованная база.

## Структура

| Путь | Что |
| --- | --- |
| `app/` | Приложение Flutter (iOS 17+, Android 8+) |
| `packages/horyzontal_geo/` | Геодезия на чистом Dart: датумы, сетки, MGRS, углы, задачи, WMM, геоид |
| `tools/geo-reference/` | Генерация эталонов для тестов `horyzontal_geo` (PROJ, GeographicLib, NOAA) |
| `packages/horyzontal_symbols/` | Символы APP-6 (порт milsymbol) и каталог кодов с украинскими названиями |
| `tools/map-pipeline/` | Нарезка офлайн-пакетов по областям: Protomaps + Copernicus DEM; ежемесячно в `.github/workflows/maps.yml` |
| `tools/ci/` | Проверки CI |
| `spike/` | Одноразовое приложение этапа 0: офлайн PMTiles с рельефом, передача по Wi-Fi |
| `docs/` | Спецификация и отчеты |

## Сборка и тесты

Репозиторий — pub workspace, зависимости ставятся один раз из корня.

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

База шифруется SQLCipher: `package:sqlite3` подтягивает сборку SQLCipher при компиляции
(настройка `hooks` в корневом `pubspec.yaml`). Код Drift и локализация сгенерированы и лежат в
git; после изменения схемы или строк: `dart run build_runner build` и `flutter gen-l10n` в `app/`.

## Сетевая политика

Приложение обращается только к этим хостам (список в `app/lib/core/net/network.dart`, HTTP-клиент
отказывает остальным и проверяет каждый редирект; CI `tools/ci/check_domains.sh` следит, чтобы
в коде не появилось новых адресов):

- `tiles.openfreemap.org` — онлайн-карта (стиль, тайлы, шрифты)
- `github.com`, `objects.githubusercontent.com`, `release-assets.githubusercontent.com` — офлайн-пакеты
  из релиза [`maps`](https://github.com/hexlogic/horyzontal/releases/tag/maps)
- серверы тайлов, которые пользователь добавил сам в «Джерела мапи» (только https). Их адреса
  хранятся в зашифрованной базе; в коде и в репозитории адресов сторонних серверов нет. Запросы
  к ним идут только после уведомления о приватности и не идут в режиме «Только офлайн»;
  загрузка области идет через тот же HTTP-клиент с белым списком

Режим «Только офлайн» в настройках отключает сеть полностью, включая MapLibre. Передача слоёв
по Wi-Fi идёт по локальной точке доступа или Multipeer Connectivity, без интернета.

Никакой аналитики, рекламы и крэш-репортинга. QR сканируется через ZXing (zxing-cpp) на
устройстве, без Google ML Kit; CI следит, чтобы ML Kit не вернулся.

## Данные

- Карта: © участники [OpenStreetMap](https://www.openstreetmap.org/copyright) (ODbL),
  [Protomaps](https://protomaps.com), [OpenFreeMap](https://openfreemap.org)
- Высоты: Copernicus DEM GLO-30 © DLR e.V. 2010–2014 и © Airbus Defence and Space GmbH 2014–2018,
  предоставлено в рамках COPERNICUS Европейским союзом и ESA
- Границы областей: [geoBoundaries](https://www.geoboundaries.org) (OpenStreetMap, ODbL)
- Шрифты Noto Sans (SIL OFL)
- Магнитное поле: World Magnetic Model WMM2025, NOAA NCEI и BGS (общественное достояние)
- Геоид: EGM2008, NGA (общественное достояние)
- Геодезические задачи: порт GeographicLib, © C. F. F. Karney (MIT)

## Лицензия

GPL-3.0, см. [LICENSE](LICENSE).
