import 'package:flutter/material.dart';
import '../../audio_engine/services/api_client.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// SessionHistoryPanel displays recent listening sessions and aggregate stats.
class SessionHistoryPanel extends StatefulWidget {
  const SessionHistoryPanel({super.key});

  @override
  State<SessionHistoryPanel> createState() => _SessionHistoryPanelState();
}

class _SessionHistoryPanelState extends State<SessionHistoryPanel> {
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = MindSyncApiClient();
    try {
      final results = await Future.wait([
        api.getRecentSessions(limit: 20),
        api.getStats(),
      ]);
      if (mounted) {
        setState(() {
          _sessions = results[0] as List<Map<String, dynamic>>;
          _stats    = results[1] as Map<String, dynamic>;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats summary strip ──────────────────────────────────
          if (_stats != null) _StatsStrip(stats: _stats!),
          const NeonDivider(),

          // ── Session list header ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MindSyncDimensions.md,
              vertical: MindSyncDimensions.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: MindSyncDimensions.iconSm,
                  color: MindSyncColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Text(
                  'RECENT SESSIONS',
                  style: TextStyle(
                    color:      MindSyncColors.textMuted,
                    fontSize:   10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 2.0,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () { setState(() => _loading = true); _loadData(); },
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: MindSyncColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // ── Sessions ─────────────────────────────────────────────
          SizedBox(
            height: 280,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MindSyncColors.neonCyan,
                    ),
                  )
                : _sessions.isEmpty
                    ? const Center(
                        child: Text(
                          'No sessions recorded yet.\nStart your first session above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:    MindSyncColors.textMuted,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MindSyncDimensions.sm,
                          vertical: MindSyncDimensions.xs,
                        ),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) => _SessionTile(session: _sessions[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Stats strip ────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalSec  = (stats['total_listening_sec'] as num? ?? 0).toDouble();
    final totalMins = (totalSec / 60).floor();
    final sessions  = stats['total_sessions'] as int? ?? 0;
    final favMode   = stats['favorite_mode']  as String? ?? 'FOCUS';
    final sigs      = stats['saved_signatures'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(MindSyncDimensions.md),
      child: Row(
        children: [
          _StatCell(label: 'SESSIONS',  value: '$sessions',
            color: MindSyncColors.neonCyan),
          _StatCell(label: 'MINUTES',   value: '$totalMins',
            color: MindSyncColors.neonGreen),
          _StatCell(label: 'FAV MODE',  value: favMode.substring(0, 3),
            color: MindSyncColors.neonAmber),
          _StatCell(label: 'PRESETS',   value: '$sigs',
            color: MindSyncColors.neonPurple),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color:      color,
              fontSize:   22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color:    MindSyncColors.textMuted,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session tile ───────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final mode     = (session['session_mode'] as String? ?? 'CUSTOM').toUpperCase();
    final dur      = (session['duration_sec'] as num? ?? 0).toDouble();
    final brainwave = session['brainwave_target'] as String? ?? '';
    final startedAt = session['started_at'] as String? ?? '';
    final color    = MindSyncColors.gradientForMode(mode).first;
    final bwColor  = MindSyncColors.forBrainwave(brainwave);

    // Parse ISO8601 date for display
    String timeDisplay = '—';
    try {
      final dt = DateTime.parse(startedAt);
      final local = dt.toLocal();
      timeDisplay = '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    } catch (_) {}

    final durationStr = dur < 60
        ? '${dur.toStringAsFixed(0)}s'
        : '${(dur / 60).toStringAsFixed(1)}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          // Mode dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          // Mode
          Text(
            mode.substring(0, 3),
            style: TextStyle(
              color: color, fontSize: 11,
              fontWeight: FontWeight.w700, fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          // Brainwave
          if (brainwave.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color:        bwColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                brainwave.length > 5 ? brainwave.substring(0, 5) : brainwave,
                style: TextStyle(
                  color: bwColor, fontSize: 9,
                  fontFamily: 'monospace', fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const Spacer(),
          // Duration
          Text(
            durationStr,
            style: const TextStyle(
              color: MindSyncColors.textSecondary,
              fontSize: 12, fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          // Time
          Text(
            timeDisplay,
            style: const TextStyle(
              color: MindSyncColors.textMuted,
              fontSize: 11, fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
