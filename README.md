# Горизонталь

Бесплатное open source приложение для работы с картами и координатами на iOS и Android:
системы координат СК-42, УСК-2000, WGS84, MGRS, UTM, офлайн-топокарты, объекты APP-6,
обмен без интернета. Для военных, геодезистов, спасателей.

Спецификация: [docs/spec.md](docs/spec.md).

## Статус

Этап 1 — координаты, конвертер, компас. Этап 0 (спайк) закрыт:
[docs/stage0-spike.md](docs/stage0-spike.md).

Что уже работает: конвертер координат WGS 84 / СК-42 / УСК-2000 / UTM / MGRS, конвертер углов
(360°, 60-00, 64-00, Г°М′С″), прямая и обратная геодезические задачи на плоскости и эллипсоиде,
компас с истинным и магнитным севером (WMM2025), PIN и биометрия, зашифрованная база.

## Структура

| Путь | Что |
| --- | --- |
| `app/` | Приложение Flutter (iOS 17+, Android 8+) |
| `packages/horyzontal_geo/` | Геодезия на чистом Dart: датумы, сетки, MGRS, углы, задачи, WMM, геоид |
| `tools/geo-reference/` | Генерация эталонов для тестов `horyzontal_geo` (PROJ, GeographicLib, NOAA) |
| `tools/map-pipeline/` | Нарезка офлайн-пакетов по областям: Protomaps + Copernicus DEM |
| `tools/ci/` | Проверки CI |
| `spike/` | Одноразовое приложение этапа 0: офлайн PMTiles с рельефом, передача по Wi-Fi |
| `docs/` | Спецификация и отчеты |

`packages/horyzontal_symbols` (APP-6) появится на этапе 2.

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

Этап 1 вообще не обращается к сети: в Android-сборке нет разрешения `INTERNET`. С этапа 2
разрешены только эти хосты, CI (`tools/ci/check_domains.sh`) проверяет, что новых не появилось:

- `tiles.openfreemap.org`, `openfreemap.org` — онлайн-карта
- `github.com`, `objects.githubusercontent.com` — офлайн-пакеты из GitHub Releases
- источники тайлов, которые пользователь добавил сам

Никакой аналитики, рекламы и крэш-репортинга.

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
