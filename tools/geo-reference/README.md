# Эталоны для `horyzontal_geo`

Скрипты генерируют эталонные значения для тестов `packages/horyzontal_geo/test/fixtures/`.
Фикстуры лежат в git, CI скрипты не запускает. Пересобирать нужно только при смене
параметров или расширении набора точек.

| Фикстура | Источник |
| --- | --- |
| `datum_ukraine.csv`, `datum_inverse.csv` | PROJ `cct`, Гельмерт с параметрами EPSG:15865 (СК-42) и EPSG:7817 (УСК-2000) |
| `gk_sk42.csv`, `gk_usk2000.csv`, `tm3_usk2000.csv` | PROJ `tmerc` на эллипсоиде Красовского, своя и соседняя зона |
| `tm_factors.csv` | PROJ `proj -V`: сближение меридианов и масштаб |
| `utm.csv` | PROJ `utm` |
| `mgrs.csv` | пакет `mgrs` (NGA GEOTRANS) |
| `geodtest_subset.dat` | каждая 20-я строка GeodTest-short C. F. F. Karney ([doi:10.5281/zenodo.32156](https://doi.org/10.5281/zenodo.32156)) |
| `WMM2025_TEST_VALUES.txt` | официальные тестовые значения NOAA NCEI |
| `geoid.csv` | PROJ `vgridshift` по `us_nga_egm08_25.tif` |
| `polygons.csv` | `geographiclib` (`Geodesic.Polygon`): периметр, площадь, длина ломаной для 40 полигонов по Украине |
| `astro_positions.csv`, `astro_events.csv` | `skyfield` с эфемеридами JPL DE440: топоцентрические азимут и высота Солнца и Луны (без рефракции), освещенность Луны; восходы, заходы, кульминации и сумерки (`almanac.find_risings`, `find_settings`, `find_transits`). Время — UT1 |

Использовались PROJ 9.9.0, `geographiclib` 2.1, `mgrs` 1.5.4, `skyfield` 1.55, DE440.

## Запуск

```bash
python3 -m venv /tmp/georef && /tmp/georef/bin/pip install mgrs packaging geographiclib==2.1
```

```bash
curl -L -o /tmp/GeodTest-short.dat.gz https://sourceforge.net/projects/geographiclib/files/testdata/GeodTest-short.dat.gz/download
```

```bash
/tmp/georef/bin/python -I tools/geo-reference/generate.py packages/horyzontal_geo/test/fixtures /tmp/GeodTest-short.dat.gz
```

Солнце и Луна (отдельный скрипт, эфемериды DE440 — 115 МБ, 1550–2650 годы):

```bash
/tmp/georef/bin/pip install skyfield==1.55
```

```bash
curl -L -o /tmp/de440.bsp https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de440.bsp
```

```bash
/tmp/georef/bin/python -I tools/geo-reference/astro.py packages/horyzontal_geo/test/fixtures /tmp/de440.bsp
```

Время берется в UT1, а не в UTC skyfield: у skyfield нет високосных секунд до 1972 года и после
последней объявленной, поэтому его UTC за века уходит от вращения Земли на минуты. Гражданское
время держится в пределах секунды от UT1.

Сетка геоида для приложения и ее проверочные точки:

```bash
python3 -I tools/geo-reference/geoid.py packages/horyzontal_geo/lib/src/geoid/egm2008_ukraine.dart packages/horyzontal_geo/test/fixtures/geoid.csv
```

Нужны `cct` и `proj` из PROJ с сеткой `us_nga_egm08_25.tif` (`projsync --file us_nga_egm08_25.tif`).

## Почему эти параметры

Единого официального набора параметров СК-42 → WGS 84 для Украины нет. EPSG:15865 —
единственное преобразование EPSG, область действия которого включает Украину. `cs2cs` по
умолчанию берет EPSG:5044 (ГОСТ Р 51794-2008, область действия — только РФ): PROJ сравнивает
только охватывающие прямоугольники областей, а EPSG:5044 заявляет точность 3 м против 4.5 м.
Под Киевом эти два варианта расходятся примерно на 1.8 м.

УСК-2000 → WGS 84: EPSG:7817 (официальный переход УСК-2000 → ITRF2000), WGS 84 считается
совпадающим с ITRF2000. `cs2cs` берет EPSG:5840, это те же параметры, округленные до метра;
расхождение около 0.5 м.
