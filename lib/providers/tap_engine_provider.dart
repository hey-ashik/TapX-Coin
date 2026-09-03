import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/floating_particle.dart';
import '../services/api_service.dart';

class TapEngineProvider extends ChangeNotifier {
  static const String _keyScore = 'tapx_engine_score';
  static const String _keyTodayTaps = 'tapx_engine_today_taps';
  static const String _keyLevel = 'tapx_engine_level';
  static const String _keyNextLevel = 'tapx_engine_next_level';
  static const String _keyBonusDay = 'tapx_engine_bonus_day';
  static const String _keyBonusClaimed = 'tapx_engine_bonus_claimed';
  static const String _keyLastDate = 'tapx_engine_last_date';
  static const String _keyLastClaimDate = 'tapx_engine_last_claim_date';
  static const String _keyWeeklyTaps = 'tapx_engine_weekly_taps';

  // Initial starting state: 0 score, Level 1
  int _score = 0;
  int _level = 1;
  int _nextLevelScore = 100;
  int _currentMilestoneBase = 0;

  // Live Today Taps tracking: counts taps in current 24h cycle, auto-resets at midnight
  int _todayTaps = 0;
  DateTime _lastDayCheck = DateTime.now();

  // 7-day weekday tap counts: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
  List<int> _weeklyTaps = [0, 0, 0, 0, 0, 0, 0];

  // Energy Charge System: Starts at 0, charges up to 500 on continuous taps
  final int _maxEnergy = 500;
  int _currentEnergy = 0;
  double _multiplier = 1.0;
  int _comboCount = 0;
  DateTime _lastTapTime = DateTime.now();

  // 7-Day Daily Bonus System with 2x daily doubling (10, 20, 40, 80, 160, 320, 640)
  int _dailyBonusDay = 1; // 1 to 7
  bool _isDailyBonusClaimed = false;
  DateTime? _lastBonusClaimDate;

  final List<FloatingParticle> _particles = [];
  Timer? _decayTimer;
  Timer? _comboResetTimer;
  Timer? _backendSyncTimer;
  Timer? _periodicDBSyncTimer;
  Timer? _midnightCheckTimer;

  // Callback to add earned taps to WalletProvider
  void Function(int earnedPoints)? onTapsEarned;
  void Function(int totalTaps)? onScoreChanged;

  int get score => _score;
  int get todayTaps => _todayTaps;
  int get level => _level;
  int get nextLevelScore => _nextLevelScore;
  int get currentMilestoneBase => _currentMilestoneBase;
  int get maxEnergy => _maxEnergy;
  int get currentEnergy => _currentEnergy;
  double get energyPercentage => (_currentEnergy / _maxEnergy).clamp(0.0, 1.0);
  double get multiplier => _multiplier;
  int get comboCount => _comboCount;
  int get dailyBonusDay => _dailyBonusDay;
  bool get isDailyBonusClaimed => _isDailyBonusClaimed;
  int get nextStreakDay => (_dailyBonusDay >= 7) ? 1 : (_dailyBonusDay + 1);
  int get nextDayBonusAmount => getBonusAmountForDay(nextStreakDay);
  List<int> get weeklyTaps => List.unmodifiable(_weeklyTaps);

