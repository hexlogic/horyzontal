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
  String get errDistance => 'Вкажіть відстань у метрах';

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
  String get ellipsoidNote =>
      'Геодезична лінія на еліпсоїді WGS 84, азимути від істинної півночі';

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
      'Магнітне поле: World Magnetic Model WMM2025, NOAA NCEI і BGS. Геоїд: EGM2008, NGA. Геодезичні задачі: алгоритми C. F. F. Karney (GeographicLib, MIT).';
}
