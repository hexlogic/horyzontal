# Еталони для `horyzontal_geo`

Скрипти генерують еталонні значення для тестів `packages/horyzontal_geo/test/fixtures/`.
Фікстури лежать у git, CI скрипти не запускає. Перезбирати потрібно лише при зміні
параметрів або розширенні набору точок.

| Фікстура | Джерело |
| --- | --- |
| `datum_ukraine.csv`, `datum_inverse.csv` | PROJ `cct`, Гельмерт з параметрами EPSG:15865 (СК-42) і EPSG:7817 (УСК-2000) |
| `gk_sk42.csv`, `gk_usk2000.csv`, `tm3_usk2000.csv` | PROJ `tmerc` на еліпсоїді Красовського, своя й сусідня зона |
| `tm_factors.csv` | PROJ `proj -V`: зближення меридіанів і масштаб |
| `utm.csv` | PROJ `utm` |
| `mgrs.csv` | пакет `mgrs` (NGA GEOTRANS) |
| `geodtest_subset.dat` | кожен 20-й рядок GeodTest-short C. F. F. Karney ([doi:10.5281/zenodo.32156](https://doi.org/10.5281/zenodo.32156)) |
| `WMM2025_TEST_VALUES.txt` | офіційні тестові значення NOAA NCEI |
| `geoid.csv` | PROJ `vgridshift` за `us_nga_egm08_25.tif` |
| `polygons.csv` | `geographiclib` (`Geodesic.Polygon`): периметр, площа, довжина ламаної для 40 полігонів по Україні |
| `astro_positions.csv`, `astro_events.csv` | `skyfield` з ефемеридами JPL DE440: топоцентричні азимут і висота Сонця й Місяця (без рефракції), освітленість Місяця; сходи, заходи, кульмінації й сутінки (`almanac.find_risings`, `find_settings`, `find_transits`). Час — UT1 |

Використано PROJ 9.9.0, `geographiclib` 2.1, `mgrs` 1.5.4, `skyfield` 1.55, DE440.

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

Сонце й Місяць (окремий скрипт, ефемериди DE440 — 115 МБ, 1550–2650 роки):

```bash
/tmp/georef/bin/pip install skyfield==1.55
```

```bash
curl -L -o /tmp/de440.bsp https://ssd.jpl.nasa.gov/ftp/eph/planets/bsp/de440.bsp
```

```bash
/tmp/georef/bin/python -I tools/geo-reference/astro.py packages/horyzontal_geo/test/fixtures /tmp/de440.bsp
```

Час береться в UT1, а не в UTC skyfield: у skyfield немає високосних секунд до 1972 року й після
останньої оголошеної, тому його UTC за століття відходить від обертання Землі на хвилини. Громадянський
час тримається в межах секунди від UT1.

Сітка геоїда для застосунку та її перевірочні точки:

```bash
python3 -I tools/geo-reference/geoid.py packages/horyzontal_geo/lib/src/geoid/egm2008_ukraine.dart packages/horyzontal_geo/test/fixtures/geoid.csv
```

Потрібні `cct` і `proj` з PROJ із сіткою `us_nga_egm08_25.tif` (`projsync --file us_nga_egm08_25.tif`).

## Чому саме ці параметри

Єдиного офіційного набору параметрів СК-42 → WGS 84 для України немає. EPSG:15865 —
єдине перетворення EPSG, область дії якого охоплює Україну. `cs2cs` за
замовчуванням бере EPSG:5044 (ГОСТ Р 51794-2008, область дії — лише РФ): PROJ порівнює
тільки охопні прямокутники областей, а EPSG:5044 заявляє точність 3 м проти 4.5 м.
Під Києвом ці два варіанти розходяться приблизно на 1.8 м.

УСК-2000 → WGS 84: EPSG:7817 (офіційний перехід УСК-2000 → ITRF2000), WGS 84 вважається
таким, що збігається з ITRF2000. `cs2cs` бере EPSG:5840, це ті самі параметри, округлені до метра;
розбіжність близько 0.5 м.
