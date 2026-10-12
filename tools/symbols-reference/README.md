# Эталоны для `horyzontal_symbols`

`packages/horyzontal_symbols` — порт [milsymbol](https://github.com/spatialillusions/milsymbol)
3.0.4 (MIT, Måns Beckman) на Dart, только числовые SIDC (APP-6 D/E, 2525 D/E). Тест
`test/reference_test.dart` сравнивает SVG (байт в байт), размер, якоря, `isValid`, метаданные и
цвета с выводом самого milsymbol из `packages/horyzontal_symbols/test/fixtures/`. Фикстуры лежат в
git, CI node не запускает. Пересобирать нужно при переносе нового набора символов или расширении
корпуса.

| Фикстура | Что внутри |
| --- | --- |
| `land*.jsonl.gz` | наборы 10, 11, 15, 20, 27, 40: каждая сущность в четырех принадлежностях (2525) и в APP-6, все коды модификаторов 1 и 2 (двузначные и трехзначные 2525E), подтипы 95–99, уменьшение иконки техники и спешенных при модификаторах |
| `core-*.jsonl.gz` | рамки всех измерений, контексты, принадлежности, статусы, HQ/TF/FD, эшелоны, подвижность, форма рамки 2525E, опции стиля и текстовые поля, неверные SIDC; от наборов иконок не зависят (сущность `000000`) |
| `manifest.json` | версия milsymbol, перенесенные модули, файлы с наборами символов (`sets`) и числом записей |
| `js_number.json` | биты double и `String(x)` из JS — проверка форматирования чисел |

Запись `.jsonl.gz`: `sidc`, `options` (как в `new ms.Symbol(sidc, options)`), `svg`, `size`,
`anchor`, `octagonAnchor`, `isValid`, `validity`, `metadata`, у `core-options` еще `colors`;
`error`, если milsymbol бросает исключение (тогда и порт должен бросать).

## Запуск

```bash
mkdir -p /tmp/milsymbol && cd /tmp/milsymbol && npm pack milsymbol@3.0.4 && tar xzf milsymbol-3.0.4.tgz
```

```bash
node tools/symbols-reference/generate.mjs /tmp/milsymbol/package packages/horyzontal_symbols/test/fixtures
```

```bash
cd packages/horyzontal_symbols && dart test
```

Нужен Node 18+. Скрипт импортирует milsymbol по пути из аргумента и ничего из него в репозиторий не
копирует. В `manifest.json` пишется SHA-256 дерева `src/` milsymbol: если после пересборки
расходится все сразу, сначала сравните хэш — возможно, это другая копия пакета, а не ошибка порта.

## Как устроен эталон

- Регистрируются только перенесенные модули (`PORTED` в `generate.mjs`), в порядке milsymbol:
  `app6d`, затем `std2525d`, затем `std2525e`, как в `index.js` без буквенных модулей. Порядок
  важен: при совпадении ключей частей иконок побеждает модуль, добавленный позже.
- Перед каждым символом кэш иконок milsymbol сбрасывается. `ms._scale(…, true)` меняет закэшированные
  части иконок на месте, и с теплым кэшем вывод milsymbol зависит от порядка отрисовки (на корпусе
  land так расходятся 9 символов из 6725). Порт строит кэш по набору символов и масштабирует копии,
  поэтому всегда совпадает с холодным кэшем.
- Вывод совпадает и с полным бандлом milsymbol (с буквенными модулями): проверено на всем корпусе.
- Генератор печатает ключи частей иконок, на которые ссылаются таблицы, но которых нет ни в одном
  перенесенном файле частей; сейчас таких нет.

## Конвертер

`convert.mjs` механически переводит файл частей иконок или таблицу SIDC milsymbol в Dart: литералы
объектов в `<String, Object?>{...}`, массивы в `<Object?>[...]`, `ms._scale`/`ms._translate` в
`msScale`/`msTranslate`, `undefined` в `null`, финальный цикл регистрации в `registerIconParts`.
Файл только читается как текст. Результат — заготовка, после нее `dart format --line-length 100`,
`dart analyze` и ручные правки. Типичные: сложение строки с числом (`'M' + x` →
`'M' + jsString(x)`), не-bool в условиях (`a || b` → `truthy(a) ? a : b`), вызовы функций milsymbol,
которых нет в Dart. Проверенный Dart и есть исходник, конвертер сборкой не запускается.

## Как добавить набор символов

Модули milsymbol (`src/numbersidc/sidc/*.js`) в порядке регистрации и их файлы частей иконок
(`src/iconparts/*.js`):

| Модуль | Наборы | Части иконок | Статус |
| --- | --- | --- | --- |
| `air` | 01 | `air.js` | есть |
| `airmissile` | 02 | `air.js` | есть |
| `space` | 05 | `space.js` | есть |
| `spacemissile` | 06 | `space.js` | есть |
| `landunit` | 10 | `ground.js` | есть |
| `landcivilian` | 11 | `ground.js` | есть |
| `landequipment` | 15 | `ground.js` | есть |
| `landinstallation` | 20 | `ground.js` | есть |
| `sea` | 30 | `sea.js` | есть |
| `subsurface` | 35 | `subsurface.js` | есть |
| `minewarfare` | 36 | `subsurface.js` | есть |
| `activites` | 40 | `ground.js` | есть |
| `signalsintelligence` | 50–54 | `signals-intelligence.js` | есть |
| `dismountedindividual` | 27 | `ground.js` | есть |
| `tacticalpoints` (`control-measure.js`) | 25 | `tactical-points.js`, подписи `numbersidc/labels/tactical-points.js` | есть |
| `cyberspace` | 60 | `ground.js` (части `CY.*`) | есть |
| `common` | модификаторы 2525E | `common-modifiers.js` | есть |

Порядок для набора `air` (для остальных так же):

1. Части иконок, если файла еще нет в `lib/src/iconparts/`:
   ```bash
   node tools/symbols-reference/convert.mjs iconparts /tmp/milsymbol/package/src/iconparts/air.js airIconParts > packages/horyzontal_symbols/lib/src/iconparts/air.dart
   ```
2. Таблица SIDC:
   ```bash
   node tools/symbols-reference/convert.mjs sidc /tmp/milsymbol/package/src/numbersidc/sidc/air.js airIcons > packages/horyzontal_symbols/lib/src/numbersidc/sidc/air.dart
   ```
3. `dart format --line-length 100` и `dart analyze` по новым файлам, ручные правки (см. выше).
   В шапке файла остается `// Ported from milsymbol <путь>, MIT`; если правили руками, замените
   `hand edits: none` коротким списком правок.
4. В `lib/src/numbersidc.dart` объявить модуль
   (`const air = SymbolSetModule(name: 'air', symbolSets: ['01'], iconParts: airIconParts, icons: airIcons);`,
   для `tacticalpoints` еще `labels:`) и раскомментировать его в `app6d`, `std2525d` и `std2525e` на
   том же месте, где он стоит у milsymbol. Больше ничего в ядре менять не нужно: ядро берет части и
   таблицы из зарегистрированных модулей, а для незарегистрированных наборов рисует рамку со знаком
   вопроса milsymbol (`isValid == false`).
5. В `generate.mjs` добавить имя модуля в `PORTED` и раскомментировать (или добавить) семейство в
   `FAMILIES`; при необходимости задать сущность для модификаторов в `REPRESENTATIVE`.
6. Пересобрать **все** фикстуры и прогнать `dart test`: все файлы должны совпасть на 100 %. Новые
   части иконок могут законно изменить вывод уже перенесенных наборов (ссылки между модулями,
   переопределение ключей), поэтому сравнивать надо весь корпус, а не только новый файл.

Особые случаи: у `minewarfare` (36) есть опция `alternateMedal`; у мер управления (25) подписи
через `labels` (`numbersidc/labels/tactical-points.js` перенести как `LabelOverridesFunction` и
добавить в корпус варианты с текстовыми полями, в том числе ключами вроде `uniqueDesignation1`, иначе
`labelOverride` не выполнится) и типы инструкций `clip` и `svg` (в `assvg.dart` уже перенесены, но
корпусом пока не проверены); `cyberspace` использует части из `ground.dart`, нужна только таблица.
Пробная конвертация всех оставшихся файлов собирается, кроме одной строки в `tactical-points.js`
(`if (metadata.notpresent)` → `if (truthy(metadata.notpresent))`); компиляция еще не значит
совпадение, проверяет только полный корпус.
