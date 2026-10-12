// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Горизонталь';

  @override
  String get tabTasks => 'Завдання';

  @override
  String get tabCompass => 'Компас';

  @override
  String get tabSettings => 'Налаштування';

  @override
  String get copied => 'Скопійовано';

  @override
  String get copy => 'Копіювати';

  @override
  String get share => 'Поділитися';

  @override
  String get paste => 'Вставити';

  @override
  String get myLocation => 'Моє місце';

  @override
  String get cancel => 'Скасувати';

  @override
  String get clear => 'Очистити';

  @override
  String get sysWgs84 => 'WGS 84';

  @override
  String get sysUtm => 'UTM';

  @override
  String get sysMgrs => 'MGRS';

  @override
  String get sysSk42 => 'СК-42, геодезичні';

  @override
  String get sysSk42Gk => 'СК-42, прямокутні';

  @override
  String get sysUsk2000 => 'УСК-2000, геодезичні';

  @override
  String get sysUsk2000Gk => 'УСК-2000, прямокутні 6°';

  @override
  String get sysUsk2000Tm3 => 'УСК-2000, ТМ 3°';

  @override
  String get hintGeographic => '50.4501, 30.5234 або 50°27\'00\"N 30°31\'24\"E';

  @override
  String get hintUtm => '36U 324182 5591608';

  @override
  String get hintMgrs => '36U UA 24182 91607';

  @override
  String get hintGrid => 'X 5593957  Y 6324233';

  @override
  String get hintTm3 => 'X 5591157  Y 337291';

  @override
  String get geoDegrees => 'Градуси';

  @override
  String get geoDegMin => 'Градуси, мінути';

  @override
  String get geoDms => 'Градуси, мінути, секунди';

  @override
  String get angleDeg360 => 'Градуси 360°';

  @override
  String get angleMils6000 => 'Поділки 60-00';

  @override
  String get angleMils6400 => 'Тисячні 64-00';

  @override
  String get angleDms => 'Градуси, мінути, секунди';

  @override
  String get errUnrecognized => 'Не вдалося розпізнати координати';

  @override
  String get errOutOfRange => 'Координати поза допустимими межами';

  @override
  String get errMissingZone => 'Вкажіть зону';

  @override
  String get errOutsideSystem => 'Точка поза областю системи';

  @override
  String get errAngle => 'Не вдалося розпізнати кут';

  @override
  String get errDistance => 'Вкажіть відстань';

  @override
  String get errLocation => 'Немає доступу до геолокації';

  @override
  String get zone => 'Зона';

  @override
  String zoneValue(int zone) {
    return 'зона $zone';
  }

  @override
  String get neighbourZone => 'Сусідня зона';

  @override
  String get taskConverter => 'Конвертер координат';

  @override
  String get taskConverterSubtitle => 'WGS 84, СК-42, УСК-2000, UTM, MGRS';

  @override
  String get taskAngles => 'Конвертер кутів';

  @override
  String get taskAnglesSubtitle => '360°, 60-00, 64-00, Г°М′С″';

  @override
  String get taskDirect => 'Пряма геодезична задача';

  @override
  String get taskDirectSubtitle => 'Точка, відстань і кут → нова точка';

  @override
  String get taskInverse => 'Обернена геодезична задача';

  @override
  String get taskInverseSubtitle => 'Дві точки → відстань і кути';

  @override
  String get inputSystem => 'Система координат';

  @override
  String get coordinates => 'Координати';

  @override
  String get results => 'У всіх системах';

  @override
  String get angle => 'Кут';

  @override
  String get inputFormat => 'Формат введення';

  @override
  String get outputFormat => 'Формат виведення';

  @override
  String get startPoint => 'Початкова точка';

  @override
  String get endPoint => 'Кінцева точка';

  @override
  String get point1 => 'Точка 1';

  @override
  String get point2 => 'Точка 2';

  @override
  String get distanceM => 'Відстань, м';

  @override
  String get distance => 'Відстань';

  @override
  String get gridBearing => 'Дирекційний кут';

  @override
  String get backGridBearing => 'Зворотний дирекційний кут';

  @override
  String get azimuth => 'Азимут';

  @override
  String get backAzimuth => 'Зворотний азимут';

  @override
  String get magneticAzimuth => 'Магнітний азимут';

  @override
  String get trueAzimuth => 'Істинний азимут';

  @override
  String get backTrueAzimuth => 'Зворотний істинний азимут';

  @override
  String get backMagneticAzimuth => 'Зворотний магнітний азимут';

  @override
  String get angleKind => 'Вид кута';

  @override
  String get directionCorrection => 'Поправка напрямку';

  @override
  String get planeFrame => 'Прямокутна сітка';

  @override
  String get frameAuto => 'Автоматично';

  @override
  String get frameAutoNote => 'авто';

  @override
  String get gridDistance => 'Відстань на площині';

  @override
  String get ellipsoidDistance => 'Відстань на еліпсоїді';

  @override
  String get scaleFactor => 'Масштаб сітки';

  @override
  String get groundDistance => 'Відстань на місцевості';

  @override
  String get groundDistanceHint =>
      'Переводиться на площину з урахуванням масштабу сітки';

  @override
  String get unitM => 'м';

  @override
  String get unitKm => 'км';

  @override
  String get method => 'Метод';

  @override
  String get methodPlane => 'Площина';

  @override
  String get methodEllipsoid => 'Еліпсоїд';

  @override
  String planeGrid(String grid, String zone) {
    return 'Площина $grid, $zone';
  }

  @override
  String get ellipsoidNote => 'Геодезична лінія на еліпсоїді WGS 84';

  @override
  String metres(String value) {
    return '$value м';
  }

  @override
  String kilometres(String value) {
    return '$value км';
  }

  @override
  String get compassMagnetic => 'Магнітна північ';

  @override
  String get compassTrue => 'Істинна північ';

  @override
  String get compassGrid => 'Північ сітки';

  @override
  String get declination => 'Магнітне схилення';

  @override
  String get convergence => 'Зближення меридіанів';

  @override
  String get altitude => 'Висота';

  @override
  String altitudeMsl(String value) {
    return '$value м над рівнем моря';
  }

  @override
  String altitudeEllipsoid(String value) {
    return '$value м над еліпсоїдом';
  }

  @override
  String accuracy(String value) {
    return '±$value м';
  }

  @override
  String get locating => 'Визначення місця…';

  @override
  String get trueNorthNeedsLocation =>
      'Істинна північ з\'явиться після визначення місця, зараз показано магнітну';

  @override
  String get noCompass => 'На пристрої немає компаса';

  @override
  String get compassLowAccuracy =>
      'Низька точність компаса. Відкалібруйте: поводіть телефоном вісімкою, подалі від металу й техніки.';

  @override
  String compassAccuracy(String value) {
    return 'Похибка компаса ±$value°';
  }

  @override
  String get wmmExpired =>
      'Модель магнітного поля WMM2025 діє до 2030 року, схилення може бути неточним';

  @override
  String get locationDenied =>
      'Дозвольте доступ до геолокації, щоб бачити координати й істинну північ';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get settingsCoordinates => 'Координати й кути';

  @override
  String get defaultSystem => 'Система координат за замовчуванням';

  @override
  String get geoFormat => 'Формат географічних координат';

  @override
  String get angleInput => 'Формат кутів: введення';

  @override
  String get angleOutput => 'Формат кутів: виведення';

  @override
  String get callsign => 'Позивний';

  @override
  String get callsignHint => 'Підписує ваші точки, коли ними діляться';

  @override
  String get theme => 'Тема';

  @override
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get settingsSecurity => 'Безпека';

  @override
  String get pinCode => 'PIN-код';

  @override
  String get pinOn => 'Увімкнено';

  @override
  String get pinOff => 'Вимкнено';

  @override
  String get pinEnable => 'Встановити PIN-код';

  @override
  String get pinChange => 'Змінити PIN-код';

  @override
  String get pinDisable => 'Вимкнути PIN-код';

  @override
  String get biometrics => 'Біометрія';

  @override
  String get biometricsSubtitle =>
      'Розблокування Face ID, Touch ID або відбитком';

  @override
  String get lockAfter => 'Блокувати після виходу';

  @override
  String get lockImmediately => 'Одразу';

  @override
  String lockSeconds(int n) {
    return 'Через $n с';
  }

  @override
  String lockMinutes(int n) {
    return 'Через $n хв';
  }

  @override
  String get about => 'Про застосунок';

  @override
  String get pinEnter => 'Введіть PIN-код';

  @override
  String get pinNew => 'Новий PIN-код';

  @override
  String get pinRepeat => 'Повторіть PIN-код';

  @override
  String get pinCurrent => 'Поточний PIN-код';

  @override
  String get pinMismatch => 'PIN-коди не збігаються';

  @override
  String get pinWrong => 'Невірний PIN-код';

  @override
  String pinWait(int seconds) {
    return 'Забагато спроб. Зачекайте $seconds с';
  }

  @override
  String get pinSet => 'PIN-код встановлено';

  @override
  String get pinRemoved => 'PIN-код вимкнено';

  @override
  String get biometricReason => 'Розблокуйте Горизонталь';

  @override
  String get unlockBiometric => 'Біометрія';

  @override
  String get deleteDigit => 'Стерти';

  @override
  String get aboutDescription =>
      'Безкоштовний застосунок з відкритим кодом для роботи з координатами в полі. Працює без інтернету й нікуди не надсилає ваші дані.';

  @override
  String aboutVersion(String version) {
    return 'Версія $version';
  }

  @override
  String get aboutLicense => 'Відкритий вихідний код, ліцензія GPL-3.0.';

  @override
  String get aboutTransforms => 'Перехід між системами';

  @override
  String get aboutTransformsText =>
      'СК-42 → WGS 84: EPSG:15865 (точність близько 4 м). УСК-2000 → WGS 84: EPSG:7817 (близько 1 м). Єдиного офіційного набору параметрів для СК-42 в Україні немає, різні програми можуть розходитися на 1–3 м.';

  @override
  String get aboutData => 'Дані й алгоритми';

  @override
  String get aboutDataText =>
      'Мапа: © учасники OpenStreetMap (ODbL), OpenFreeMap, Protomaps. Висоти: Copernicus DEM GLO-30 © DLR e.V. 2010–2014 і © Airbus Defence and Space GmbH 2014–2018, надано в рамках COPERNICUS Європейським Союзом та ESA. Магнітне поле: World Magnetic Model WMM2025, NOAA NCEI і BGS. Геоїд: EGM2008, NGA. Геодезичні задачі: алгоритми C. F. F. Karney (GeographicLib, MIT). Умовні знаки: milsymbol © Måns Beckman (MIT), каталог кодів за Esri Joint Military Symbology XML (Apache-2.0).';

  @override
  String get tabMap => 'Мапа';

  @override
  String get tabJournal => 'Журнал';

  @override
  String get addPointHere => 'Додати точку';

  @override
  String get altitudeM => 'Висота, м';

  @override
  String get appleMaps => 'Apple Maps';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get otherMapsApp => 'Інший застосунок карт';

  @override
  String get archive => 'Архів';

  @override
  String get archiveEmpty => 'В архіві немає шарів';

  @override
  String get author => 'Автор';

  @override
  String get baseMap => 'Основа мапи';

  @override
  String get close => 'Закрити';

  @override
  String get defaultLayerName => 'Мої об\'єкти';

  @override
  String get delete => 'Видалити';

  @override
  String get deleteLayer => 'Видалити шар';

  @override
  String get deleteObjectQuestion => 'Видалити об\'єкт?';

  @override
  String get description => 'Опис';

  @override
  String get distanceAzimuthFromMe => 'Від мене: відстань · азимут';

  @override
  String get donate => 'Підтримати проєкт';

  @override
  String get donateHint => 'Банка monobank';

  @override
  String get download => 'Завантажити';

  @override
  String get downloadFailed => 'не вдалося завантажити';

  @override
  String get edit => 'Редагувати';

  @override
  String get emergencyWipe => 'Екстрене видалення';

  @override
  String get emergencyWipeHint => 'Стерти всі дані на цьому пристрої';

  @override
  String get encrypt => 'Зашифрувати';

  @override
  String get encryptQuestion => 'Зашифрувати файл паролем?';

  @override
  String get encryptText =>
      'Без пароля файл прочитає будь-хто, хто його отримає. Пароль передайте іншим каналом.';

  @override
  String get noEncryption => 'Без шифрування';

  @override
  String get exportFormats => '.hrz, KML, KMZ, GPX, CoT, пакет ATAK';

  @override
  String get exportLayer => 'Експорт шару';

  @override
  String get exportPassword => 'Пароль для файлу';

  @override
  String get formatAtakHint =>
      'Zip для ATAK: точки як CoT, лінії й полігони як KML';

  @override
  String get formatAtakPackage => 'Пакет даних ATAK';

  @override
  String get formatCotHint => 'Точки для ATAK і WinTAK';

  @override
  String get formatGpxHint => 'Навігатори, OsmAnd, Garmin';

  @override
  String get formatHrz => 'Горизонталь (.hrz)';

  @override
  String get formatHrzHint =>
      'Без втрат, для іншої Горизонталі; можна з паролем';

  @override
  String get formatKmlHint => 'Google Earth, ATAK, OsmAnd, QGIS';

  @override
  String get hidden => 'прихований';

  @override
  String get importAction => 'Імпортувати';

  @override
  String get importFile => 'Імпорт файлу';

  @override
  String get importPack => 'Імпорт пакета';

  @override
  String get importPassword => 'Файл зашифровано. Пароль';

  @override
  String get importQuestion => 'Імпортувати шари?';

  @override
  String get journalEmpty =>
      'Тут з\'являться точки, лінії й полігони. Довге натискання на мапі створює точку.';

  @override
  String get kindPoint => 'Точка';

  @override
  String get kindPoints => 'Точки';

  @override
  String get kindPolygon => 'Полігон';

  @override
  String get kindPolygons => 'Полігони';

  @override
  String get kindPolyline => 'Полілінія';

  @override
  String get kindPolylines => 'Полілінії';

  @override
  String get layer => 'Шар';

  @override
  String get layerName => 'Назва шару';

  @override
  String get layers => 'Шари';

  @override
  String get manageLayers => 'Керувати';

  @override
  String get mapLayers => 'Шари мапи';

  @override
  String get mapOffline => 'Офлайн';

  @override
  String get mapOnline => 'Онлайн';

  @override
  String get name => 'Назва';

  @override
  String get newLayer => 'Новий шар';

  @override
  String get newPoint => 'Нова точка';

  @override
  String get newPolyline => 'Нова полілінія';

  @override
  String get newPolygon => 'Новий полігон';

  @override
  String get interiorAngle => 'Внутрішній кут';

  @override
  String get noLayers => 'Шарів ще немає';

  @override
  String get noMapsApp => 'Немає застосунку карт для маршруту';

  @override
  String get noPacksHint =>
      'Завантажте область, щоб мапа працювала без інтернету';

  @override
  String get noPacksOffline =>
      'Імпортуйте файл пакета або вимкніть режим «Тільки офлайн»';

  @override
  String get noPacksTitle => 'Немає офлайн-пакетів';

  @override
  String get nothingFound => 'Нічого не знайдено';

  @override
  String get object => 'Об\'єкт';

  @override
  String get offlinePacks => 'Офлайн-пакети карт';

  @override
  String get packNoHeights => 'без висот';

  @override
  String get packNotAvailable => 'недоступно для завантаження';

  @override
  String get packUpdate => 'Оновити';

  @override
  String get packsAttribution =>
      'Карта: © учасники OpenStreetMap (ODbL), Protomaps. Висоти: Copernicus DEM GLO-30 © DLR, Airbus, ESA. Пакети з github.com/hexlogic/horyzontal.';

  @override
  String get packsLoading => 'Перевіряю доступні пакети…';

  @override
  String get packsManifestError =>
      'Список пакетів недоступний (немає мережі?). Можна імпортувати файл.';

  @override
  String get packsOfflineOnly => 'Режим «Тільки офлайн»: завантаження вимкнено';

  @override
  String get packsOther => 'Інші файли';

  @override
  String get password => 'Пароль';

  @override
  String get passwordHint => 'Щонайменше 8 символів';

  @override
  String get privacyOfflineOnly => 'Тільки офлайн';

  @override
  String get privacyOk => 'Зрозуміло';

  @override
  String get privacyTitle => 'Приватність';

  @override
  String get privacyText =>
      'Горизонталь не має аналітики, реклами й облікових записів, а ваші об\'єкти зберігаються лише на пристрої, зашифрованими.\n\nОнлайн-мапа завантажує тайли з OpenFreeMap: за запитами провайдер бачить приблизний район, який ви переглядаєте. Якщо це неприйнятно, увімкніть режим «Тільки офлайн» і користуйтеся завантаженими пакетами областей. Режим можна змінити в налаштуваннях.';

  @override
  String get qrCode => 'QR-код';

  @override
  String get qrNotAPoint => 'Це не QR-код точки Горизонталі';

  @override
  String get radius => 'Радіус';

  @override
  String get radiusM => 'Радіус, м';

  @override
  String get receiveWifi => 'Отримати по Wi-Fi';

  @override
  String get renameLayer => 'Перейменувати';

  @override
  String get route => 'Маршрут';

  @override
  String get save => 'Зберегти';

  @override
  String get saveToLayer => 'Зберегти в шар';

  @override
  String get scanQr => 'Сканувати QR';

  @override
  String get scanQrHint => 'Наведіть камеру на QR-код точки';

  @override
  String get screenshotProtection => 'Заборонити знімки екрана';

  @override
  String get screenshotProtectionHint =>
      'Також приховує вміст у переліку застосунків';

  @override
  String get searchByName => 'Пошук за назвою';

  @override
  String get searchCoordinates => 'Пошук за координатами';

  @override
  String get sendWifi => 'Передати по Wi-Fi';

  @override
  String get showOnMap => 'Показати на мапі';

  @override
  String get swipeToHide =>
      'Проведіть шар убік, щоб сховати або показати його на мапі. Довге натискання — вибрати кілька шарів для експорту чи передачі.';

  @override
  String get symbol => 'Умовний знак';

  @override
  String get symbolNone => 'Без знака';

  @override
  String get toArchive => 'В архів';

  @override
  String get unarchive => 'З архіву';

  @override
  String get unnamed => 'Без назви';

  @override
  String get whatsNew => 'Що нового';

  @override
  String get settingsMap => 'Мапа';

  @override
  String get offlineOnly => 'Тільки офлайн';

  @override
  String get offlineOnlyHint =>
      'Жодних мережевих запитів: ні онлайн-мапи, ні завантаження пакетів';

  @override
  String get wipeHold => 'Утримуйте 3 секунди, щоб стерти';

  @override
  String get wipePacks => 'Також видалити офлайн-пакети карт';

  @override
  String get wipeText =>
      'Буде стерто базу з усіма шарами й об\'єктами, ключ шифрування, PIN-код, налаштування, кеш мапи, експортовані й отримані файли. Відновити це неможливо. Застосунок закриється.';

  @override
  String get wrongPassword => 'Невірний пароль';

  @override
  String get transferBadQr => 'Це не запрошення до передачі Горизонталі';

  @override
  String get transferBothReceive =>
      'Обидва пристрої чекають на отримання. На одному з них оберіть передачу.';

  @override
  String get transferBothSend =>
      'Обидва пристрої передають. На одному з них оберіть отримання.';

  @override
  String get transferChecksum =>
      'Дані пошкоджено під час передачі, спробуйте ще раз';

  @override
  String get transferConnecting => 'Підключаюся…';

  @override
  String get transferDeclined => 'Імпорт скасовано';

  @override
  String get transferLayersToSend => 'Шари для передачі';

  @override
  String get transferHowTo =>
      'QR показує один телефон, інший сканує. Якщо один з телефонів Android — QR показує Android: iPhone не вміє створювати точку доступу. Між двома iPhone працює напряму, без мережі. Дані шифруються ключем з QR-коду.';

  @override
  String get transferNeedsIphone =>
      'Цей QR-код для передачі між двома iPhone. Покажіть QR на цьому пристрої.';

  @override
  String get transferPermission => 'Потрібен дозвіл на роботу з Wi-Fi';

  @override
  String get transferReceiving => 'Отримую шари…';

  @override
  String get transferSameNetwork => 'Обидва в одній мережі Wi-Fi';

  @override
  String get transferSameNetworkHint =>
      'Без точки доступу: через спільний роутер';

  @override
  String get transferScanButton => 'Сканувати QR іншого телефона';

  @override
  String get transferSending => 'Передаю шари…';

  @override
  String get transferSent => 'Шари передано';

  @override
  String get transferShowQr => 'Відскануйте цей QR на іншому телефоні';

  @override
  String get transferShowQrButton => 'Показати QR';

  @override
  String get transferStarting => 'Запускаю…';

  @override
  String created(String date) {
    return 'Створено $date';
  }

  @override
  String updated(String date) {
    return 'змінено $date';
  }

  @override
  String deleteLayerQuestion(String name) {
    return 'Видалити шар «$name»?';
  }

  @override
  String deleteLayerText(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Разом з ним буде видалено $n об\'єкта.',
      many: 'Разом з ним буде видалено $n об\'єктів.',
      few: 'Разом з ним буде видалено $n об\'єкти.',
      one: 'Разом з ним буде видалено $n об\'єкт.',
      zero: 'У шарі немає об\'єктів.',
    );
    return '$_temp0';
  }

  @override
  String deletePackQuestion(String name) {
    return 'Видалити пакет «$name»?';
  }

  @override
  String downloading(String received, String total) {
    return '$received з $total';
  }

  @override
  String gigabytes(String value) {
    return '$value ГБ';
  }

  @override
  String megabytes(String value) {
    return '$value МБ';
  }

  @override
  String importFailed(String name) {
    return 'Не вдалося імпортувати $name';
  }

  @override
  String importWarnings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n елемента пропущено',
      many: '$n елементів пропущено',
      few: '$n елементи пропущено',
      one: '$n елемент пропущено',
    );
    return '$_temp0';
  }

  @override
  String imported(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Імпортовано $n об\'єкта',
      many: 'Імпортовано $n об\'єктів',
      few: 'Імпортовано $n об\'єкти',
      one: 'Імпортовано $n об\'єкт',
    );
    return '$_temp0';
  }

  @override
  String notAPack(String name) {
    return '$name не є пакетом PMTiles';
  }

  @override
  String objectsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n об\'єкта',
      many: '$n об\'єктів',
      few: '$n об\'єкти',
      one: '$n об\'єкт',
    );
    return '$_temp0';
  }

  @override
  String packImported(String name) {
    return 'Пакет $name додано';
  }

  @override
  String packsBuild(String build) {
    return 'Збірка карт $build';
  }

  @override
  String packsInstalled(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n області',
      many: '$n областей',
      few: '$n області',
      one: '$n область',
      zero: 'Не встановлено',
    );
    return '$_temp0';
  }

  @override
  String packsSummary(int n, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n файлу, $size',
      many: '$n файлів, $size',
      few: '$n файли, $size',
      one: '$n файл, $size',
      zero: 'Немає файлів',
    );
    return '$_temp0';
  }

  @override
  String transferFailed(String error) {
    return 'Не вдалося: $error';
  }

  @override
  String transferJoinFailed(String ssid, String psk) {
    return 'Не вдалося підключитися до мережі $ssid. Підключіться вручну в налаштуваннях Wi-Fi, пароль: $psk';
  }

  @override
  String transferManual(String ssid, String psk) {
    return 'Якщо не підключається: мережа $ssid, пароль $psk';
  }

  @override
  String vertices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n вершини',
      many: '$n вершин',
      few: '$n вершини',
      one: '$n вершина',
    );
    return '$_temp0';
  }

  @override
  String get tools => 'Інструменти';

  @override
  String get toolRuler => 'Лінійка';

  @override
  String get toolPolyline => 'Полілінія';

  @override
  String get toolPolygon => 'Полігон';

  @override
  String get toolProfile => 'Профіль висот';

  @override
  String get toolLos => 'Видимість';

  @override
  String get toolHint =>
      'Наведіть перехрестя і натисніть «Точка» або торкніться карти';

  @override
  String get addPoint => 'Точка';

  @override
  String get undoPoint => 'Прибрати останню точку';

  @override
  String get clearPoints => 'Почати заново';

  @override
  String get closeTool => 'Закрити інструмент';

  @override
  String get length => 'Довжина';

  @override
  String get perimeter => 'Периметр';

  @override
  String get area => 'Площа';

  @override
  String get lastSegment => 'Останній відрізок';

  @override
  String get toCrosshair => 'До перехрестя';

  @override
  String get backShort => 'зворотний';

  @override
  String get vertexAngle => 'Кут при вершині';

  @override
  String get deviation => 'Відхилення перехрестя';

  @override
  String get deltaXY => 'Прирости';

  @override
  String get heightDiff => 'Перевищення';

  @override
  String get angleKindCycle => 'Змінити вид кута';

  @override
  String rangeOver(String value) {
    return 'переліт $value';
  }

  @override
  String rangeShort(String value) {
    return 'недоліт $value';
  }

  @override
  String deviationRight(String value) {
    return 'вправо $value';
  }

  @override
  String deviationLeft(String value) {
    return 'вліво $value';
  }

  @override
  String squareMetres(String value) {
    return '$value м²';
  }

  @override
  String hectares(String value) {
    return '$value га';
  }

  @override
  String squareKm(String value) {
    return '$value км²';
  }

  @override
  String get buildTool => 'Побудувати';

  @override
  String get heightRange => 'Висота, мін / макс';

  @override
  String get ascentDescent => 'Набір / спуск висоти';

  @override
  String get noDemPack => 'Немає пакета висот для цього району';

  @override
  String get noDemPackHint =>
      'Завантажте область: пакет висот іде разом із мапою';

  @override
  String get demGaps => 'Частина лінії поза пакетами висот';

  @override
  String get demSurfaceNote =>
      'Висоти Copernicus DEM — модель поверхні: вони включають ліс і будівлі';

  @override
  String atDistance(String value) {
    return 'На відстані $value';
  }

  @override
  String get losVisible => 'Пряма видимість є';

  @override
  String losBlocked(String value) {
    return 'Перешкода на відстані $value від A';
  }

  @override
  String get minClearance => 'Найменший просвіт над перешкодою';

  @override
  String get mastA => 'Щогла A, м';

  @override
  String get mastB => 'Щогла B, м';

  @override
  String get refraction => 'Рефракція';

  @override
  String get refractionNone => 'Без рефракції';

  @override
  String get refractionOptical => 'Оптична, k = 0.13';

  @override
  String get refractionRadio => 'Радіо, 4/3 Землі';

  @override
  String get frequencyMhz => 'Частота, МГц (для зони Френеля)';

  @override
  String get fresnelClear => 'Перша зона Френеля вільна щонайменше на 60%';

  @override
  String fresnelBlocked(String value) {
    return 'Перша зона Френеля перекрита: просвіт $value% радіуса';
  }

  @override
  String get pointA => 'Точка A';

  @override
  String get pointB => 'Точка B';

  @override
  String get cameraUnavailable =>
      'Камера недоступна. Перевірте дозвіл на камеру в системних налаштуваннях.';

  @override
  String get favorite => 'В обране';

  @override
  String get favorites => 'Обране';

  @override
  String get recent => 'Нещодавні';

  @override
  String get symbolSearch => 'Пошук знака: піхота, танк, міномет…';

  @override
  String get sidcIdentity => 'Належність';

  @override
  String get sidcSet => 'Набір знаків';

  @override
  String get sidcEntity => 'Тип';

  @override
  String get sidcEntityNone => 'Не вибрано';

  @override
  String get sidcStatus => 'Стан';

  @override
  String get sidcHq => 'Штаб, тактична група, макет';

  @override
  String get sidcEchelon => 'Ешелон';

  @override
  String get sidcMobility => 'Рухомість';

  @override
  String get sidcModifier1 => 'Модифікатор 1';

  @override
  String get sidcModifier2 => 'Модифікатор 2';

  @override
  String sidcChooseThis(String name) {
    return 'Вибрати «$name»';
  }

  @override
  String get cardinalN => 'Пн';

  @override
  String get cardinalE => 'Сх';

  @override
  String get cardinalS => 'Пд';

  @override
  String get cardinalW => 'Зх';

  @override
  String get angleDmsShort => 'Г°М′С″';

  @override
  String get notes030 =>
      'Інструменти мапи: лінійка з відхиленнями, полілінії з кутами, полігони з площею, профіль висот, видимість між точками з висотою щогл і зоною Френеля\nПолілінії й полігони можна малювати й зберігати; у картці — довжина, площа й кути при вершинах\nПГЗ і ОГЗ: дирекційний кут, істинний і магнітний азимут, вибір сітки й зони (зокрема UTM), відстань у кілометрах і на місцевості\nСканер QR на ZXing замість Google ML Kit: жодних метрик до Google';

  @override
  String get notes020 =>
      'Мапа: онлайн OpenFreeMap і офлайн-пакети областей з рельєфом, кілька пакетів одночасно\nОб\'єкти з умовними знаками НАТО APP-6, шари, журнал з фільтрами й пошуком\nОбмін: QR для точок, шари по Wi-Fi без інтернету, файли .hrz, KML/KMZ, GPX, CoT і пакети даних ATAK\nБезпека: розмиття в перемикачі застосунків, заборона знімків екрана (Android), екстрене видалення, режим «Тільки офлайн»';

  @override
  String get notes010 =>
      'Конвертер координат WGS 84, СК-42, УСК-2000, UTM, MGRS і кутів\nПряма й обернена геодезичні задачі, компас з істинною північчю\nPIN-код, біометрія, зашифрована база';

  @override
  String selectedCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Вибрано $n шару',
      many: 'Вибрано $n шарів',
      few: 'Вибрано $n шари',
      one: 'Вибрано $n шар',
    );
    return '$_temp0';
  }
}
