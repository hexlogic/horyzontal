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
  /// **'Вкажіть відстань'**
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

  /// No description provided for @trueAzimuth.
  ///
  /// In uk, this message translates to:
  /// **'Істинний азимут'**
  String get trueAzimuth;

  /// No description provided for @backTrueAzimuth.
  ///
  /// In uk, this message translates to:
  /// **'Зворотний істинний азимут'**
  String get backTrueAzimuth;

  /// No description provided for @backMagneticAzimuth.
  ///
  /// In uk, this message translates to:
  /// **'Зворотний магнітний азимут'**
  String get backMagneticAzimuth;

  /// No description provided for @angleKind.
  ///
  /// In uk, this message translates to:
  /// **'Вид кута'**
  String get angleKind;

  /// No description provided for @directionCorrection.
  ///
  /// In uk, this message translates to:
  /// **'Поправка напрямку'**
  String get directionCorrection;

  /// No description provided for @planeFrame.
  ///
  /// In uk, this message translates to:
  /// **'Прямокутна сітка'**
  String get planeFrame;

  /// No description provided for @frameAuto.
  ///
  /// In uk, this message translates to:
  /// **'Автоматично'**
  String get frameAuto;

  /// No description provided for @frameAutoNote.
  ///
  /// In uk, this message translates to:
  /// **'авто'**
  String get frameAutoNote;

  /// No description provided for @gridDistance.
  ///
  /// In uk, this message translates to:
  /// **'Відстань на площині'**
  String get gridDistance;

  /// No description provided for @ellipsoidDistance.
  ///
  /// In uk, this message translates to:
  /// **'Відстань на еліпсоїді'**
  String get ellipsoidDistance;

  /// No description provided for @scaleFactor.
  ///
  /// In uk, this message translates to:
  /// **'Масштаб сітки'**
  String get scaleFactor;

  /// No description provided for @groundDistance.
  ///
  /// In uk, this message translates to:
  /// **'Відстань на місцевості'**
  String get groundDistance;

  /// No description provided for @groundDistanceHint.
  ///
  /// In uk, this message translates to:
  /// **'Переводиться на площину з урахуванням масштабу сітки'**
  String get groundDistanceHint;

  /// No description provided for @unitM.
  ///
  /// In uk, this message translates to:
  /// **'м'**
  String get unitM;

  /// No description provided for @unitKm.
  ///
  /// In uk, this message translates to:
  /// **'км'**
  String get unitKm;

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
  /// **'Геодезична лінія на еліпсоїді WGS 84'**
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
  /// **'Мапа: © учасники OpenStreetMap (ODbL), OpenFreeMap, Protomaps. Висоти: Copernicus DEM GLO-30 © DLR e.V. 2010–2014 і © Airbus Defence and Space GmbH 2014–2018, надано в рамках COPERNICUS Європейським Союзом та ESA. Магнітне поле: World Magnetic Model WMM2025, NOAA NCEI і BGS. Геоїд: EGM2008, NGA. Геодезичні задачі: алгоритми C. F. F. Karney (GeographicLib, MIT). Умовні знаки: milsymbol © Måns Beckman (MIT), каталог кодів за Esri Joint Military Symbology XML (Apache-2.0).'**
  String get aboutDataText;

  /// No description provided for @tabMap.
  ///
  /// In uk, this message translates to:
  /// **'Мапа'**
  String get tabMap;

  /// No description provided for @tabJournal.
  ///
  /// In uk, this message translates to:
  /// **'Журнал'**
  String get tabJournal;

  /// No description provided for @addPointHere.
  ///
  /// In uk, this message translates to:
  /// **'Додати точку'**
  String get addPointHere;

  /// No description provided for @altitudeM.
  ///
  /// In uk, this message translates to:
  /// **'Висота, м'**
  String get altitudeM;

  /// No description provided for @appleMaps.
  ///
  /// In uk, this message translates to:
  /// **'Apple Maps'**
  String get appleMaps;

  /// No description provided for @googleMaps.
  ///
  /// In uk, this message translates to:
  /// **'Google Maps'**
  String get googleMaps;

  /// No description provided for @otherMapsApp.
  ///
  /// In uk, this message translates to:
  /// **'Інший застосунок карт'**
  String get otherMapsApp;

  /// No description provided for @archive.
  ///
  /// In uk, this message translates to:
  /// **'Архів'**
  String get archive;

  /// No description provided for @archiveEmpty.
  ///
  /// In uk, this message translates to:
  /// **'В архіві немає шарів'**
  String get archiveEmpty;

  /// No description provided for @author.
  ///
  /// In uk, this message translates to:
  /// **'Автор'**
  String get author;

  /// No description provided for @baseMap.
  ///
  /// In uk, this message translates to:
  /// **'Основа мапи'**
  String get baseMap;

  /// No description provided for @close.
  ///
  /// In uk, this message translates to:
  /// **'Закрити'**
  String get close;

  /// No description provided for @defaultLayerName.
  ///
  /// In uk, this message translates to:
  /// **'Мої об\'єкти'**
  String get defaultLayerName;

  /// No description provided for @delete.
  ///
  /// In uk, this message translates to:
  /// **'Видалити'**
  String get delete;

  /// No description provided for @deleteLayer.
  ///
  /// In uk, this message translates to:
  /// **'Видалити шар'**
  String get deleteLayer;

  /// No description provided for @deleteObjectQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Видалити об\'єкт?'**
  String get deleteObjectQuestion;

  /// No description provided for @description.
  ///
  /// In uk, this message translates to:
  /// **'Опис'**
  String get description;

  /// No description provided for @distanceAzimuthFromMe.
  ///
  /// In uk, this message translates to:
  /// **'Від мене: відстань · азимут'**
  String get distanceAzimuthFromMe;

  /// No description provided for @donate.
  ///
  /// In uk, this message translates to:
  /// **'Підтримати проєкт'**
  String get donate;

  /// No description provided for @donateHint.
  ///
  /// In uk, this message translates to:
  /// **'Банка monobank'**
  String get donateHint;

  /// No description provided for @download.
  ///
  /// In uk, this message translates to:
  /// **'Завантажити'**
  String get download;

  /// No description provided for @downloadFailed.
  ///
  /// In uk, this message translates to:
  /// **'не вдалося завантажити'**
  String get downloadFailed;

  /// No description provided for @edit.
  ///
  /// In uk, this message translates to:
  /// **'Редагувати'**
  String get edit;

  /// No description provided for @emergencyWipe.
  ///
  /// In uk, this message translates to:
  /// **'Екстрене видалення'**
  String get emergencyWipe;

  /// No description provided for @emergencyWipeHint.
  ///
  /// In uk, this message translates to:
  /// **'Стерти всі дані на цьому пристрої'**
  String get emergencyWipeHint;

  /// No description provided for @encrypt.
  ///
  /// In uk, this message translates to:
  /// **'Зашифрувати'**
  String get encrypt;

  /// No description provided for @encryptQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Зашифрувати файл паролем?'**
  String get encryptQuestion;

  /// No description provided for @encryptText.
  ///
  /// In uk, this message translates to:
  /// **'Без пароля файл прочитає будь-хто, хто його отримає. Пароль передайте іншим каналом.'**
  String get encryptText;

  /// No description provided for @noEncryption.
  ///
  /// In uk, this message translates to:
  /// **'Без шифрування'**
  String get noEncryption;

  /// No description provided for @exportFormats.
  ///
  /// In uk, this message translates to:
  /// **'.hrz, KML, KMZ, GPX, CoT, пакет ATAK'**
  String get exportFormats;

  /// No description provided for @exportLayer.
  ///
  /// In uk, this message translates to:
  /// **'Експорт шару'**
  String get exportLayer;

  /// No description provided for @exportPassword.
  ///
  /// In uk, this message translates to:
  /// **'Пароль для файлу'**
  String get exportPassword;

  /// No description provided for @formatAtakHint.
  ///
  /// In uk, this message translates to:
  /// **'Zip для ATAK: точки як CoT, лінії й полігони як KML'**
  String get formatAtakHint;

  /// No description provided for @formatAtakPackage.
  ///
  /// In uk, this message translates to:
  /// **'Пакет даних ATAK'**
  String get formatAtakPackage;

  /// No description provided for @formatCotHint.
  ///
  /// In uk, this message translates to:
  /// **'Точки для ATAK і WinTAK'**
  String get formatCotHint;

  /// No description provided for @formatGpxHint.
  ///
  /// In uk, this message translates to:
  /// **'Навігатори, OsmAnd, Garmin'**
  String get formatGpxHint;

  /// No description provided for @formatHrz.
  ///
  /// In uk, this message translates to:
  /// **'Горизонталь (.hrz)'**
  String get formatHrz;

  /// No description provided for @formatHrzHint.
  ///
  /// In uk, this message translates to:
  /// **'Без втрат, для іншої Горизонталі; можна з паролем'**
  String get formatHrzHint;

  /// No description provided for @formatKmlHint.
  ///
  /// In uk, this message translates to:
  /// **'Google Earth, ATAK, OsmAnd, QGIS'**
  String get formatKmlHint;

  /// No description provided for @hidden.
  ///
  /// In uk, this message translates to:
  /// **'прихований'**
  String get hidden;

  /// No description provided for @importAction.
  ///
  /// In uk, this message translates to:
  /// **'Імпортувати'**
  String get importAction;

  /// No description provided for @importFile.
  ///
  /// In uk, this message translates to:
  /// **'Імпорт файлу'**
  String get importFile;

  /// No description provided for @importPack.
  ///
  /// In uk, this message translates to:
  /// **'Імпорт пакета'**
  String get importPack;

  /// No description provided for @importPassword.
  ///
  /// In uk, this message translates to:
  /// **'Файл зашифровано. Пароль'**
  String get importPassword;

  /// No description provided for @importQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Імпортувати шари?'**
  String get importQuestion;

  /// No description provided for @journalEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Тут з\'являться точки, лінії й полігони. Довге натискання на мапі створює точку.'**
  String get journalEmpty;

  /// No description provided for @kindPoint.
  ///
  /// In uk, this message translates to:
  /// **'Точка'**
  String get kindPoint;

  /// No description provided for @kindPoints.
  ///
  /// In uk, this message translates to:
  /// **'Точки'**
  String get kindPoints;

  /// No description provided for @kindPolygon.
  ///
  /// In uk, this message translates to:
  /// **'Полігон'**
  String get kindPolygon;

  /// No description provided for @kindPolygons.
  ///
  /// In uk, this message translates to:
  /// **'Полігони'**
  String get kindPolygons;

  /// No description provided for @kindPolyline.
  ///
  /// In uk, this message translates to:
  /// **'Полілінія'**
  String get kindPolyline;

  /// No description provided for @kindPolylines.
  ///
  /// In uk, this message translates to:
  /// **'Полілінії'**
  String get kindPolylines;

  /// No description provided for @layer.
  ///
  /// In uk, this message translates to:
  /// **'Шар'**
  String get layer;

  /// No description provided for @layerName.
  ///
  /// In uk, this message translates to:
  /// **'Назва шару'**
  String get layerName;

  /// No description provided for @layers.
  ///
  /// In uk, this message translates to:
  /// **'Шари'**
  String get layers;

  /// No description provided for @manageLayers.
  ///
  /// In uk, this message translates to:
  /// **'Керувати'**
  String get manageLayers;

  /// No description provided for @mapLayers.
  ///
  /// In uk, this message translates to:
  /// **'Шари мапи'**
  String get mapLayers;

  /// No description provided for @mapOffline.
  ///
  /// In uk, this message translates to:
  /// **'Офлайн'**
  String get mapOffline;

  /// No description provided for @mapOnline.
  ///
  /// In uk, this message translates to:
  /// **'Онлайн'**
  String get mapOnline;

  /// No description provided for @name.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get name;

  /// No description provided for @newLayer.
  ///
  /// In uk, this message translates to:
  /// **'Новий шар'**
  String get newLayer;

  /// No description provided for @newPoint.
  ///
  /// In uk, this message translates to:
  /// **'Нова точка'**
  String get newPoint;

  /// No description provided for @newPolyline.
  ///
  /// In uk, this message translates to:
  /// **'Нова полілінія'**
  String get newPolyline;

  /// No description provided for @newPolygon.
  ///
  /// In uk, this message translates to:
  /// **'Новий полігон'**
  String get newPolygon;

  /// No description provided for @interiorAngle.
  ///
  /// In uk, this message translates to:
  /// **'Внутрішній кут'**
  String get interiorAngle;

  /// No description provided for @noLayers.
  ///
  /// In uk, this message translates to:
  /// **'Шарів ще немає'**
  String get noLayers;

  /// No description provided for @noMapsApp.
  ///
  /// In uk, this message translates to:
  /// **'Немає застосунку карт для маршруту'**
  String get noMapsApp;

  /// No description provided for @noPacksHint.
  ///
  /// In uk, this message translates to:
  /// **'Завантажте область, щоб мапа працювала без інтернету'**
  String get noPacksHint;

  /// No description provided for @noPacksOffline.
  ///
  /// In uk, this message translates to:
  /// **'Імпортуйте файл пакета або вимкніть режим «Тільки офлайн»'**
  String get noPacksOffline;

  /// No description provided for @noPacksTitle.
  ///
  /// In uk, this message translates to:
  /// **'Немає офлайн-пакетів'**
  String get noPacksTitle;

  /// No description provided for @nothingFound.
  ///
  /// In uk, this message translates to:
  /// **'Нічого не знайдено'**
  String get nothingFound;

  /// No description provided for @object.
  ///
  /// In uk, this message translates to:
  /// **'Об\'єкт'**
  String get object;

  /// No description provided for @offlinePacks.
  ///
  /// In uk, this message translates to:
  /// **'Офлайн-пакети карт'**
  String get offlinePacks;

  /// No description provided for @packNoHeights.
  ///
  /// In uk, this message translates to:
  /// **'без висот'**
  String get packNoHeights;

  /// No description provided for @packNotAvailable.
  ///
  /// In uk, this message translates to:
  /// **'недоступно для завантаження'**
  String get packNotAvailable;

  /// No description provided for @packUpdate.
  ///
  /// In uk, this message translates to:
  /// **'Оновити'**
  String get packUpdate;

  /// No description provided for @packsAttribution.
  ///
  /// In uk, this message translates to:
  /// **'Карта: © учасники OpenStreetMap (ODbL), Protomaps. Висоти: Copernicus DEM GLO-30 © DLR, Airbus, ESA. Пакети з github.com/hexlogic/horyzontal.'**
  String get packsAttribution;

  /// No description provided for @packsLoading.
  ///
  /// In uk, this message translates to:
  /// **'Перевіряю доступні пакети…'**
  String get packsLoading;

  /// No description provided for @packsManifestError.
  ///
  /// In uk, this message translates to:
  /// **'Список пакетів недоступний (немає мережі?). Можна імпортувати файл.'**
  String get packsManifestError;

  /// No description provided for @packsOfflineOnly.
  ///
  /// In uk, this message translates to:
  /// **'Режим «Тільки офлайн»: завантаження вимкнено'**
  String get packsOfflineOnly;

  /// No description provided for @packsOther.
  ///
  /// In uk, this message translates to:
  /// **'Інші файли'**
  String get packsOther;

  /// No description provided for @password.
  ///
  /// In uk, this message translates to:
  /// **'Пароль'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In uk, this message translates to:
  /// **'Щонайменше 8 символів'**
  String get passwordHint;

  /// No description provided for @privacyOfflineOnly.
  ///
  /// In uk, this message translates to:
  /// **'Тільки офлайн'**
  String get privacyOfflineOnly;

  /// No description provided for @privacyOk.
  ///
  /// In uk, this message translates to:
  /// **'Зрозуміло'**
  String get privacyOk;

  /// No description provided for @privacyTitle.
  ///
  /// In uk, this message translates to:
  /// **'Приватність'**
  String get privacyTitle;

  /// No description provided for @privacyText.
  ///
  /// In uk, this message translates to:
  /// **'Горизонталь не має аналітики, реклами й облікових записів, а ваші об\'єкти зберігаються лише на пристрої, зашифрованими.\n\nОнлайн-мапа завантажує тайли з OpenFreeMap: за запитами провайдер бачить приблизний район, який ви переглядаєте. Якщо це неприйнятно, увімкніть режим «Тільки офлайн» і користуйтеся завантаженими пакетами областей. Режим можна змінити в налаштуваннях.'**
  String get privacyText;

  /// No description provided for @qrCode.
  ///
  /// In uk, this message translates to:
  /// **'QR-код'**
  String get qrCode;

  /// No description provided for @qrNotAPoint.
  ///
  /// In uk, this message translates to:
  /// **'Це не QR-код точки Горизонталі'**
  String get qrNotAPoint;

  /// No description provided for @radius.
  ///
  /// In uk, this message translates to:
  /// **'Радіус'**
  String get radius;

  /// No description provided for @radiusM.
  ///
  /// In uk, this message translates to:
  /// **'Радіус, м'**
  String get radiusM;

  /// No description provided for @receiveWifi.
  ///
  /// In uk, this message translates to:
  /// **'Отримати по Wi-Fi'**
  String get receiveWifi;

  /// No description provided for @renameLayer.
  ///
  /// In uk, this message translates to:
  /// **'Перейменувати'**
  String get renameLayer;

  /// No description provided for @route.
  ///
  /// In uk, this message translates to:
  /// **'Маршрут'**
  String get route;

  /// No description provided for @save.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get save;

  /// No description provided for @saveToLayer.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти в шар'**
  String get saveToLayer;

  /// No description provided for @scanQr.
  ///
  /// In uk, this message translates to:
  /// **'Сканувати QR'**
  String get scanQr;

  /// No description provided for @scanQrHint.
  ///
  /// In uk, this message translates to:
  /// **'Наведіть камеру на QR-код точки'**
  String get scanQrHint;

  /// No description provided for @screenshotProtection.
  ///
  /// In uk, this message translates to:
  /// **'Заборонити знімки екрана'**
  String get screenshotProtection;

  /// No description provided for @screenshotProtectionHint.
  ///
  /// In uk, this message translates to:
  /// **'Також приховує вміст у переліку застосунків'**
  String get screenshotProtectionHint;

  /// No description provided for @searchByName.
  ///
  /// In uk, this message translates to:
  /// **'Пошук за назвою'**
  String get searchByName;

  /// No description provided for @searchCoordinates.
  ///
  /// In uk, this message translates to:
  /// **'Пошук за координатами'**
  String get searchCoordinates;

  /// No description provided for @sendWifi.
  ///
  /// In uk, this message translates to:
  /// **'Передати по Wi-Fi'**
  String get sendWifi;

  /// No description provided for @showOnMap.
  ///
  /// In uk, this message translates to:
  /// **'Показати на мапі'**
  String get showOnMap;

  /// No description provided for @swipeToHide.
  ///
  /// In uk, this message translates to:
  /// **'Проведіть шар убік, щоб сховати або показати його на мапі. Довге натискання — вибрати кілька шарів для експорту чи передачі.'**
  String get swipeToHide;

  /// No description provided for @symbol.
  ///
  /// In uk, this message translates to:
  /// **'Умовний знак'**
  String get symbol;

  /// No description provided for @symbolNone.
  ///
  /// In uk, this message translates to:
  /// **'Без знака'**
  String get symbolNone;

  /// No description provided for @toArchive.
  ///
  /// In uk, this message translates to:
  /// **'В архів'**
  String get toArchive;

  /// No description provided for @unarchive.
  ///
  /// In uk, this message translates to:
  /// **'З архіву'**
  String get unarchive;

  /// No description provided for @unnamed.
  ///
  /// In uk, this message translates to:
  /// **'Без назви'**
  String get unnamed;

  /// No description provided for @whatsNew.
  ///
  /// In uk, this message translates to:
  /// **'Що нового'**
  String get whatsNew;

  /// No description provided for @settingsMap.
  ///
  /// In uk, this message translates to:
  /// **'Мапа'**
  String get settingsMap;

  /// No description provided for @offlineOnly.
  ///
  /// In uk, this message translates to:
  /// **'Тільки офлайн'**
  String get offlineOnly;

  /// No description provided for @offlineOnlyHint.
  ///
  /// In uk, this message translates to:
  /// **'Жодних мережевих запитів: ні онлайн-мапи, ні завантаження пакетів'**
  String get offlineOnlyHint;

  /// No description provided for @wipeHold.
  ///
  /// In uk, this message translates to:
  /// **'Утримуйте 3 секунди, щоб стерти'**
  String get wipeHold;

  /// No description provided for @wipePacks.
  ///
  /// In uk, this message translates to:
  /// **'Також видалити офлайн-пакети карт'**
  String get wipePacks;

  /// No description provided for @wipeText.
  ///
  /// In uk, this message translates to:
  /// **'Буде стерто базу з усіма шарами й об\'єктами, ключ шифрування, PIN-код, налаштування, джерела мапи з їхніми файлами й завантаженими областями, кеш мапи, експортовані й отримані файли. Відновити це неможливо. Застосунок закриється.'**
  String get wipeText;

  /// No description provided for @wrongPassword.
  ///
  /// In uk, this message translates to:
  /// **'Невірний пароль'**
  String get wrongPassword;

  /// No description provided for @transferBadQr.
  ///
  /// In uk, this message translates to:
  /// **'Це не запрошення до передачі Горизонталі'**
  String get transferBadQr;

  /// No description provided for @transferBothReceive.
  ///
  /// In uk, this message translates to:
  /// **'Обидва пристрої чекають на отримання. На одному з них оберіть передачу.'**
  String get transferBothReceive;

  /// No description provided for @transferBothSend.
  ///
  /// In uk, this message translates to:
  /// **'Обидва пристрої передають. На одному з них оберіть отримання.'**
  String get transferBothSend;

  /// No description provided for @transferChecksum.
  ///
  /// In uk, this message translates to:
  /// **'Дані пошкоджено під час передачі, спробуйте ще раз'**
  String get transferChecksum;

  /// No description provided for @transferConnecting.
  ///
  /// In uk, this message translates to:
  /// **'Підключаюся…'**
  String get transferConnecting;

  /// No description provided for @transferDeclined.
  ///
  /// In uk, this message translates to:
  /// **'Імпорт скасовано'**
  String get transferDeclined;

  /// No description provided for @transferLayersToSend.
  ///
  /// In uk, this message translates to:
  /// **'Шари для передачі'**
  String get transferLayersToSend;

  /// No description provided for @transferHowTo.
  ///
  /// In uk, this message translates to:
  /// **'QR показує один телефон, інший сканує. Якщо один з телефонів Android — QR показує Android: iPhone не вміє створювати точку доступу. Між двома iPhone працює напряму, без мережі. Дані шифруються ключем з QR-коду.'**
  String get transferHowTo;

  /// No description provided for @transferNeedsIphone.
  ///
  /// In uk, this message translates to:
  /// **'Цей QR-код для передачі між двома iPhone. Покажіть QR на цьому пристрої.'**
  String get transferNeedsIphone;

  /// No description provided for @transferPermission.
  ///
  /// In uk, this message translates to:
  /// **'Потрібен дозвіл на роботу з Wi-Fi'**
  String get transferPermission;

  /// No description provided for @transferReceiving.
  ///
  /// In uk, this message translates to:
  /// **'Отримую шари…'**
  String get transferReceiving;

  /// No description provided for @transferSameNetwork.
  ///
  /// In uk, this message translates to:
  /// **'Обидва в одній мережі Wi-Fi'**
  String get transferSameNetwork;

  /// No description provided for @transferSameNetworkHint.
  ///
  /// In uk, this message translates to:
  /// **'Без точки доступу: через спільний роутер'**
  String get transferSameNetworkHint;

  /// No description provided for @transferScanButton.
  ///
  /// In uk, this message translates to:
  /// **'Сканувати QR іншого телефона'**
  String get transferScanButton;

  /// No description provided for @transferSending.
  ///
  /// In uk, this message translates to:
  /// **'Передаю шари…'**
  String get transferSending;

  /// No description provided for @transferSent.
  ///
  /// In uk, this message translates to:
  /// **'Шари передано'**
  String get transferSent;

  /// No description provided for @transferShowQr.
  ///
  /// In uk, this message translates to:
  /// **'Відскануйте цей QR на іншому телефоні'**
  String get transferShowQr;

  /// No description provided for @transferShowQrButton.
  ///
  /// In uk, this message translates to:
  /// **'Показати QR'**
  String get transferShowQrButton;

  /// No description provided for @transferStarting.
  ///
  /// In uk, this message translates to:
  /// **'Запускаю…'**
  String get transferStarting;

  /// No description provided for @created.
  ///
  /// In uk, this message translates to:
  /// **'Створено {date}'**
  String created(String date);

  /// No description provided for @updated.
  ///
  /// In uk, this message translates to:
  /// **'змінено {date}'**
  String updated(String date);

  /// No description provided for @deleteLayerQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Видалити шар «{name}»?'**
  String deleteLayerQuestion(String name);

  /// No description provided for @deleteLayerText.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, =0{У шарі немає об\'єктів.} one{Разом з ним буде видалено {n} об\'єкт.} few{Разом з ним буде видалено {n} об\'єкти.} many{Разом з ним буде видалено {n} об\'єктів.} other{Разом з ним буде видалено {n} об\'єкта.}}'**
  String deleteLayerText(int n);

  /// No description provided for @deletePackQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Видалити пакет «{name}»?'**
  String deletePackQuestion(String name);

  /// No description provided for @downloading.
  ///
  /// In uk, this message translates to:
  /// **'{received} з {total}'**
  String downloading(String received, String total);

  /// No description provided for @gigabytes.
  ///
  /// In uk, this message translates to:
  /// **'{value} ГБ'**
  String gigabytes(String value);

  /// No description provided for @megabytes.
  ///
  /// In uk, this message translates to:
  /// **'{value} МБ'**
  String megabytes(String value);

  /// No description provided for @importFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося імпортувати {name}'**
  String importFailed(String name);

  /// No description provided for @importWarnings.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, one{{n} елемент пропущено} few{{n} елементи пропущено} many{{n} елементів пропущено} other{{n} елемента пропущено}}'**
  String importWarnings(int n);

  /// No description provided for @imported.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, one{Імпортовано {n} об\'єкт} few{Імпортовано {n} об\'єкти} many{Імпортовано {n} об\'єктів} other{Імпортовано {n} об\'єкта}}'**
  String imported(int n);

  /// No description provided for @notAPack.
  ///
  /// In uk, this message translates to:
  /// **'{name} не є пакетом області. Растрові мапи MBTiles і PMTiles додавайте в «Джерела мапи»'**
  String notAPack(String name);

  /// No description provided for @objectsCount.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, one{{n} об\'єкт} few{{n} об\'єкти} many{{n} об\'єктів} other{{n} об\'єкта}}'**
  String objectsCount(int n);

  /// No description provided for @packImported.
  ///
  /// In uk, this message translates to:
  /// **'Пакет {name} додано'**
  String packImported(String name);

  /// No description provided for @packsBuild.
  ///
  /// In uk, this message translates to:
  /// **'Збірка карт {build}'**
  String packsBuild(String build);

  /// No description provided for @packsInstalled.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, =0{Не встановлено} one{{n} область} few{{n} області} many{{n} областей} other{{n} області}}'**
  String packsInstalled(int n);

  /// No description provided for @packsSummary.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, =0{Немає файлів} one{{n} файл, {size}} few{{n} файли, {size}} many{{n} файлів, {size}} other{{n} файлу, {size}}}'**
  String packsSummary(int n, String size);

  /// No description provided for @transferFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося: {error}'**
  String transferFailed(String error);

  /// No description provided for @transferJoinFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося підключитися до мережі {ssid}. Підключіться вручну в налаштуваннях Wi-Fi, пароль: {psk}'**
  String transferJoinFailed(String ssid, String psk);

  /// No description provided for @transferManual.
  ///
  /// In uk, this message translates to:
  /// **'Якщо не підключається: мережа {ssid}, пароль {psk}'**
  String transferManual(String ssid, String psk);

  /// No description provided for @vertices.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, one{{n} вершина} few{{n} вершини} many{{n} вершин} other{{n} вершини}}'**
  String vertices(int n);

  /// No description provided for @tools.
  ///
  /// In uk, this message translates to:
  /// **'Інструменти'**
  String get tools;

  /// No description provided for @toolRuler.
  ///
  /// In uk, this message translates to:
  /// **'Лінійка'**
  String get toolRuler;

  /// No description provided for @toolPolyline.
  ///
  /// In uk, this message translates to:
  /// **'Полілінія'**
  String get toolPolyline;

  /// No description provided for @toolPolygon.
  ///
  /// In uk, this message translates to:
  /// **'Полігон'**
  String get toolPolygon;

  /// No description provided for @toolProfile.
  ///
  /// In uk, this message translates to:
  /// **'Профіль висот'**
  String get toolProfile;

  /// No description provided for @toolLos.
  ///
  /// In uk, this message translates to:
  /// **'Видимість'**
  String get toolLos;

  /// No description provided for @toolHint.
  ///
  /// In uk, this message translates to:
  /// **'Наведіть перехрестя і натисніть «Точка» або торкніться карти'**
  String get toolHint;

  /// No description provided for @addPoint.
  ///
  /// In uk, this message translates to:
  /// **'Точка'**
  String get addPoint;

  /// No description provided for @undoPoint.
  ///
  /// In uk, this message translates to:
  /// **'Прибрати останню точку'**
  String get undoPoint;

  /// No description provided for @clearPoints.
  ///
  /// In uk, this message translates to:
  /// **'Почати заново'**
  String get clearPoints;

  /// No description provided for @closeTool.
  ///
  /// In uk, this message translates to:
  /// **'Закрити інструмент'**
  String get closeTool;

  /// No description provided for @length.
  ///
  /// In uk, this message translates to:
  /// **'Довжина'**
  String get length;

  /// No description provided for @perimeter.
  ///
  /// In uk, this message translates to:
  /// **'Периметр'**
  String get perimeter;

  /// No description provided for @area.
  ///
  /// In uk, this message translates to:
  /// **'Площа'**
  String get area;

  /// No description provided for @lastSegment.
  ///
  /// In uk, this message translates to:
  /// **'Останній відрізок'**
  String get lastSegment;

  /// No description provided for @toCrosshair.
  ///
  /// In uk, this message translates to:
  /// **'До перехрестя'**
  String get toCrosshair;

  /// No description provided for @backShort.
  ///
  /// In uk, this message translates to:
  /// **'зворотний'**
  String get backShort;

  /// No description provided for @vertexAngle.
  ///
  /// In uk, this message translates to:
  /// **'Кут при вершині'**
  String get vertexAngle;

  /// No description provided for @deviation.
  ///
  /// In uk, this message translates to:
  /// **'Відхилення перехрестя'**
  String get deviation;

  /// No description provided for @deltaXY.
  ///
  /// In uk, this message translates to:
  /// **'Прирости'**
  String get deltaXY;

  /// No description provided for @heightDiff.
  ///
  /// In uk, this message translates to:
  /// **'Перевищення'**
  String get heightDiff;

  /// No description provided for @angleKindCycle.
  ///
  /// In uk, this message translates to:
  /// **'Змінити вид кута'**
  String get angleKindCycle;

  /// No description provided for @rangeOver.
  ///
  /// In uk, this message translates to:
  /// **'переліт {value}'**
  String rangeOver(String value);

  /// No description provided for @rangeShort.
  ///
  /// In uk, this message translates to:
  /// **'недоліт {value}'**
  String rangeShort(String value);

  /// No description provided for @deviationRight.
  ///
  /// In uk, this message translates to:
  /// **'вправо {value}'**
  String deviationRight(String value);

  /// No description provided for @deviationLeft.
  ///
  /// In uk, this message translates to:
  /// **'вліво {value}'**
  String deviationLeft(String value);

  /// No description provided for @squareMetres.
  ///
  /// In uk, this message translates to:
  /// **'{value} м²'**
  String squareMetres(String value);

  /// No description provided for @hectares.
  ///
  /// In uk, this message translates to:
  /// **'{value} га'**
  String hectares(String value);

  /// No description provided for @squareKm.
  ///
  /// In uk, this message translates to:
  /// **'{value} км²'**
  String squareKm(String value);

  /// No description provided for @buildTool.
  ///
  /// In uk, this message translates to:
  /// **'Побудувати'**
  String get buildTool;

  /// No description provided for @heightRange.
  ///
  /// In uk, this message translates to:
  /// **'Висота, мін / макс'**
  String get heightRange;

  /// No description provided for @ascentDescent.
  ///
  /// In uk, this message translates to:
  /// **'Набір / спуск висоти'**
  String get ascentDescent;

  /// No description provided for @noDemPack.
  ///
  /// In uk, this message translates to:
  /// **'Немає пакета висот для цього району'**
  String get noDemPack;

  /// No description provided for @noDemPackHint.
  ///
  /// In uk, this message translates to:
  /// **'Завантажте область: пакет висот іде разом із мапою'**
  String get noDemPackHint;

  /// No description provided for @demGaps.
  ///
  /// In uk, this message translates to:
  /// **'Частина лінії поза пакетами висот'**
  String get demGaps;

  /// No description provided for @taskSky.
  ///
  /// In uk, this message translates to:
  /// **'Сонце й Місяць'**
  String get taskSky;

  /// No description provided for @taskSkySubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Азимут і висота, схід, захід, сутінки, фаза Місяця, таймер'**
  String get taskSkySubtitle;

  /// No description provided for @skyPlace.
  ///
  /// In uk, this message translates to:
  /// **'Місце'**
  String get skyPlace;

  /// No description provided for @skyPlaceHint.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть місце, щоб побачити Сонце й Місяць'**
  String get skyPlaceHint;

  /// No description provided for @skyMoment.
  ///
  /// In uk, this message translates to:
  /// **'Момент'**
  String get skyMoment;

  /// No description provided for @skyNow.
  ///
  /// In uk, this message translates to:
  /// **'Зараз'**
  String get skyNow;

  /// No description provided for @skyPickDate.
  ///
  /// In uk, this message translates to:
  /// **'Дата'**
  String get skyPickDate;

  /// No description provided for @skyPickTime.
  ///
  /// In uk, this message translates to:
  /// **'Час'**
  String get skyPickTime;

  /// No description provided for @skyLocalTime.
  ///
  /// In uk, this message translates to:
  /// **'Місцевий'**
  String get skyLocalTime;

  /// No description provided for @skySun.
  ///
  /// In uk, this message translates to:
  /// **'Сонце'**
  String get skySun;

  /// No description provided for @skyMoon.
  ///
  /// In uk, this message translates to:
  /// **'Місяць'**
  String get skyMoon;

  /// No description provided for @skyAltitude.
  ///
  /// In uk, this message translates to:
  /// **'Висота над обрієм (з рефракцією)'**
  String get skyAltitude;

  /// No description provided for @skyPhase.
  ///
  /// In uk, this message translates to:
  /// **'Фаза'**
  String get skyPhase;

  /// No description provided for @skyIllumination.
  ///
  /// In uk, this message translates to:
  /// **'освітлено {percent} %'**
  String skyIllumination(int percent);

  /// No description provided for @skyEvents.
  ///
  /// In uk, this message translates to:
  /// **'Найближчі події за 48 годин'**
  String get skyEvents;

  /// No description provided for @skyToMoment.
  ///
  /// In uk, this message translates to:
  /// **'До вибраного моменту'**
  String get skyToMoment;

  /// No description provided for @skyDays.
  ///
  /// In uk, this message translates to:
  /// **'{count} д'**
  String skyDays(int count);

  /// No description provided for @skySunrise.
  ///
  /// In uk, this message translates to:
  /// **'Схід Сонця'**
  String get skySunrise;

  /// No description provided for @skySunset.
  ///
  /// In uk, this message translates to:
  /// **'Захід Сонця'**
  String get skySunset;

  /// No description provided for @skySunTransit.
  ///
  /// In uk, this message translates to:
  /// **'Кульмінація Сонця (полудень)'**
  String get skySunTransit;

  /// No description provided for @skyMoonrise.
  ///
  /// In uk, this message translates to:
  /// **'Схід Місяця'**
  String get skyMoonrise;

  /// No description provided for @skyMoonset.
  ///
  /// In uk, this message translates to:
  /// **'Захід Місяця'**
  String get skyMoonset;

  /// No description provided for @skyMoonTransit.
  ///
  /// In uk, this message translates to:
  /// **'Кульмінація Місяця'**
  String get skyMoonTransit;

  /// No description provided for @skyCivilDawn.
  ///
  /// In uk, this message translates to:
  /// **'Громадянський світанок, −6°'**
  String get skyCivilDawn;

  /// No description provided for @skyCivilDusk.
  ///
  /// In uk, this message translates to:
  /// **'Громадянські сутінки, −6°'**
  String get skyCivilDusk;

  /// No description provided for @skyNauticalDawn.
  ///
  /// In uk, this message translates to:
  /// **'Навігаційний світанок, −12°'**
  String get skyNauticalDawn;

  /// No description provided for @skyNauticalDusk.
  ///
  /// In uk, this message translates to:
  /// **'Навігаційні сутінки, −12°'**
  String get skyNauticalDusk;

  /// No description provided for @skyAstronomicalDawn.
  ///
  /// In uk, this message translates to:
  /// **'Астрономічний світанок, −18°'**
  String get skyAstronomicalDawn;

  /// No description provided for @skyAstronomicalDusk.
  ///
  /// In uk, this message translates to:
  /// **'Астрономічні сутінки, −18°'**
  String get skyAstronomicalDusk;

  /// No description provided for @skyPolarDay.
  ///
  /// In uk, this message translates to:
  /// **'За 48 годин Сонце не заходить: полярний день'**
  String get skyPolarDay;

  /// No description provided for @skyPolarNight.
  ///
  /// In uk, this message translates to:
  /// **'За 48 годин Сонце не сходить: полярна ніч'**
  String get skyPolarNight;

  /// No description provided for @skyAccuracy.
  ///
  /// In uk, this message translates to:
  /// **'Поза 1600–2600 роками точність знижується: обертання Землі в далекому минулому й майбутньому відоме лише наближено'**
  String get skyAccuracy;

  /// No description provided for @phaseNew.
  ///
  /// In uk, this message translates to:
  /// **'Молодик'**
  String get phaseNew;

  /// No description provided for @phaseWaxingCrescent.
  ///
  /// In uk, this message translates to:
  /// **'Молодий місяць, росте'**
  String get phaseWaxingCrescent;

  /// No description provided for @phaseFirstQuarter.
  ///
  /// In uk, this message translates to:
  /// **'Перша чверть'**
  String get phaseFirstQuarter;

  /// No description provided for @phaseWaxingGibbous.
  ///
  /// In uk, this message translates to:
  /// **'Росте, більше половини'**
  String get phaseWaxingGibbous;

  /// No description provided for @phaseFull.
  ///
  /// In uk, this message translates to:
  /// **'Повня'**
  String get phaseFull;

  /// No description provided for @phaseWaningGibbous.
  ///
  /// In uk, this message translates to:
  /// **'Спадає, більше половини'**
  String get phaseWaningGibbous;

  /// No description provided for @phaseLastQuarter.
  ///
  /// In uk, this message translates to:
  /// **'Остання чверть'**
  String get phaseLastQuarter;

  /// No description provided for @phaseWaningCrescent.
  ///
  /// In uk, this message translates to:
  /// **'Старий місяць, спадає'**
  String get phaseWaningCrescent;

  /// No description provided for @mapSources.
  ///
  /// In uk, this message translates to:
  /// **'Джерела мапи'**
  String get mapSources;

  /// No description provided for @mapSourcesSubtitle.
  ///
  /// In uk, this message translates to:
  /// **'Свої онлайн-джерела тайлів, файли MBTiles і PMTiles'**
  String get mapSourcesSubtitle;

  /// No description provided for @sourcesNote.
  ///
  /// In uk, this message translates to:
  /// **'Онлайн-джерело бачить, який район ви переглядаєте, а за умови його використання відповідаєте ви. Файли MBTiles і PMTiles та завантажені області працюють без мережі.'**
  String get sourcesNote;

  /// No description provided for @sourcesEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Джерел ще немає. Додайте адресу тайлів або файл.'**
  String get sourcesEmpty;

  /// No description provided for @sourceAddUrl.
  ///
  /// In uk, this message translates to:
  /// **'Додати за адресою'**
  String get sourceAddUrl;

  /// No description provided for @sourceAddFile.
  ///
  /// In uk, this message translates to:
  /// **'Додати файл'**
  String get sourceAddFile;

  /// No description provided for @sourceNew.
  ///
  /// In uk, this message translates to:
  /// **'Нове джерело'**
  String get sourceNew;

  /// No description provided for @sourceName.
  ///
  /// In uk, this message translates to:
  /// **'Назва'**
  String get sourceName;

  /// No description provided for @sourceUrl.
  ///
  /// In uk, this message translates to:
  /// **'Адреса тайлів'**
  String get sourceUrl;

  /// No description provided for @sourceUrlHelp.
  ///
  /// In uk, this message translates to:
  /// **'Шаблон з {xyz}; {sub} — піддомени, {tms} — рядки знизу (TMS), {wms} — запит WMS'**
  String sourceUrlHelp(Object xyz, Object sub, Object tms, Object wms);

  /// No description provided for @sourceSubdomains.
  ///
  /// In uk, this message translates to:
  /// **'Піддомени через кому'**
  String get sourceSubdomains;

  /// No description provided for @sourceTms.
  ///
  /// In uk, this message translates to:
  /// **'Рядки рахуються знизу (TMS)'**
  String get sourceTms;

  /// No description provided for @sourceMinZoom.
  ///
  /// In uk, this message translates to:
  /// **'Мін. зум'**
  String get sourceMinZoom;

  /// No description provided for @sourceMaxZoom.
  ///
  /// In uk, this message translates to:
  /// **'Макс. зум'**
  String get sourceMaxZoom;

  /// No description provided for @sourceTileSize.
  ///
  /// In uk, this message translates to:
  /// **'Розмір тайла, px'**
  String get sourceTileSize;

  /// No description provided for @sourceAttribution.
  ///
  /// In uk, this message translates to:
  /// **'Атрибуція'**
  String get sourceAttribution;

  /// No description provided for @sourceTest.
  ///
  /// In uk, this message translates to:
  /// **'Перевірити'**
  String get sourceTest;

  /// No description provided for @sourceTestOk.
  ///
  /// In uk, this message translates to:
  /// **'Тайл отримано: {size}, {format}'**
  String sourceTestOk(Object size, Object format);

  /// No description provided for @sourceTestEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Сервер відповів, але тайла в цьому місці немає'**
  String get sourceTestEmpty;

  /// No description provided for @sourceTestFailed.
  ///
  /// In uk, this message translates to:
  /// **'Не вдалося: {error}'**
  String sourceTestFailed(Object error);

  /// No description provided for @sourceOfflineBlocked.
  ///
  /// In uk, this message translates to:
  /// **'Мережу вимкнено режимом «Тільки офлайн»'**
  String get sourceOfflineBlocked;

  /// No description provided for @errTemplateEmpty.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть адресу'**
  String get errTemplateEmpty;

  /// No description provided for @errTemplateHttps.
  ///
  /// In uk, this message translates to:
  /// **'Адреса має починатися з https://'**
  String get errTemplateHttps;

  /// No description provided for @errTemplateHost.
  ///
  /// In uk, this message translates to:
  /// **'В адресі немає сервера'**
  String get errTemplateHost;

  /// No description provided for @errTemplateTiles.
  ///
  /// In uk, this message translates to:
  /// **'Потрібні {xyz} (або {tms}) чи {wms}'**
  String errTemplateTiles(Object xyz, Object tms, Object wms);

  /// No description provided for @errTemplateQuadkey.
  ///
  /// In uk, this message translates to:
  /// **'Адреси з quadkey не підтримуються'**
  String get errTemplateQuadkey;

  /// No description provided for @errTemplateSubdomains.
  ///
  /// In uk, this message translates to:
  /// **'Вкажіть піддомени для {sub}'**
  String errTemplateSubdomains(Object sub);

  /// No description provided for @errZoomRange.
  ///
  /// In uk, this message translates to:
  /// **'Зум від 0 до 24, мінімальний не більший за максимальний'**
  String get errZoomRange;

  /// No description provided for @sourceFileInfo.
  ///
  /// In uk, this message translates to:
  /// **'Файл · зум {min}–{max} · {size}'**
  String sourceFileInfo(Object min, Object max, Object size);

  /// No description provided for @sourceDownloaded.
  ///
  /// In uk, this message translates to:
  /// **'Завантажено: {size}'**
  String sourceDownloaded(Object size);

  /// No description provided for @sourceDownloadArea.
  ///
  /// In uk, this message translates to:
  /// **'Завантажити видиму область'**
  String get sourceDownloadArea;

  /// No description provided for @sourceDeleteDownloaded.
  ///
  /// In uk, this message translates to:
  /// **'Видалити завантажене'**
  String get sourceDeleteDownloaded;

  /// No description provided for @sourceDownloadTitle.
  ///
  /// In uk, this message translates to:
  /// **'Завантаження області'**
  String get sourceDownloadTitle;

  /// No description provided for @sourceDownloadZooms.
  ///
  /// In uk, this message translates to:
  /// **'Зум {min}–{max}'**
  String sourceDownloadZooms(Object min, Object max);

  /// No description provided for @sourceDownloadTiles.
  ///
  /// In uk, this message translates to:
  /// **'{count} тайлів, приблизно {size}'**
  String sourceDownloadTiles(Object count, Object size);

  /// No description provided for @sourceDownloadTooMany.
  ///
  /// In uk, this message translates to:
  /// **'Більше {max} тайлів: зменште зум або область'**
  String sourceDownloadTooMany(Object max);

  /// No description provided for @sourceDownloadTerms.
  ///
  /// In uk, this message translates to:
  /// **'Багато сервісів забороняють масове завантаження тайлів: перевірте умови джерела.'**
  String get sourceDownloadTerms;

  /// No description provided for @sourceDownloadNoArea.
  ///
  /// In uk, this message translates to:
  /// **'Відкрийте мапу на потрібній області й поверніться сюди'**
  String get sourceDownloadNoArea;

  /// No description provided for @sourceDownloadStart.
  ///
  /// In uk, this message translates to:
  /// **'Завантажити'**
  String get sourceDownloadStart;

  /// No description provided for @sourceDownloading.
  ///
  /// In uk, this message translates to:
  /// **'{done} з {total} · {size}'**
  String sourceDownloading(Object done, Object total, Object size);

  /// No description provided for @sourceDownloadDone.
  ///
  /// In uk, this message translates to:
  /// **'Завантажено {done} тайлів, не вдалося {failed}'**
  String sourceDownloadDone(Object done, Object failed);

  /// No description provided for @sourceDeleteQuestion.
  ///
  /// In uk, this message translates to:
  /// **'Видалити джерело «{name}»?'**
  String sourceDeleteQuestion(Object name);

  /// No description provided for @importVector.
  ///
  /// In uk, this message translates to:
  /// **'{name}: це векторна мапа, її місце в офлайн-пакетах'**
  String importVector(Object name);

  /// No description provided for @importElevation.
  ///
  /// In uk, this message translates to:
  /// **'{name}: це пакет висот, його місце в офлайн-пакетах'**
  String importElevation(Object name);

  /// No description provided for @importUnreadable.
  ///
  /// In uk, this message translates to:
  /// **'{name}: не вдалося прочитати як MBTiles чи PMTiles'**
  String importUnreadable(Object name);

  /// No description provided for @sourceOpacity.
  ///
  /// In uk, this message translates to:
  /// **'Непрозорість'**
  String get sourceOpacity;

  /// No description provided for @sourceImported.
  ///
  /// In uk, this message translates to:
  /// **'Додано джерело мапи «{name}»'**
  String sourceImported(Object name);

  /// No description provided for @clustering.
  ///
  /// In uk, this message translates to:
  /// **'Кластеризація'**
  String get clustering;

  /// No description provided for @clusteringHint.
  ///
  /// In uk, this message translates to:
  /// **'Близькі точки об\'єднуються в кружок із числом, коли мапу віддалено'**
  String get clusteringHint;

  /// No description provided for @reliefTint.
  ///
  /// In uk, this message translates to:
  /// **'Теплова мапа висот'**
  String get reliefTint;

  /// No description provided for @reliefTintNoPacks.
  ///
  /// In uk, this message translates to:
  /// **'Потрібен пакет висот: завантажте його в офлайн-пакетах'**
  String get reliefTintNoPacks;

  /// No description provided for @reliefLegend.
  ///
  /// In uk, this message translates to:
  /// **'Висота, м'**
  String get reliefLegend;

  /// No description provided for @demSurfaceNote.
  ///
  /// In uk, this message translates to:
  /// **'Висоти Copernicus DEM — модель поверхні: вони включають ліс і будівлі'**
  String get demSurfaceNote;

  /// No description provided for @atDistance.
  ///
  /// In uk, this message translates to:
  /// **'На відстані {value}'**
  String atDistance(String value);

  /// No description provided for @losVisible.
  ///
  /// In uk, this message translates to:
  /// **'Пряма видимість є'**
  String get losVisible;

  /// No description provided for @losBlocked.
  ///
  /// In uk, this message translates to:
  /// **'Перешкода на відстані {value} від A'**
  String losBlocked(String value);

  /// No description provided for @minClearance.
  ///
  /// In uk, this message translates to:
  /// **'Найменший просвіт над перешкодою'**
  String get minClearance;

  /// No description provided for @mastA.
  ///
  /// In uk, this message translates to:
  /// **'Щогла A, м'**
  String get mastA;

  /// No description provided for @mastB.
  ///
  /// In uk, this message translates to:
  /// **'Щогла B, м'**
  String get mastB;

  /// No description provided for @refraction.
  ///
  /// In uk, this message translates to:
  /// **'Рефракція'**
  String get refraction;

  /// No description provided for @refractionNone.
  ///
  /// In uk, this message translates to:
  /// **'Без рефракції'**
  String get refractionNone;

  /// No description provided for @refractionOptical.
  ///
  /// In uk, this message translates to:
  /// **'Оптична, k = 0.13'**
  String get refractionOptical;

  /// No description provided for @refractionRadio.
  ///
  /// In uk, this message translates to:
  /// **'Радіо, 4/3 Землі'**
  String get refractionRadio;

  /// No description provided for @frequencyMhz.
  ///
  /// In uk, this message translates to:
  /// **'Частота, МГц (для зони Френеля)'**
  String get frequencyMhz;

  /// No description provided for @fresnelClear.
  ///
  /// In uk, this message translates to:
  /// **'Перша зона Френеля вільна щонайменше на 60%'**
  String get fresnelClear;

  /// No description provided for @fresnelBlocked.
  ///
  /// In uk, this message translates to:
  /// **'Перша зона Френеля перекрита: просвіт {value}% радіуса'**
  String fresnelBlocked(String value);

  /// No description provided for @pointA.
  ///
  /// In uk, this message translates to:
  /// **'Точка A'**
  String get pointA;

  /// No description provided for @pointB.
  ///
  /// In uk, this message translates to:
  /// **'Точка B'**
  String get pointB;

  /// No description provided for @cameraUnavailable.
  ///
  /// In uk, this message translates to:
  /// **'Камера недоступна. Перевірте дозвіл на камеру в системних налаштуваннях.'**
  String get cameraUnavailable;

  /// No description provided for @favorite.
  ///
  /// In uk, this message translates to:
  /// **'В обране'**
  String get favorite;

  /// No description provided for @favorites.
  ///
  /// In uk, this message translates to:
  /// **'Обране'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In uk, this message translates to:
  /// **'Нещодавні'**
  String get recent;

  /// No description provided for @symbolSearch.
  ///
  /// In uk, this message translates to:
  /// **'Пошук знака: піхота, танк, міномет…'**
  String get symbolSearch;

  /// No description provided for @sidcIdentity.
  ///
  /// In uk, this message translates to:
  /// **'Належність'**
  String get sidcIdentity;

  /// No description provided for @sidcSet.
  ///
  /// In uk, this message translates to:
  /// **'Набір знаків'**
  String get sidcSet;

  /// No description provided for @sidcEntity.
  ///
  /// In uk, this message translates to:
  /// **'Тип'**
  String get sidcEntity;

  /// No description provided for @sidcEntityNone.
  ///
  /// In uk, this message translates to:
  /// **'Не вибрано'**
  String get sidcEntityNone;

  /// No description provided for @sidcStatus.
  ///
  /// In uk, this message translates to:
  /// **'Стан'**
  String get sidcStatus;

  /// No description provided for @sidcHq.
  ///
  /// In uk, this message translates to:
  /// **'Штаб, тактична група, макет'**
  String get sidcHq;

  /// No description provided for @sidcEchelon.
  ///
  /// In uk, this message translates to:
  /// **'Ешелон'**
  String get sidcEchelon;

  /// No description provided for @sidcMobility.
  ///
  /// In uk, this message translates to:
  /// **'Рухомість'**
  String get sidcMobility;

  /// No description provided for @sidcModifier1.
  ///
  /// In uk, this message translates to:
  /// **'Модифікатор 1'**
  String get sidcModifier1;

  /// No description provided for @sidcModifier2.
  ///
  /// In uk, this message translates to:
  /// **'Модифікатор 2'**
  String get sidcModifier2;

  /// No description provided for @sidcChooseThis.
  ///
  /// In uk, this message translates to:
  /// **'Вибрати «{name}»'**
  String sidcChooseThis(String name);

  /// No description provided for @cardinalN.
  ///
  /// In uk, this message translates to:
  /// **'Пн'**
  String get cardinalN;

  /// No description provided for @cardinalE.
  ///
  /// In uk, this message translates to:
  /// **'Сх'**
  String get cardinalE;

  /// No description provided for @cardinalS.
  ///
  /// In uk, this message translates to:
  /// **'Пд'**
  String get cardinalS;

  /// No description provided for @cardinalW.
  ///
  /// In uk, this message translates to:
  /// **'Зх'**
  String get cardinalW;

  /// No description provided for @angleDmsShort.
  ///
  /// In uk, this message translates to:
  /// **'Г°М′С″'**
  String get angleDmsShort;

  /// No description provided for @notes040.
  ///
  /// In uk, this message translates to:
  /// **'Теплова мапа висот із пакетів висот — офлайн і поверх онлайн-мапи, з легендою\nСонце й Місяць: азимут і висота на будь-який момент і місце, фаза Місяця, схід, захід, кульмінація й сутінки з таймером\nКластеризація: близькі точки об\'єднуються в кружок із числом; дотик наближає\nСвої джерела мапи: адреси XYZ/TMS/WMS із завантаженням області для роботи без мережі, файли MBTiles і PMTiles\nПланшети: бічна навігація, картка об\'єкта поруч із мапою, поворот екрана'**
  String get notes040;

  /// No description provided for @notes030.
  ///
  /// In uk, this message translates to:
  /// **'Інструменти мапи: лінійка з відхиленнями, полілінії з кутами, полігони з площею, профіль висот, видимість між точками з висотою щогл і зоною Френеля\nПолілінії й полігони можна малювати й зберігати; у картці — довжина, площа й кути при вершинах\nПГЗ і ОГЗ: дирекційний кут, істинний і магнітний азимут, вибір сітки й зони (зокрема UTM), відстань у кілометрах і на місцевості\nСканер QR на ZXing замість Google ML Kit: жодних метрик до Google'**
  String get notes030;

  /// No description provided for @notes020.
  ///
  /// In uk, this message translates to:
  /// **'Мапа: онлайн OpenFreeMap і офлайн-пакети областей з рельєфом, кілька пакетів одночасно\nОб\'єкти з умовними знаками НАТО APP-6, шари, журнал з фільтрами й пошуком\nОбмін: QR для точок, шари по Wi-Fi без інтернету, файли .hrz, KML/KMZ, GPX, CoT і пакети даних ATAK\nБезпека: розмиття в перемикачі застосунків, заборона знімків екрана (Android), екстрене видалення, режим «Тільки офлайн»'**
  String get notes020;

  /// No description provided for @notes010.
  ///
  /// In uk, this message translates to:
  /// **'Конвертер координат WGS 84, СК-42, УСК-2000, UTM, MGRS і кутів\nПряма й обернена геодезичні задачі, компас з істинною північчю\nPIN-код, біометрія, зашифрована база'**
  String get notes010;

  /// No description provided for @selectedCount.
  ///
  /// In uk, this message translates to:
  /// **'{n, plural, one{Вибрано {n} шар} few{Вибрано {n} шари} many{Вибрано {n} шарів} other{Вибрано {n} шару}}'**
  String selectedCount(int n);
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
