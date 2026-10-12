# Горизонталь

Бесплатное open source приложение для работы с картами и координатами на iOS и Android:
системы координат СК-42, УСК-2000, WGS84, MGRS, UTM, офлайн-топокарты, объекты APP-6,
обмен без интернета. Для военных, геодезистов, спасателей.

Спецификация: [docs/spec.md](docs/spec.md).

## Статус

Этап 0 — спайк технических рисков. Итоги: [docs/stage0-spike.md](docs/stage0-spike.md).

## Структура

| Путь | Что |
| --- | --- |
| `spike/` | Одноразовое приложение этапа 0: офлайн PMTiles с рельефом, передача по Wi-Fi |
| `tools/map-pipeline/` | Нарезка офлайн-пакетов по областям: Protomaps + Copernicus DEM |
| `docs/` | Спецификация и отчеты |

Будут добавлены на этапе 1: `packages/horyzontal_geo`, `packages/horyzontal_symbols`, `app/`.

## Данные

- Карта: © участники [OpenStreetMap](https://www.openstreetmap.org/copyright) (ODbL),
  [Protomaps](https://protomaps.com), [OpenFreeMap](https://openfreemap.org)
- Высоты: Copernicus DEM GLO-30 © DLR e.V. 2010–2014 и © Airbus Defence and Space GmbH 2014–2018,
  предоставлено в рамках COPERNICUS Европейским союзом и ESA
- Границы областей: [geoBoundaries](https://www.geoboundaries.org) (OpenStreetMap, ODbL)
- Шрифты Noto Sans (SIL OFL)

## Лицензия

GPL-3.0, см. [LICENSE](LICENSE).
