# Еталони для `horyzontal_symbols`

`packages/horyzontal_symbols` — порт [milsymbol](https://github.com/spatialillusions/milsymbol)
3.0.4 (MIT, Måns Beckman) на Dart, лише числові SIDC (APP-6 D/E, 2525 D/E). Тест
`test/reference_test.dart` порівнює SVG (байт у байт), розмір, якорі, `isValid`, метадані й
кольори з виводом самого milsymbol з `packages/horyzontal_symbols/test/fixtures/`. Фікстури лежать у
git, CI node не запускає. Перезбирати потрібно під час перенесення нового набору знаків або розширення
корпусу.

| Фікстура | Що всередині |
| --- | --- |
| `<модуль>*.jsonl.gz` | те саме для решти модулів (`air`, `sea`, ..., `tacticalpoints`), плюс `*-styles` (рамка, заливка, monoColor, alternateMedal по черзі) і `tacticalpoints-labels` (підписи заходів керування з усіма їхніми текстовими полями) |
| `land*.jsonl.gz` | набори 10, 11, 15, 20, 27, 40: кожна сутність у чотирьох належностях (2525) і в APP-6, усі коди модифікаторів 1 і 2 (двозначні й тризначні 2525E), підтипи 95–99, зменшення іконки техніки й спішених за наявності модифікаторів |
| `core-*.jsonl.gz` | рамки всіх вимірів, контексти, належності, статуси, HQ/TF/FD, ешелони, рухомість, форма рамки 2525E, опції стилю й текстові поля, хибні SIDC; від наборів іконок не залежать (сутність `000000`) |
| `manifest.json` | версія milsymbol, перенесені модулі, файли з наборами знаків (`sets`) і кількістю записів |
| `js_number.json` | біти double і `String(x)` з JS — перевірка форматування чисел |

Запис `.jsonl.gz`: `sidc`, `options` (як у `new ms.Symbol(sidc, options)`), `svg`, `size`,
`anchor`, `octagonAnchor`, `isValid`, `validity`, `metadata`, у `core-options` ще `colors`;
`error`, якщо milsymbol кидає виняток (тоді й порт має кидати).

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

Потрібен Node 18+. Скрипт імпортує milsymbol за шляхом з аргументу й нічого з нього в репозиторій не
копіює. У `manifest.json` пишеться SHA-256 дерева `src/` milsymbol: якщо після перезбирання
розходиться все одразу, спочатку порівняйте хеш — можливо, це інша копія пакета, а не помилка порту.

## Як влаштовано еталон

- Реєструються лише перенесені модулі (`PORTED` у `generate.mjs`), у порядку milsymbol:
  `app6d`, потім `std2525d`, потім `std2525e`, як в `index.js` без літерних модулів. Порядок
  важливий: за збігу ключів частин іконок перемагає модуль, доданий пізніше.
- Перед кожним знаком кеш іконок milsymbol скидається. `ms._scale(…, true)` змінює закешовані
  частини іконок на місці, і з теплим кешем вивід milsymbol залежить від порядку малювання (на корпусі
  land так розходяться 9 знаків із 6725). Порт будує кеш за набором знаків і масштабує копії,
  тому завжди збігається з холодним кешем.
- Вивід збігається й з повним бандлом milsymbol (з літерними модулями): перевірено на всьому корпусі.
- Генератор друкує ключі частин іконок, на які посилаються таблиці, але яких немає в жодному
  перенесеному файлі частин. Зараз це лише `TODO` з `control-measure.js` — заглушка самого
  milsymbol, такі заходи керування в нього теж невалідні.

## Конвертер

`convert.mjs` механічно перекладає файл частин іконок або таблицю SIDC milsymbol у Dart: літерали
об'єктів у `<String, Object?>{...}`, масиви в `<Object?>[...]`, `ms._scale`/`ms._translate` у
`msScale`/`msTranslate`, `undefined` у `null`, фінальний цикл реєстрації в `registerIconParts`.
Файл лише читається як текст. Результат — заготовка, після неї `dart format --line-length 100`,
`dart analyze` і ручні правки. Типові: додавання рядка до числа (`'M' + x` →
`'M' + jsString(x)`), не-bool в умовах (`a || b` → `truthy(a) ? a : b`), виклики функцій milsymbol,
яких немає в Dart. Перевірений Dart і є джерелом, конвертер під час збирання не запускається.

## Як додати набір знаків

Модулі milsymbol (`src/numbersidc/sidc/*.js`) у порядку реєстрації та їхні файли частин іконок
(`src/iconparts/*.js`):

| Модуль | Набори | Частини іконок | Стан |
| --- | --- | --- | --- |
| `air` | 01 | `air.js` | є |
| `airmissile` | 02 | `air.js` | є |
| `space` | 05 | `space.js` | є |
| `spacemissile` | 06 | `space.js` | є |
| `landunit` | 10 | `ground.js` | є |
| `landcivilian` | 11 | `ground.js` | є |
| `landequipment` | 15 | `ground.js` | є |
| `landinstallation` | 20 | `ground.js` | є |
| `sea` | 30 | `sea.js` | є |
| `subsurface` | 35 | `subsurface.js` | є |
| `minewarfare` | 36 | `subsurface.js` | є |
| `activites` | 40 | `ground.js` | є |
| `signalsintelligence` | 50–54 | `signals-intelligence.js` | є |
| `dismountedindividual` | 27 | `ground.js` | є |
| `tacticalpoints` (`control-measure.js`) | 25 | `tactical-points.js`, підписи `numbersidc/labels/tactical-points.js` | є |
| `cyberspace` | 60 | `ground.js` (частини `CY.*`) | є |
| `common` | модифікатори 2525E | `common-modifiers.js` | є |

Порядок для набору `air` (для решти так само):

1. Частини іконок, якщо файлу ще немає в `lib/src/iconparts/`:
   ```bash
   node tools/symbols-reference/convert.mjs iconparts /tmp/milsymbol/package/src/iconparts/air.js airIconParts > packages/horyzontal_symbols/lib/src/iconparts/air.dart
   ```
2. Таблиця SIDC:
   ```bash
   node tools/symbols-reference/convert.mjs sidc /tmp/milsymbol/package/src/numbersidc/sidc/air.js airIcons > packages/horyzontal_symbols/lib/src/numbersidc/sidc/air.dart
   ```
3. `dart format --line-length 100` і `dart analyze` для нових файлів, ручні правки (див. вище).
   У шапці файлу лишається `// Ported from milsymbol <шлях>, MIT`; якщо правили вручну, замініть
   `hand edits: none` коротким списком правок.
4. У `lib/src/numbersidc.dart` оголосити модуль
   (`const air = SymbolSetModule(name: 'air', symbolSets: ['01'], iconParts: airIconParts, icons: airIcons);`,
   для `tacticalpoints` ще `labels:`) і розкоментувати його в `app6d`, `std2525d` і `std2525e` на
   тому самому місці, де він стоїть у milsymbol. Більше нічого в ядрі змінювати не потрібно: ядро бере частини й
   таблиці із зареєстрованих модулів, а для незареєстрованих наборів малює рамку зі знаком
   питання milsymbol (`isValid == false`).
5. У `generate.mjs` додати ім'я модуля в `PORTED` і розкоментувати (або додати) сімейство в
   `FAMILIES`; за потреби задати сутність для модифікаторів у `REPRESENTATIVE`.
6. Перезібрати **всі** фікстури й прогнати `dart test`: усі файли мають збігтися на 100 %. Нові
   частини іконок можуть законно змінити вивід уже перенесених наборів (посилання між модулями,
   перевизначення ключів), тому порівнювати треба весь корпус, а не лише новий файл.

Особливі випадки: у `minewarfare` (36) є опція `alternateMedal`; у заходів керування (25) підписи
через `labels` (`numbersidc/labels/tactical-points.js` перенести як `LabelOverridesFunction` і
додати в корпус варіанти з текстовими полями, зокрема з ключами на кшталт `uniqueDesignation1`, інакше
`labelOverride` не виконається) і типи інструкцій `clip` і `svg` (в `assvg.dart` уже перенесено, але
корпусом поки не перевірено); `cyberspace` використовує частини з `ground.dart`, потрібна лише таблиця.
Пробне конвертування всіх решти файлів збирається, крім одного рядка в `tactical-points.js`
(`if (metadata.notpresent)` → `if (truthy(metadata.notpresent))`); компіляція ще не означає
збігу, перевіряє лише повний корпус.