  String get timeUntilReset {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Calculate real activity rates (0.0 to 1.0) based on actual weekly taps
  List<double> get weeklyActivityRates {
    int maxDayTaps = 0;
    for (final count in _weeklyTaps) {
      if (count > maxDayTaps) maxDayTaps = count;
    }
    if (maxDayTaps <= 0) {
      return const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
    return _weeklyTaps.map((c) => (c / maxDayTaps).clamp(0.0, 1.0)).toList();
  }

  TapEngineProvider() {
    restoreState();
    _startMidnightChecker();
    _startPeriodicDBSync();
  }

  static int _calendarDaysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _score = prefs.getInt(_keyScore) ?? _score;
      _todayTaps = prefs.getInt(_keyTodayTaps) ?? _todayTaps;
      _level = prefs.getInt(_keyLevel) ?? _level;
      _nextLevelScore = prefs.getInt(_keyNextLevel) ?? _nextLevelScore;
      _dailyBonusDay = (prefs.getInt(_keyBonusDay) ?? _dailyBonusDay).clamp(1, 7);
      _isDailyBonusClaimed = prefs.getBool(_keyBonusClaimed) ?? _isDailyBonusClaimed;

      final lastDateStr = prefs.getString(_keyLastDate);
      if (lastDateStr != null) {
        _lastDayCheck = DateTime.tryParse(lastDateStr) ?? DateTime.now();
      }

      final lastClaimDateStr = prefs.getString(_keyLastClaimDate);
      if (lastClaimDateStr != null) {
        _lastBonusClaimDate = DateTime.tryParse(lastClaimDateStr);
      }

      final weeklyJson = prefs.getString(_keyWeeklyTaps);
      if (weeklyJson != null) {
        final decoded = jsonDecode(weeklyJson);
        if (decoded is List) {
          _weeklyTaps = List<int>.from(decoded.map((x) => (x as num).toInt()));
        }
      }

      // Check date validity against now
      final now = DateTime.now();
      if (_lastBonusClaimDate != null) {
        final daysDiff = _calendarDaysBetween(_lastBonusClaimDate!, now);
        if (daysDiff == 0) {
          _isDailyBonusClaimed = true; // Claimed today
        } else if (daysDiff == 1) {
          if (_isDailyBonusClaimed) {
            // Consecutive next day -> advance streak
            if (_dailyBonusDay >= 7) {
              _dailyBonusDay = 1;
            } else {
              _dailyBonusDay++;
            }
            _isDailyBonusClaimed = false;
          }
        } else if (daysDiff > 1) {
          // Missed one or more days -> reset streak back to Day 1
          _dailyBonusDay = 1;
          _isDailyBonusClaimed = false;
        }
      }

      // Ensure current day bucket matches score if initial
      final weekdayIndex = (now.weekday - 1).clamp(0, 6);
      if (_weeklyTaps[weekdayIndex] < _todayTaps) {
        _weeklyTaps[weekdayIndex] = _todayTaps;
      }

      _checkMidnightReset();
      onScoreChanged?.call(_score);
      notifyListeners();
    } catch (e) {
      debugPrint('TapEngine restore note: $e');
    }
  }

