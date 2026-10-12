import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('uk')];

  /// No description provided for @appTitle.
  ///
  /// In uk, this message translates to:
  /// **'Горизонталь'**
  String get appTitle;

  /// No description provided for @tabTasks.
  ///
  /// In uk, this message translates to:
  /// **'Завдання'**
  String get tabTasks;

  /// No description provided for @tabCompass.
  ///
  /// In uk, this message translates to:
  /// **'Компас'**
  String get tabCompass;

  /// No description provided for @tabSettings.
  ///
  /// In uk, this message translates to:
  /// **'Налаштування'**
  String get tabSettings;

  /// No description provided for @copied.
  ///
  /// In uk, this message translates to:
  /// **'Скопійовано'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In uk, this message translates to:
  /// **'Копіювати'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In uk, this message translates to:
  /// **'Поділитися'**
  String get share;

  /// No description provided for @paste.
  ///
  /// In uk, this message translates to:
  /// **'Вставити'**
  String get paste;

  /// No description provided for @myLocation.
  ///
  /// In uk, this message translates to:
  /// **'Моє місце'**
  String get myLocation;

  /// No description provided for @cancel.
  ///
  /// In uk, this message translates to:
  /// **'Скасувати'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In uk, this message translates to:
  /// **'Очистити'**
  String get clear;

  /// No description provided for @sysWgs84.
  ///
  /// In uk, this message translates to:
  /// **'WGS 84'**
  String get sysWgs84;

  /// No description provided for @sysUtm.
  ///
  /// In uk, this message translates to:
  /// **'UTM'**
  String get sysUtm;

  /// No description provided for @sysMgrs.
  ///
  /// In uk, this message translates to:
  /// **'MGRS'**
  String get sysMgrs;

  /// No description provided for @sysSk42.
  ///
  /// In uk, this message translates to:
  /// **'СК-42, геодезичні'**
  String get sysSk42;

  /// No description provided for @sysSk42Gk.
  ///
  /// In uk, this message translates to:
  /// **'СК-42, прямокутні'**
  String get sysSk42Gk;

  /// No description provided for @sysUsk2000.
  ///
  /// In uk, this message translates to:
  /// **'УСК-2000, геодезичні'**
  String get sysUsk2000;

  /// No description provided for @sysUsk2000Gk.
  ///
  /// In uk, this message translates to:
  /// **'УСК-2000, прямокутні 6°'**
  String get sysUsk2000Gk;

  /// No description provided for @sysUsk2000Tm3.
  ///
  /// In uk, this message translates to:
  /// **'УСК-2000, ТМ 3°'**
  String get sysUsk2000Tm3;

  /// No description provided for @hintGeographic.
  ///
  /// In uk, this message translates to:
  /// **'50.4501, 30.5234 або 50°27\'00\"N 30°31\'24\"E'**
  String get hintGeographic;

  /// No description provided for @hintUtm.
  ///
  /// In uk, this message translates to:
  /// **'36U 324182 5591608'**
  String get hintUtm;

  /// No description provided for @hintMgrs.
  ///
  /// In uk, this message translates to:
  /// **'36U UA 24182 91607'**
  String get hintMgrs;

  /// No description provided for @hintGrid.
  ///
  /// In uk, this message translates to:
  /// **'X 5593957  Y 6324233'**
  String get hintGrid;

  /// No description provided for @hintTm3.
  ///
  /// In uk, this message translates to:
  /// **'X 5591157  Y 337291'**
  String get hintTm3;

  /// No description provided for @geoDegrees.
  ///
  /// In uk, this message translates to:
  /// **'Градуси'**
  String get geoDegrees;

  /// No description provided for @geoDegMin.
  ///
  /// In uk, this message translates to:
  /// **'Градуси, мінути'**
  String get geoDegMin;

  /// No description provided for @geoDms.
  ///
  /// In uk, this message translates to:
  /// **'Градуси, мінути, секунди'**
  String get geoDms;

  /// No description provided for @angleDeg360.
  ///
  /// In uk, this message translates to:
  /// **'Градуси 360°'**
  String get angleDeg360;

  /// No description provided for @angleMils6000.
  ///
  /// In uk, this message translates to:
  /// **'Поділки 60-00'**
  String get angleMils6000;

  /// No description provided for @angleMils6400.
  ///
  /// In uk, this message translates to:
  /// **'Тисячні 64-00'**
  String get angleMils6400;

  /// No description provided for @angleDms.
  ///
  /// In uk, this message translates to:
  /// **'Градуси, мінути, секунди'**
  String get angleDms;

  /// No description provided for @errUnrecognized.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося розпізнати координати'**
  String get errUnrecognized;

  /// No description provided for @errOutOfRange.
  ///
  /// In uk, this message translates to:
  /// **'Координати поза допустимими межами'**
  String get errOutOfRange;

  /// No description provided for @errMissingZone.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть зону'**
  String get errMissingZone;

  /// No description provided for @errOutsideSystem.
  ///
  /// In uk, this message translates to:
  /// **'Точка поза областю системи'**
  String get errOutsideSystem;

  /// No description provided for @errAngle.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося розпізнати кут'**
  String get errAngle;

  /// No description provided for @errDistance.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть відстань у метрах'**
  String get errDistance;

  /// No description provided for @errLocation.
  ///
  /// In uk, this message translates to:
  /// **'Немає доступу до геолокації'**
  String get errLocation;

  /// No description provided for @zone.
  ///
  /// In uk, this message translates to:
  /// **'Зона'**
  String get zone;

  /// No description provided for @zoneValue.
  ///
  /// In uk, this message translates to:
  /// **'зона {zone}'**
  String zoneValue(int zone);

  /// No description provided for @neighbourZone.
  ///
  /// In uk, this message translates to:
  /// **'Сусідня зона'**
  String get neighbourZone;

  /// No description provided for @taskConverter.
  ///
  /// In uk, this message translates to:
  /// **'Конвертер координат'**
  String get taskConverter;

  /// No description provided for @taskConverterSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'WGS 84, СК-42, УСК-2000, UTM, MGRS'**
  String get taskConverterSubtitle;

  /// No description provided for @taskAngles.
  ///
  /// In uk, this message translates to:
  /// **'Конвертер кутів'**
  String get taskAngles;

  /// No description provided for @taskAnglesSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'360°, 60-00, 64-00, Г°М′С″'**
  String get taskAnglesSubtitle;

  /// No description provided for @taskDirect.
  ///
  /// In uk, this message translates to:
  /// **'Пряма геодезична задача'**
  String get taskDirect;

  /// No description provided for @taskDirectSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Точка, відстань і кут → нова точка'**
  String get taskDirectSubtitle;

  /// No description provided for @taskInverse.
  ///
  /// In uk, this message translates to:
  /// **'Обернена геодезична задача'**
  String get taskInverse;

  /// No description provided for @taskInverseSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Дві точки → відстань і кути'**
  String get taskInverseSubtitle;

  /// No description provided for @inputSystem.
  ///
  /// In uk, this message translates to:
  /// **'Система координат'**
  String get inputSystem;

  /// No description provided for @coordinates.
  ///
  /// In uk, this message translates to:
  /// **'Координати'**
  String get coordinates;

  /// No description provided for @results.
  ///
  /// In uk, this message translates to:
  /// **'У всіх системах'**
  String get results;

  /// No description provided for @angle.
  ///
  /// In uk, this message translates to:
  /// **'Кут'**
  String get angle;

  /// No description provided for @inputFormat.
  ///
  /// In uk, this message translates to:
  /// **'Формат введення'**
  String get inputFormat;

  /// No description provided for @outputFormat.
  ///
  /// In uk, this message translates to:
  /// **'Формат виведення'**
  String get outputFormat;

  /// No description provided for @startPoint.
  ///
  /// In uk, this message translates to:
  /// **'Початкова точка'**
  String get startPoint;

  /// No description provided for @endPoint.
  ///
  /// In uk, this message translates to:
  /// **'Кінцева точка'**
  String get endPoint;

  /// No description provided for @point1.
  ///
  /// In uk, this message translates to:
  /// **'Точка 1'**
  String get point1;

  /// No description provided for @point2.
  ///
  /// In uk, this message translates to:
  /// **'Точка 2'**
  String get point2;

  /// No description provided for @distanceM.
  ///
  /// In uk, this message translates to:
  /// **'Відстань, м'**
  String get distanceM;

  /// No description provided for @distance.
  ///
  /// In uk, this message translates to:
  /// **'Відстань'**
  String get distance;

  /// No description provided for @gridBearing.
  ///
  /// In uk, this message translates to:
  /// **'Дирекційний кут'**
  String get gridBearing;

  /// No description provided for @backGridBearing.
  ///
  /// In uk, this message translates to:
  /// **'Зворотний дирекційний кут'**
  String get backGridBearing;

  /// No description provided for @azimuth.
  ///
  /// In uk, this message translates to:
  /// **'Азимут'**
  String get azimuth;

  /// No description provided for @backAzimuth.
  ///
  /// In uk, this message translates to:
  /// **'Зворотний азимут'**
  String get backAzimuth;

  /// No description provided for @magneticAzimuth.
  ///
  /// In uk, this message translates to:
  /// **'Магнітний азимут'**
  String get magneticAzimuth;

  /// No description provided for @method.
  ///
  /// In uk, this message translates to:
  /// **'Метод'**
  String get method;

  /// No description provided for @methodPlane.
  ///
  /// In uk, this message translates to:
  /// **'Площина'**
  String get methodPlane;

  /// No description provided for @methodEllipsoid.
  ///
  /// In uk, this message translates to:
  /// **'Еліпсоїд'**
  String get methodEllipsoid;

  /// No description provided for @planeGrid.
  ///
  /// In uk, this message translates to:
  /// **'Площина {grid}, {zone}'**
  String planeGrid(String grid, String zone);

  /// No description provided for @ellipsoidNote.
  ///
  /// In uk, this message translates to:
  /// **'Геодезична лінія на еліпсоїді WGS 84, азимути від істинної півночі'**
  String get ellipsoidNote;

  /// No description provided for @metres.
  ///
  /// In uk, this message translates to:
  /// **'{value} м'**
  String metres(String value);

  /// No description provided for @kilometres.
  ///
  /// In uk, this message translates to:
  /// **'{value} км'**
  String kilometres(String value);

  /// No description provided for @compassMagnetic.
  ///
  /// In uk, this message translates to:
  /// **'Магнітна північ'**
  String get compassMagnetic;

  /// No description provided for @compassTrue.
  ///
  /// In uk, this message translates to:
  /// **'Істинна північ'**
  String get compassTrue;

  /// No description provided for @compassGrid.
  ///
  /// In uk, this message translates to:
  /// **'Північ сітки'**
  String get compassGrid;

  /// No description provided for @declination.
  ///
  /// In uk, this message translates to:
  /// **'Магнітне схилення'**
  String get declination;

  /// No description provided for @convergence.
  ///
  /// In uk, this message translates to:
  /// **'Зближення меридіанів'**
  String get convergence;

  /// No description provided for @altitude.
  ///
  /// In uk, this message translates to:
  /// **'Висота'**
  String get altitude;

  /// No description provided for @altitudeMsl.
  ///
  /// In uk, this message translates to:
  /// **'{value} м над рівнем моря'**
  String altitudeMsl(String value);

  /// No description provided for @altitudeEllipsoid.
  ///
  /// In uk, this message translates to:
  /// **'{value} м над еліпсоїдом'**
  String altitudeEllipsoid(String value);

  /// No description provided for @accuracy.
  ///
  /// In uk, this message translates to:
  /// **'±{value} м'**
  String accuracy(String value);

  /// No description provided for @locating.
  ///
  /// In uk, this message translates to:
  /// **'Визначення місця…'**
  String get locating;

  /// No description provided for @trueNorthNeedsLocation.
  ///
  /// In uk, this message translates to:
  /// **'Істинна північ з\'явиться після визначення місця, зараз показано магнітну'**
  String get trueNorthNeedsLocation;

  /// No description provided for @noCompass.
  ///
  /// In uk, this message translates to:
  /// **'На пристрої немає компаса'**
  String get noCompass;

  /// No description provided for @compassLowAccuracy.
  ///
  /// In uk, this message translates to:
  /// **'Низька точність компаса. Відкалібруйте: поводіть телефоном вісімкою, подалі від металу й техніки.'**
  String get compassLowAccuracy;

  /// No description provided for @compassAccuracy.
  ///
  /// In uk, this message translates to:
  /// **'Похибка компаса ±{value}°'**
  String compassAccuracy(String value);

  /// No description provided for @wmmExpired.
  ///
  /// In uk, this message translates to:
  /// **'Модель магнітного поля WMM2025 діє до 2030 року, схилення може бути неточним'**
  String get wmmExpired;

  /// No description provided for @locationDenied.
  ///
  /// In uk, this message translates to:
  /// **'Дозвольте доступ до геолокації, щоб бачити координати й істинну північ'**
  String get locationDenied;

  /// No description provided for @openSettings.
  ///
  /// In uk, this message translates to:
  /// **'Відкрити налаштування'**
  String get openSettings;

  /// No description provided for @settingsCoordinates.
  ///
  /// In uk, this message translates to:
  /// **'Координати й кути'**
  String get settingsCoordinates;

  /// No description provided for @defaultSystem.
  ///
  /// In uk, this message translates to:
  /// **'Система координат за замовчуванням'**
  String get defaultSystem;

  /// No description provided for @geoFormat.
  ///
  /// In uk, this message translates to:
  /// **'Формат географічних координат'**
  String get geoFormat;

  /// No description provided for @angleInput.
  ///
  /// In uk, this message translates to:
  /// **'Формат кутів: введення'**
  String get angleInput;

  /// No description provided for @angleOutput.
  ///
  /// In uk, this message translates to:
  /// **'Формат кутів: виведення'**
  String get angleOutput;

  /// No description provided for @callsign.
  ///
  /// In uk, this message translates to:
  /// **'Позивний'**
  String get callsign;

  /// No description provided for @callsignHint.
  ///
  /// In uk, this message translates to:
  /// **'Підписує ваші точки, коли ними діляться'**
  String get callsignHint;

  /// No description provided for @theme.
  ///
  /// In uk, this message translates to:
  /// **'Тема'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In uk, this message translates to:
  /// **'Як у системі'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In uk, this message translates to:
  /// **'Світла'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In uk, this message translates to:
  /// **'Темна'**
  String get themeDark;

  /// No description provided for @settingsSecurity.
  ///
  /// In uk, this message translates to:
  /// **'Безпека'**
  String get settingsSecurity;

  /// No description provided for @pinCode.
  ///
  /// In uk, this message translates to:
  /// **'PIN-код'**
  String get pinCode;

  /// No description provided for @pinOn.
  ///
  /// In uk, this message translates to:
  /// **'Увімкнено'**
  String get pinOn;

  /// No description provided for @pinOff.
  ///
  /// In uk, this message translates to:
  /// **'Вимкнено'**
  String get pinOff;

  /// No description provided for @pinEnable.
  ///
  /// In uk, this message translates to:
  /// **'Встановити PIN-код'**
  String get pinEnable;

  /// No description provided for @pinChange.
  ///
  /// In uk, this message translates to:
  /// **'Змінити PIN-код'**
  String get pinChange;

  /// No description provided for @pinDisable.
  ///
  /// In uk, this message translates to:
  /// **'Вимкнути PIN-код'**
  String get pinDisable;

  /// No description provided for @biometrics.
  ///
  /// In uk, this message translates to:
  /// **'Біометрія'**
  String get biometrics;

  /// No description provided for @biometricsSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Розблокування Face ID, Touch ID або відбитком'**
  String get biometricsSubtitle;

  /// No description provided for @lockAfter.
  ///
  /// In uk, this message translates to:
  /// **'Блокувати після виходу'**
  String get lockAfter;

  /// No description provided for @lockImmediately.
  ///
  /// In uk, this message translates to:
  /// **'Одразу'**
  String get lockImmediately;

  /// No description provided for @lockSeconds.
  ///
  /// In uk, this message translates to:
  /// **'Через {n} с'**
  String lockSeconds(int n);

  /// No description provided for @lockMinutes.
  ///
  /// In uk, this message translates to:
  /// **'Через {n} хв'**
  String lockMinutes(int n);

  /// No description provided for @about.
  ///
  /// In uk, this message translates to:
  /// **'Про застосунок'**
  String get about;

  /// No description provided for @pinEnter.
  ///
  /// In uk, this message translates to:
  /// **'Введіть PIN-код'**
  String get pinEnter;

  /// No description provided for @pinNew.
  ///
  /// In uk, this message translates to:
  /// **'Новий PIN-код'**
  String get pinNew;

  /// No description provided for @pinRepeat.
  ///
  /// In uk, this message translates to:
  /// **'Повторіть PIN-код'**
  String get pinRepeat;

  /// No description provided for @pinCurrent.
  ///
  /// In uk, this message translates to:
  /// **'Поточний PIN-код'**
  String get pinCurrent;

  /// No description provided for @pinMismatch.
  ///
  /// In uk, this message translates to:
  /// **'PIN-коди не збігаються'**
  String get pinMismatch;

  /// No description provided for @pinWrong.
  ///
  /// In uk, this message translates to:
  /// **'Невірний PIN-код'**
  String get pinWrong;

  /// No description provided for @pinWait.
  ///
  /// In uk, this message translates to:
  /// **'Забагато спроб. Зачекайте {seconds} с'**
  String pinWait(int seconds);

  /// No description provided for @pinSet.
  ///
  /// In uk, this message translates to:
  /// **'PIN-код встановлено'**
  String get pinSet;

  /// No description provided for @pinRemoved.
  ///
  /// In uk, this message translates to:
  /// **'PIN-код вимкнено'**
  String get pinRemoved;

  /// No description provided for @biometricReason.
  ///
  /// In uk, this message translates to:
  /// **'Розблокуйте Горизонталь'**
  String get biometricReason;

  /// No description provided for @unlockBiometric.
  ///
  /// In uk, this message translates to:
  /// **'Біометрія'**
  String get unlockBiometric;

  /// No description provided for @deleteDigit.
  ///
  /// In uk, this message translates to:
  /// **'Стерти'**
  String get deleteDigit;

  /// No description provided for @aboutDescription.
  ///
  /// In uk, this message translates to:
  /// **'Безкоштовний застосунок з відкритим кодом для роботи з координатами в полі. Працює без інтернету й нікуди не надсилає ваші дані.'**
  String get aboutDescription;

  /// No description provided for @aboutVersion.
  ///
  /// In uk, this message translates to:
  /// **'Версія {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutLicense.
  ///
  /// In uk, this message translates to:
  /// **'Відкритий вихідний код, ліцензія GPL-3.0.'**
  String get aboutLicense;

  /// No description provided for @aboutTransforms.
  ///
  /// In uk, this message translates to:
  /// **'Перехід між системами'**
  String get aboutTransforms;

  /// No description provided for @aboutTransformsText.
  ///
  /// In uk, this message translates to:
  /// **'СК-42 → WGS 84: EPSG:15865 (точність близько 4 м). УСК-2000 → WGS 84: EPSG:7817 (близько 1 м). Єдиного офіційного набору параметрів для СК-42 в Україні немає, різні програми можуть розходитися на 1–3 м.'**
  String get aboutTransformsText;

  /// No description provided for @aboutData.
  ///
  /// In uk, this message translates to:
  /// **'Дані й алгоритми'**
  String get aboutData;

  /// No description provided for @aboutDataText.
  ///
  /// In uk, this message translates to:
  /// **'Магнітне поле: World Magnetic Model WMM2025, NOAA NCEI і BGS. Геоїд: EGM2008, NGA. Геодезичні задачі: алгоритми C. F. F. Karney (GeographicLib, MIT).'**
  String get aboutDataText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
