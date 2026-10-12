# Пайплайн офлайн-карт

Нарезает пакеты по 25 регионам: векторная карта из Protomaps Basemap и высоты из
Copernicus DEM GLO-30. Запускается локально или (позже) ежемесячно в GitHub Actions,
пакеты уходят в GitHub Releases.

| Файл | Что делает |
| --- | --- |
| `prepare_regions.py` | Полигоны регионов из geoBoundaries (OSM, ODbL): Киев сливается с Киевской областью, Севастополь с Крымом, буфер 2 км. Результат в `regions/` закоммичен. |
| `build_region.sh <id>` | Пакет одного региона: `out/<id>.pmtiles` и `out/<id>-dem.pmtiles` |
| `build_dem.py <id>` | Высоты: мозаика COG → Web Mercator → terrain-RGB (Mapbox) → WebP lossless → PMTiles |
| `style/generate.mjs` | Офлайн-стиль MapLibre из `@protomaps/basemaps` с подписями `uk` и слоем hillshade |
| `manifest.py <out> <build>` | `packs.json` для релиза `maps`: файлы областей с размером и SHA-256, приложение сверяет загрузки с ним |

## Публикация

`.github/workflows/maps.yml` раз в месяц (и вручную, можно для части областей) собирает все 25
областей из одной сборки Protomaps и выкладывает их в релиз
[`maps`](https://github.com/hexlogic/horyzontal/releases/tag/maps) вместе с `packs.json`. Пакеты
грузятся раньше манифеста, так что приложение не увидит ссылку на ещё не выложенный файл. Если
область не собралась, в релизе остаётся её прошлый пакет.

Приложение берёт `https://github.com/hexlogic/horyzontal/releases/download/maps/packs.json`. Для
проверки без GitHub можно раздать `out/` локально и собрать приложение с
`--dart-define=PACKS_BASE_URL=http://<адрес>:<порт>/` (только для отладки).

## Зависимости

```bash
brew install pmtiles gdal
```

`build_dem.py` нужен Python с GDAL-биндингами (у Homebrew это `python3.14`):

```bash
PYTHON=python3.14 ./build_region.sh kyiv
```

Стиль (Node 20+):

```bash
cd style && npm ci && node generate.mjs ../../../app/assets/map/style-offline.json
```

## Параметры по умолчанию и почему

- **Карта до z15.** Это максимум Protomaps; z14 экономит ~45%, но теряет номера домов.
- **Высоты до z12, тайл 256 px** — ~24 м/пикс на широте Украины, т.е. исходные 30 м не теряются.
- **Шаг высоты 1 м** вместо родных для terrain-RGB 0.1 м: пакет вдвое меньше, а ошибка
  против исходника в среднем 0.2 м (точность самого Copernicus 2–4 м).
- **WebP lossless** вместо PNG: на 30% меньше; MapLibre Native и пакет `image` его читают.

Copernicus — модель поверхности (DSM): высота включает лес и здания.
