# Спайк этапа 0

Одноразовое приложение, чтобы снять три технических риска до основной работы
(см. [docs/spec.md](../docs/spec.md), раздел «Этапы»). Код отсюда в основное приложение
переносится выборочно, само приложение не развивается.

- **Мапа:** онлайн OpenFreeMap и офлайн PMTiles (Protomaps) с холмистостью из DEM-пакета;
  тап — высота точки, два долгих нажатия — профиль высот.
- **Передача:** Android поднимает LocalOnlyHotspot и показывает QR; второе устройство
  сканирует, подключается к точке и получает тестовый файл по TCP с AES-256-GCM.

## Сборка

```bash
cd spike && flutter pub get
```

```bash
flutter build apk --debug
```

```bash
flutter build ios --debug
```

iOS: нужен платный аккаунт Apple Developer — capability *Hotspot Configuration*
(`Runner.entitlements`) бесплатной команде недоступна. Выберите свою команду в Xcode
(`ios/Runner.xcworkspace` → Signing & Capabilities) и добавьте там же Hotspot Configuration.

## Пакеты карт

Собираются в `tools/map-pipeline` (`./build_region.sh kyiv`), получаются
`out/kyiv.pmtiles` и `out/kyiv-dem.pmtiles`.

- **iPhone:** Finder → устройство → Файлы → «Горизонталь спайк» → перетащить оба файла
  (приложение ищет пакеты в `Documents` и `Documents/packs`) или кнопка импорта на экране «Мапа».
- **Android:** скопировать на телефон и импортировать кнопкой на экране «Мапа», либо для
  debug-сборки: `adb push` + `run-as com.synckord.horyzontal.spike cp … app_flutter/packs/`.

## Автотест без касаний экрана

Release-сборка выполняет задание и пишет результат в `Documents/autotest.log` и в консоль
(`[autotest]`), см. `lib/autotest.dart`:

```bash
xcrun devicectl device copy to --device <udid> --domain-type appDataContainer --domain-identifier com.synckord.horyzontal.spike --source task.json --destination Documents/autotest.json
```

```bash
adb shell am start -S -n com.synckord.horyzontal.spike/.MainActivity --es autotest "'{\"do\":\"map\",\"bench\":true}'"
```

Задания: `{"do":"map","lat":…,"lon":…,"zoom":…,"bench":true}`,
`{"do":"host","send":true,"mb":10,"hotspot":true}`, `{"do":"client","invite":"…","mb":10}`.
Системные запросы iOS («Подключиться к сети?») все равно нажимает человек.

## Чек-лист на реальных устройствах

Пройден 12.10.2026 на iPhone 16 Pro Max (iOS 27) и POCO F3 (Android 16), результаты —
в [docs/stage0-spike.md](../docs/stage0-spike.md).

**Карта (iPhone и Android):**

- [x] Авиарежим, «Офлайн»: карта Киевской области рисуется, подписи украинские
- [x] Холмистость видна; диагональных полос, как в эмуляторе, нет
- [x] Высоты совпадают с Copernicus (среднее 0.22 м, максимум 1.18 м)
- [x] Профиль 256 точек быстрее 300 мс в release (36–276 мс холодный, <1 мс повторно)
- [x] Сворачивание и возврат без вылетов
- [ ] Плавность на z14–15 — визуально нормально, но кадры в секунду не измерены

**Передача (Android-хост и iPhone):**

- [x] Android поднимает точку и показывает QR
- [x] iPhone сканирует QR, подключается, передача 10–100 МБ, sha256 совпали
- [x] Обратное направление: iPhone отправляет, Android принимает
- [ ] 2–3 Android других производителей и Android 8–12 (было одно устройство)
- [ ] Android ↔ Android через WifiNetworkSpecifier (нужен второй Android)
- [ ] Автоповтор подключения на iOS в момент реального сбоя (сбой 2 из 12, в контрольной серии не случился)
