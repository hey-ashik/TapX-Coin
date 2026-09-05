import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/floating_particle.dart';
import '../services/api_service.dart';
import '../services/haptic_service.dart';
import '../utils/time_utils.dart';

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
  static const String _keyDailyTapsMap = 'tapx_engine_daily_taps_map';
  static const String _keyLastActiveBdDate = 'tapx_engine_last_active_bd_date';
  static const String _keyActiveStreakDays = 'tapx_engine_active_streak_days';

  // Initial starting state: 0 score, Level 1
  int _score = 0;
  int _level = 1;
  int _nextLevelScore = 100;
  int _currentMilestoneBase = 0;

  // Active Daily Taps dictionary by Bangladesh date ('YYYY-MM-DD' -> count)
  Map<String, int> _dailyTapsByDate = {};
  String? _lastDayCheckStr;
  String? _lastActiveBdDate;
  int _activeStreakDays = 1;

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
  int get todayTaps => _dailyTapsByDate[TimeUtils.bdDateString()] ?? 0;
  int get level => _level;
  int get nextLevelScore => _nextLevelScore;
  int get currentMilestoneBase => _currentMilestoneBase;
  int get maxEnergy => _maxEnergy;
  int get currentEnergy => _currentEnergy;
  double get energyPercentage => (_currentEnergy / _maxEnergy).clamp(0.0, 1.0);
  double get multiplier => _multiplier;
  int get comboCount => _comboCount;
  int get dailyBonusDay => _dailyBonusDay;
  int get streakDays => _activeStreakDays;
  int get activeStreakDays => _activeStreakDays;
  bool get isDailyBonusClaimed => _isDailyBonusClaimed;
  int get nextStreakDay => (_dailyBonusDay >= 7) ? 1 : (_dailyBonusDay + 1);
  int get nextDayBonusAmount => getBonusAmountForDay(nextStreakDay);

  // 7-day weekday tap counts: [Mon, Tue, Wed, Thu, Fri, Sat, Sun] for Bangladesh current week
  List<int> get weeklyTaps {
    final currentWeekDates = TimeUtils.currentWeekBdDates();
    return currentWeekDates.map((dateStr) => _dailyTapsByDate[dateStr] ?? 0).toList();
  }

  // Friendly time remaining until 12:00 AM (midnight) Bangladesh Time
  String get timeUntilReset => TimeUtils.timeUntilBdMidnight();

  // Calculate real activity rates (0.0 to 1.0) based on actual weekly taps
  List<double> get weeklyActivityRates {
    final taps = weeklyTaps;
    int maxDayTaps = 0;
    for (final count in taps) {
      if (count > maxDayTaps) maxDayTaps = count;
    }
    if (maxDayTaps <= 0) {
      return const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
    return taps.map((c) => (c / maxDayTaps).clamp(0.0, 1.0)).toList();
  }

  TapEngineProvider() {
    restoreState();
    _startMidnightChecker();
    _startPeriodicDBSync();
  }

  /// Increments or resets active streak based on 24-hour calendar days in Bangladesh
  void _updateActiveStreakOnActivity() {
    final todayStr = TimeUtils.bdDateString();
    if (_lastActiveBdDate == null) {
      _lastActiveBdDate = todayStr;
      if (_activeStreakDays < 1) _activeStreakDays = 1;
    } else if (_lastActiveBdDate != todayStr) {
      final lastDate = DateTime.tryParse(_lastActiveBdDate!);
      final todayDate = DateTime.tryParse(todayStr);
      if (lastDate != null && todayDate != null) {
        final daysDiff = TimeUtils.calendarDaysBetween(lastDate, todayDate);
        if (daysDiff == 1) {
          // Consecutive calendar day in Bangladesh time!
          _activeStreakDays++;
        } else if (daysDiff > 1) {
          // Missed one or more days -> reset streak back to 1
          _activeStreakDays = 1;
        }
      } else {
        _activeStreakDays = 1;
      }
      _lastActiveBdDate = todayStr;
    }
    _persistState();
  }

  Future<void> restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _score = prefs.getInt(_keyScore) ?? _score;
      _level = prefs.getInt(_keyLevel) ?? _level;
      _nextLevelScore = prefs.getInt(_keyNextLevel) ?? _nextLevelScore;
      _dailyBonusDay = (prefs.getInt(_keyBonusDay) ?? _dailyBonusDay).clamp(1, 7);
      _isDailyBonusClaimed = prefs.getBool(_keyBonusClaimed) ?? _isDailyBonusClaimed;
      _activeStreakDays = prefs.getInt(_keyActiveStreakDays) ?? _activeStreakDays;
      _lastActiveBdDate = prefs.getString(_keyLastActiveBdDate);
      _lastDayCheckStr = prefs.getString(_keyLastDate) ?? TimeUtils.bdDateString();

      final lastClaimDateStr = prefs.getString(_keyLastClaimDate);
      if (lastClaimDateStr != null) {
        _lastBonusClaimDate = DateTime.tryParse(lastClaimDateStr);
      }

      // Restore daily taps mapping
      final dailyMapJson = prefs.getString(_keyDailyTapsMap);
      if (dailyMapJson != null) {
        final decoded = jsonDecode(dailyMapJson);
        if (decoded is Map) {
          _dailyTapsByDate = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
      }

      // Check date validity against Bangladesh Time
      final nowBd = TimeUtils.bdNow();
      if (_lastBonusClaimDate != null) {
        final daysDiff = TimeUtils.calendarDaysBetween(_lastBonusClaimDate!, nowBd);
        if (daysDiff == 0) {
          _isDailyBonusClaimed = true; // Claimed today
        } else if (daysDiff == 1) {
          if (_isDailyBonusClaimed) {
            // Consecutive next day -> advance streak bonus day
            if (_dailyBonusDay >= 7) {
              _dailyBonusDay = 1;
            } else {
              _dailyBonusDay++;
            }
            _isDailyBonusClaimed = false;
          }
        } else if (daysDiff > 1) {
          // Missed one or more days -> reset daily bonus streak back to Day 1
          _dailyBonusDay = 1;
          _isDailyBonusClaimed = false;
        }
      }

      _updateActiveStreakOnActivity();
      _checkMidnightReset();
      if (_isDisposed) return;
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
      await prefs.setInt(_keyTodayTaps, todayTaps);
      await prefs.setInt(_keyLevel, _level);
      await prefs.setInt(_keyNextLevel, _nextLevelScore);
      await prefs.setInt(_keyBonusDay, _dailyBonusDay);
      await prefs.setBool(_keyBonusClaimed, _isDailyBonusClaimed);
      await prefs.setInt(_keyActiveStreakDays, _activeStreakDays);
      if (_lastActiveBdDate != null) {
        await prefs.setString(_keyLastActiveBdDate, _lastActiveBdDate!);
      }
      if (_lastDayCheckStr != null) {
        await prefs.setString(_keyLastDate, _lastDayCheckStr!);
      }
      if (_lastBonusClaimDate != null) {
        await prefs.setString(_keyLastClaimDate, _lastBonusClaimDate!.toIso8601String());
      }
      await prefs.setString(_keyWeeklyTaps, jsonEncode(weeklyTaps));
      await prefs.setString(_keyDailyTapsMap, jsonEncode(_dailyTapsByDate));
    } catch (e) {
      debugPrint('TapEngine persist note: $e');
    }
  }

  void _startMidnightChecker() {
    _midnightCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
          streakDays: _activeStreakDays,
        );
      }
    });
  }

  void _checkMidnightReset() {
    final nowBd = TimeUtils.bdNow();
    final todayStr = TimeUtils.bdDateString(nowBd);

    if (_lastDayCheckStr != null && _lastDayCheckStr != todayStr) {
      // 12:00 AM (midnight) in Bangladesh has passed!
      _lastDayCheckStr = todayStr;

      if (_lastBonusClaimDate != null) {
        final daysDiff = TimeUtils.calendarDaysBetween(_lastBonusClaimDate!, nowBd);
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
    _updateActiveStreakOnActivity();
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
    final todayStr = TimeUtils.bdDateString();
    _dailyTapsByDate[todayStr] = (_dailyTapsByDate[todayStr] ?? 0) + basePoints;

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
        HapticService.heavyImpact();
      } else if (_comboCount % 5 == 0) {
        HapticService.mediumImpact();
      } else {
        HapticService.lightImpact();
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
          streakDays: _activeStreakDays,
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
    _updateActiveStreakOnActivity();
    if (_isDailyBonusClaimed) return false;

    final reward = currentDayBonusAmount;
    _score += reward;
    final todayStr = TimeUtils.bdDateString();
    _dailyTapsByDate[todayStr] = (_dailyTapsByDate[todayStr] ?? 0) + reward;
    _isDailyBonusClaimed = true;
    _lastBonusClaimDate = TimeUtils.bdNow();

    onTapsEarned?.call(reward);
    onScoreChanged?.call(_score);
    _persistState();
    _scheduleBackendSync();
    notifyListeners();
    return true;
  }

  void resetForGuest() {
    _score = 0;
    _level = 1;
    _nextLevelScore = 100;
    _currentMilestoneBase = 0;
    _currentEnergy = 0;
    _multiplier = 1.0;
    _comboCount = 0;
    _dailyBonusDay = 1;
    _activeStreakDays = 1;
    _isDailyBonusClaimed = false;
    _lastBonusClaimDate = null;
    _dailyTapsByDate.clear();
    _particles.clear();
    _persistState();
    notifyListeners();
  }

  void loadForUser(int userScore, int userLevel, [int? userStreakDays]) {
    if (userScore > _score) {
      _score = userScore;
    }
    _level = userLevel > 0 ? userLevel : _level;
    if (userStreakDays != null && userStreakDays >= 1) {
      if (_activeStreakDays < userStreakDays) {
        _activeStreakDays = userStreakDays;
      }
      if (_lastBonusClaimDate == null) {
        _dailyBonusDay = userStreakDays.clamp(1, 7);
      }
    }
    _updateActiveStreakOnActivity();
    _currentEnergy = 0;
    _multiplier = 1.0;
    _comboCount = 0;
    _nextLevelScore = (_score > 0) ? (_score * 1.6).toInt() + 100 : 100;
    _currentMilestoneBase = (_nextLevelScore * 0.4).toInt();
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

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _decayTimer?.cancel();
    _comboResetTimer?.cancel();
    _backendSyncTimer?.cancel();
    _periodicDBSyncTimer?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
}