  Future<void> _persistState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyScore, _score);
      await prefs.setInt(_keyTodayTaps, _todayTaps);
      await prefs.setInt(_keyLevel, _level);
      await prefs.setInt(_keyNextLevel, _nextLevelScore);
      await prefs.setInt(_keyBonusDay, _dailyBonusDay);
      await prefs.setBool(_keyBonusClaimed, _isDailyBonusClaimed);
      await prefs.setString(_keyLastDate, _lastDayCheck.toIso8601String());
      if (_lastBonusClaimDate != null) {
        await prefs.setString(_keyLastClaimDate, _lastBonusClaimDate!.toIso8601String());
      }
      await prefs.setString(_keyWeeklyTaps, jsonEncode(_weeklyTaps));
    } catch (e) {
      debugPrint('TapEngine persist note: $e');
    }
  }

  void _startMidnightChecker() {
    _midnightCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkMidnightReset();
    });
  }

  // Continuous background sync with MySQL database every 30 seconds
  void _startPeriodicDBSync() {
    _periodicDBSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ApiService.hasToken && _score > 0) {
        ApiService.syncScore(
          score: _score,
          level: _level,
          streakDays: _dailyBonusDay,
        );
      }
    });
  }

  void _checkMidnightReset() {
    final now = DateTime.now();
    final lastDate = DateTime(_lastDayCheck.year, _lastDayCheck.month, _lastDayCheck.day);
    final nowDate = DateTime(now.year, now.month, now.day);

    if (nowDate.isAfter(lastDate)) {
      _todayTaps = 0;
      _lastDayCheck = now;

      if (_lastBonusClaimDate != null) {
        final daysDiff = _calendarDaysBetween(_lastBonusClaimDate!, now);
        if (daysDiff == 1 && _isDailyBonusClaimed) {
          // Advanced to consecutive next day
          if (_dailyBonusDay >= 7) {
            _dailyBonusDay = 1;
          } else {
            _dailyBonusDay++;
          }
          _isDailyBonusClaimed = false;
        } else if (daysDiff > 1) {
          // Streak broken
          _dailyBonusDay = 1;
          _isDailyBonusClaimed = false;
        }
      } else {
        _isDailyBonusClaimed = false;
      }

      _persistState();
      notifyListeners();
    }
  }

  // 7-day reward sequence: Day 1: 10, Day 2: 20, Day 3: 40, Day 4: 80, Day 5: 160, Day 6: 320, Day 7: 640
  int get currentDayBonusAmount => getBonusAmountForDay(_dailyBonusDay);

  static int getBonusAmountForDay(int day) {
    final clampedDay = day.clamp(1, 7);
    return 10 * (1 << (clampedDay - 1));
  }

  List<FloatingParticle> get particles => List.unmodifiable(_particles);

  double get milestoneProgress {
    final range = _nextLevelScore - _currentMilestoneBase;
    if (range <= 0) return 1.0;
    final progress = (_score - _currentMilestoneBase) / range;
    return progress.clamp(0.0, 1.0);
  }

  void _calculateMultiplierAndEnergy() {
    if (_comboCount >= 500) {
      _multiplier = 2.5;
    } else if (_comboCount >= 300) {
      _multiplier = 2.4;
    } else if (_comboCount >= 150) {
      _multiplier = 2.0;
    } else if (_comboCount >= 50) {
      _multiplier = 1.5;
    } else {
      _multiplier = 1.0;
    }
  }

  void handleTap(Offset localPosition, {bool hapticsEnabled = true}) {
    _checkMidnightReset();
    _decayTimer?.cancel();
    _comboResetTimer?.cancel();

    final now = DateTime.now();
    final difference = now.difference(_lastTapTime).inMilliseconds;
    _lastTapTime = now;

    if (difference < 800) {
      _comboCount++;
    } else {
      _comboCount = 1;
    }

    _currentEnergy = (_currentEnergy + 1).clamp(0, _maxEnergy);
    _calculateMultiplierAndEnergy();

    int basePoints = 1;
    if (_multiplier >= 2.5) {
      basePoints = 3;
    } else if (_multiplier >= 1.5) {
      basePoints = 2;
    } else {
      basePoints = 1;
    }

    _score += basePoints;
    _todayTaps += basePoints;

    // Record in current weekday bucket (Monday = 1 -> index 0)
    final weekdayIndex = (now.weekday - 1).clamp(0, 6);
    if (_weeklyTaps.length == 7) {
      _weeklyTaps[weekdayIndex] = (_weeklyTaps[weekdayIndex] + basePoints).clamp(0, _score);
    }

    // Notify wallet provider with earned points
    onTapsEarned?.call(basePoints);
    onScoreChanged?.call(_score);

    // Dynamic Level Progression Calculation
    if (_score >= _nextLevelScore) {
      _level++;
      _currentMilestoneBase = _nextLevelScore;
      _nextLevelScore = (_nextLevelScore * 1.6).toInt() + 100;
    }

    // Haptics
    if (hapticsEnabled) {
      if (_comboCount % 25 == 0) {
        HapticFeedback.heavyImpact();
      } else if (_comboCount % 5 == 0) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    // Floating particle
    final particleText = '+$basePoints';
    final particle = FloatingParticle(
      id: '${now.microsecondsSinceEpoch}',
      text: particleText,
      position: localPosition,
      createdAt: now,
      color: Colors.white,
      fontSize: basePoints > 1 ? 26.0 : 22.0,
      showFireIcon: basePoints > 1,
    );
    _particles.add(particle);

    _comboResetTimer = Timer(const Duration(milliseconds: 1500), () {
      _startEnergyDecay();
    });

    _persistState();
    _scheduleBackendSync();
    notifyListeners();
  }

  void _scheduleBackendSync() {
    _backendSyncTimer?.cancel();
    _backendSyncTimer = Timer(const Duration(milliseconds: 1000), () {
      if (ApiService.hasToken && _score > 0) {
        ApiService.syncScore(
          score: _score,
          level: _level,
          streakDays: _dailyBonusDay,
        );
      }
    });
  }

  void _startEnergyDecay() {
    _decayTimer?.cancel();
    _decayTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentEnergy > 0 || _comboCount > 0) {
        _currentEnergy = (_currentEnergy - 10).clamp(0, _maxEnergy);
        _comboCount = (_comboCount - 10).clamp(0, 5000);
        _calculateMultiplierAndEnergy();
        notifyListeners();
      } else {
        _currentEnergy = 0;
        _comboCount = 0;
        _multiplier = 1.0;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void removeParticle(String id) {
    _particles.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  bool claimDailyBonus() {
    _checkMidnightReset();
    if (_isDailyBonusClaimed) return false;

    final reward = currentDayBonusAmount;
    _score += reward;
    _todayTaps += reward;
    final now = DateTime.now();
    final weekdayIndex = (now.weekday - 1).clamp(0, 6);
    if (_weeklyTaps.length == 7) {
      _weeklyTaps[weekdayIndex] = (_weeklyTaps[weekdayIndex] + reward).clamp(0, _score);
    }
    _isDailyBonusClaimed = true;
    _lastBonusClaimDate = now;

    onTapsEarned?.call(reward);
    onScoreChanged?.call(_score);
    _persistState();
    _scheduleBackendSync();
    notifyListeners();
    return true;
  }

  void resetForGuest() {
    _score = 0;
    _todayTaps = 0;
    _level = 1;
    _nextLevelScore = 100;
    _currentMilestoneBase = 0;
    _currentEnergy = 0;
    _multiplier = 1.0;
    _comboCount = 0;
    _dailyBonusDay = 1;
    _isDailyBonusClaimed = false;
    _lastBonusClaimDate = null;
    _weeklyTaps = [0, 0, 0, 0, 0, 0, 0];
    _particles.clear();
    _persistState();
    notifyListeners();
  }

  void loadForUser(int userScore, int userLevel, [int? userStreakDays]) {
    if (userScore > _score) {
      _score = userScore;
    }
    _level = userLevel > 0 ? userLevel : _level;
    if (userStreakDays != null && userStreakDays >= 1 && userStreakDays <= 7 && _lastBonusClaimDate == null) {
      _dailyBonusDay = userStreakDays;
    }
    _todayTaps = _todayTaps > 0 ? _todayTaps.clamp(0, _score) : _score;
    _currentEnergy = 0;
    _multiplier = 1.0;
    _comboCount = 0;
    _nextLevelScore = (_score > 0) ? (_score * 1.6).toInt() + 100 : 100;
    _currentMilestoneBase = (_nextLevelScore * 0.4).toInt();
    final now = DateTime.now();
    final weekdayIndex = (now.weekday - 1).clamp(0, 6);
    if (_weeklyTaps.length == 7) {
      _weeklyTaps[weekdayIndex] = _todayTaps;
      for (int i = 0; i < 7; i++) {
        if (_weeklyTaps[i] > _score) {
          _weeklyTaps[i] = _score;
        }
      }
    } else {
      _weeklyTaps = [0, 0, 0, 0, 0, 0, 0];
      _weeklyTaps[weekdayIndex] = _todayTaps;
    }
    _persistState();
    notifyListeners();
  }

  void clearSession() {
    resetForGuest();
  }

  void syncWithUser(int userScore, int userLevel, [int? userStreakDays]) {
    loadForUser(userScore, userLevel, userStreakDays);
  }

  void setScoreFromBackend(int score, int level, [int? userStreakDays]) {
    loadForUser(score, level, userStreakDays);
  }

  @override
  void dispose() {
    _decayTimer?.cancel();
    _comboResetTimer?.cancel();
    _backendSyncTimer?.cancel();
    _periodicDBSyncTimer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
}
