import 'package:flutter/material.dart';
import 'package:sweph/sweph.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class MoonPhaseProvider with ChangeNotifier {
  String _currentPhase = '계산 중...';
  String _nextPhaseTime = '계산 중...';
  String _currentZodiac = '계산 중...';
  String _nextZodiacTime = '계산 중...';
  bool _isVoidOfCourse = false;
  String _voidOfCourseTime = '계산 중...';
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  String get currentPhase => _currentPhase;

  String get nextPhaseTime => _nextPhaseTime;

  String get currentZodiac => _currentZodiac;

  String get nextZodiacTime => _nextZodiacTime;

  bool get isVoidOfCourse => _isVoidOfCourse;

  String get voidOfCourseTime => _voidOfCourseTime;

  String get errorMessage => _errorMessage;

  DateTime get selectedDate => _selectedDate;

  MoonPhaseProvider() {
    tz.initializeTimeZones();
    calculateMoonData();
  }

  void setDate(DateTime newDate) {
    _selectedDate = newDate.toUtc();
    calculateMoonData();
  }

  Future<void> calculateMoonData() async {
    try {
      final nowUtc = _selectedDate.toUtc();
      final localLocation = tz.getLocation('Asia/Seoul'); // 기본 KST, 필요 시 동적 설정
      final nowLocal = tz.TZDateTime.from(nowUtc, localLocation);

      final jdResult = Sweph.swe_utc_to_jd(
        nowUtc.year,
        nowUtc.month,
        nowUtc.day,
        nowUtc.hour,
        nowUtc.minute,
        nowUtc.second.toDouble(),
        CalendarType.SE_GREG_CAL,
      );

      if (jdResult[0] == null || jdResult[1] == null) {
        _errorMessage = 'Julian Day 계산 실패';
        notifyListeners();
        return;
      }
      final julianDayEt = jdResult[0];

      final sunResult = Sweph.swe_calc_ut(
        julianDayEt,
        HeavenlyBody.SE_SUN,
        SwephFlag.SEFLG_SWIEPH,
      );
      final moonResult = Sweph.swe_calc_ut(
        julianDayEt,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
      );

      if (sunResult.longitude == null || moonResult.longitude == null) {
        _errorMessage = '천체 위치 계산 실패';
        notifyListeners();
        return;
      }

      double phaseAngle = Sweph.swe_degnorm(
        moonResult.longitude! - sunResult.longitude!,
      );
      _currentPhase = _getPhaseName(phaseAngle);
      final nextPhase = await _calculateNextPhase(julianDayEt, phaseAngle);
      _nextPhaseTime = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(tz.TZDateTime.from(nextPhase, localLocation));

      _currentZodiac = _getZodiacSign(moonResult.longitude!);
      final nextZodiac = await _calculateNextZodiac(
        julianDayEt,
        moonResult.longitude!,
      );
      _nextZodiacTime = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(tz.TZDateTime.from(nextZodiac, localLocation));

      final vocResult = await _calculateVoidOfCourse(
        julianDayEt,
        moonResult.longitude!,
        nowLocal,
      );
      _isVoidOfCourse = vocResult['isVoid'];
      _voidOfCourseTime = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(vocResult['time']);

      _errorMessage = '';
    } catch (e) {
      _errorMessage = '오류: $e';
    }
    notifyListeners();
  }

  String _getPhaseName(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'new_moon';
    if (angle < 67.5) return 'waxing_crescent';
    if (angle < 112.5) return 'first_quarter';
    if (angle < 157.5) return 'waxing_gibbous';
    if (angle < 202.5) return 'full_moon';
    if (angle < 247.5) return 'waning_gibbous';
    if (angle < 292.5) return 'last_quarter';
    return 'waning_crescent';
  }

  String _getZodiacSign(double longitude) {
    final normalized = longitude % 360;
    const signs = [
      '양자리',
      '황소자리',
      '쌍둥이자리',
      '게자리',
      '사자자리',
      '처녀자리',
      '천칭자리',
      '전갈자리',
      '사수자리',
      '염소자리',
      '물병자리',
      '물고기자리',
    ];
    final index = (normalized / 30).floor();
    return signs[index];
  }

  Future<DateTime> _calculateNextPhase(
    double julianDayEt,
    double currentAngle,
  ) async {
    final phaseAngles = [0.0, 90.0, 180.0, 270.0, 360.0];
    double targetAngle =
        phaseAngles.firstWhere(
          (angle) => angle > currentAngle,
          orElse: () => phaseAngles[0] + 360.0,
        ) %
        360.0;

    double jdStart = julianDayEt;
    double jdEnd = julianDayEt + 15.0;
    double nextJd = julianDayEt;

    while (jdEnd - jdStart > 0.0001) {
      nextJd = (jdStart + jdEnd) / 2;
      final moon = Sweph.swe_calc_ut(
        nextJd,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_SWIEPH,
      );
      final sun = Sweph.swe_calc_ut(
        nextJd,
        HeavenlyBody.SE_SUN,
        SwephFlag.SEFLG_SWIEPH,
      );

      if (moon.longitude == null || sun.longitude == null) {
        _errorMessage = '다음 위상 계산 중 오류';
        return DateTime.now();
      }

      double nextAngle = Sweph.swe_degnorm(moon.longitude! - sun.longitude!);

      if ((currentAngle < targetAngle && nextAngle >= targetAngle) ||
          (targetAngle == 0.0 && (nextAngle >= 337.5 || nextAngle < 22.5))) {
        jdEnd = nextJd;
      } else {
        jdStart = nextJd;
      }
    }

    final utc = Sweph.swe_jdet_to_utc(nextJd, CalendarType.SE_GREG_CAL);
    return utc;
  }

  Future<DateTime> _calculateNextZodiac(
    double julianDayEt,
    double currentLongitude,
  ) async {
    final currentSignIndex = (currentLongitude % 360 / 30).floor();
    final nextSignStart = ((currentSignIndex + 1) % 12) * 30.0;

    double jdStart = julianDayEt;
    double jdEnd = julianDayEt + 30.0;
    double nextJd = julianDayEt;

    while (jdEnd - jdStart > 0.0001) {
      nextJd = (jdStart + jdEnd) / 2;
      final moon = Sweph.swe_calc_ut(
        nextJd,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
      );

      if (moon.longitude == null) {
        _errorMessage = '다음 별자리 계산 중 오류';
        return DateTime.now();
      }

      double nextLongitude = moon.longitude! % 360;

      if (nextLongitude >= nextSignStart ||
          (nextSignStart < currentLongitude % 360 &&
              nextLongitude < nextSignStart + 360)) {
        jdEnd = nextJd;
      } else {
        jdStart = nextJd;
      }
    }

    final utc = Sweph.swe_jdet_to_utc(nextJd, CalendarType.SE_GREG_CAL);
    return utc;
  }

  Future<Map<String, dynamic>> _calculateVoidOfCourse(
    double julianDayEt,
    double moonLongitude,
    tz.TZDateTime nowLocal,
  ) async {
    final planets = [
      HeavenlyBody.SE_SUN,
      HeavenlyBody.SE_MERCURY,
      HeavenlyBody.SE_VENUS,
      HeavenlyBody.SE_MARS,
      HeavenlyBody.SE_JUPITER,
      HeavenlyBody.SE_SATURN,
      HeavenlyBody.SE_URANUS,
    ];
    const majorAspects = [0.0, 60.0, 90.0, 120.0, 180.0];
    const orb = 2.0;

    // 과거로 돌아가며 마지막 어스펙트 검색
    double jdStart = julianDayEt - 2.0; // 2일 전부터 검색
    double jdEnd = julianDayEt;
    double lastAspectJd = julianDayEt;

    while (jdEnd - jdStart > 0.0001) {
      double midJd = (jdStart + jdEnd) / 2;
      bool hasAspect = false;
      final moonPos = Sweph.swe_calc_ut(
        midJd,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
      );

      if (moonPos.longitude == null) continue;

      for (var planet in planets) {
        final planetPos = Sweph.swe_calc_ut(
          midJd,
          planet,
          SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
        );
        if (planetPos.longitude == null) continue;

        double angle = Sweph.swe_degnorm(
          moonPos.longitude! - planetPos.longitude!,
        );
        for (var aspect in majorAspects) {
          if ((angle - aspect).abs() < orb) {
            hasAspect = true;
            break;
          }
        }
        if (hasAspect) break;
      }

      if (hasAspect) {
        lastAspectJd = midJd;
        jdEnd = midJd;
      } else {
        jdStart = midJd;
      }
    }

    // VoC 상태 판단 (마지막 어스펙트 이후)
    bool isVoid = julianDayEt > lastAspectJd;
    double nextJd = julianDayEt;
    double searchEnd = julianDayEt + 2.0;

    while (searchEnd - nextJd > 0.0001) {
      double midJd = (nextJd + searchEnd) / 2;
      final moonPos = Sweph.swe_calc_ut(
        midJd,
        HeavenlyBody.SE_MOON,
        SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
      );
      if (moonPos.longitude == null) {
        _errorMessage = '보이드 오브 코스 계산 중 오류';
        return {'isVoid': isVoid, 'time': nowLocal};
      }

      bool nextHasAspect = false;
      for (var planet in planets) {
        final planetPos = Sweph.swe_calc_ut(
          midJd,
          planet,
          SwephFlag.SEFLG_SWIEPH | SwephFlag.SEFLG_SIDEREAL,
        );
        if (planetPos.longitude == null) continue;

        double angle = Sweph.swe_degnorm(
          moonPos.longitude! - planetPos.longitude!,
        );
        for (var aspect in majorAspects) {
          if ((angle - aspect).abs() < orb) {
            nextHasAspect = true;
            break;
          }
        }
        if (nextHasAspect) break;
      }

      if (nextHasAspect != isVoid) {
        searchEnd = midJd;
      } else {
        nextJd = midJd;
      }
    }

    final utc = Sweph.swe_jdet_to_utc(nextJd, CalendarType.SE_GREG_CAL);
    final localTime = tz.TZDateTime.from(
      utc,
      tz.getLocation(nowLocal.timeZoneName),
    );
    return {'isVoid': isVoid, 'time': localTime};
  }
}
