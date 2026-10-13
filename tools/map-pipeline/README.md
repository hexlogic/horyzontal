# Конвеєр офлайн-мап

Нарізає пакети для 25 регіонів: векторна мапа з Protomaps Basemap і висоти з
Copernicus DEM GLO-30. Запускається локально або щомісяця в GitHub Actions,
пакети йдуть у GitHub Releases.

| Файл | Що робить |
| --- | --- |
| `prepare_regions.py` | Полігони регіонів з geoBoundaries (OSM, ODbL): Київ зливається з Київською областю, Севастополь із Кримом, буфер 2 км. Результат у `regions/` закомічено. |
| `build_region.sh <id>` | Пакет одного регіону: `out/<id>.pmtiles` і `out/<id>-dem.pmtiles` |
| `build_dem.py <id>` | Висоти: мозаїка COG → Web Mercator → terrain-RGB (Mapbox) → WebP lossless → PMTiles |
| `style/generate.mjs` | Офлайн-стиль MapLibre з `@protomaps/basemaps` з підписами `uk` і шаром hillshade |
| `manifest.py <out> <build>` | `packs.json` для релізу `maps`: файли областей з розміром і SHA-256, застосунок звіряє з ним завантаження |

## Публікація

`.github/workflows/maps.yml` раз на місяць (і вручну, можна для частини областей) збирає всі 25
областей з однієї збірки Protomaps і викладає їх у реліз
[`maps`](https://github.com/hexlogic/horyzontal/releases/tag/maps) разом із `packs.json`. Пакети
вантажаться раніше за маніфест, тож застосунок не побачить посилання на ще не викладений файл. Якщо
область не зібралася, у релізі лишається її попередній пакет.

Застосунок бере `https://github.com/hexlogic/horyzontal/releases/download/maps/packs.json`. Щоб
перевірити без GitHub, можна роздати `out/` локально й зібрати застосунок з
`--dart-define=PACKS_BASE_URL=http://<адреса>:<порт>/` (лише для налагодження).

## Залежності

```bash
brew install pmtiles gdal
```

`build_dem.py` потрібен Python з GDAL-біндингами (у Homebrew це `python3.14`):

```bash
PYTHON=python3.14 ./build_region.sh kyiv
```

Стиль (Node 20+):

```bash
cd style && npm ci && node generate.mjs ../../../app/assets/map/style-offline.json
```

## Типові параметри та чому саме вони

- **Мапа до z15.** Це максимум Protomaps; z14 заощаджує ~45%, але втрачає номери будинків.
- **Висоти до z12, тайл 256 px** — ~24 м/пікс на широті України, тобто вихідні 30 м не втрачаються.
- **Крок висоти 1 м** замість рідних для terrain-RGB 0.1 м: пакет удвічі менший, а похибка
  відносно джерела в середньому 0.2 м (точність самого Copernicus 2–4 м).
- **WebP lossless** замість PNG: на 30% менше; MapLibre Native і пакет `image` його читають.

Copernicus — модель поверхні (DSM): висота враховує ліс і будівлі.
