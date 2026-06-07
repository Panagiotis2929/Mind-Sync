import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../audio_engine/bloc/audio_engine_bloc.dart';
import '../../audio_engine/models/synthesis_parameters.dart';
import '../../audio_engine/services/api_client.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/dimensions.dart';

/// PresetsPanel displays factory presets and user-saved Neural Signatures.
/// Tapping a preset fires AudioEnginePresetLoaded to instantly update synthesis.
class PresetsPanel extends StatefulWidget {
  const PresetsPanel({super.key});

  @override
  State<PresetsPanel> createState() => _PresetsPanelState();
}

class _PresetsPanelState extends State<PresetsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _factoryPresets   = [];
  List<Map<String, dynamic>> _savedSignatures  = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final api = MindSyncApiClient();
    try {
      final results = await Future.wait([
        api.getFactoryPresets(),
        api.getAllSignatures(),
      ]);
      if (mounted) {
        setState(() {
          _factoryPresets  = results[0];
          _savedSignatures = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NeonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab bar ──────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: MindSyncColors.gridLine),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: MindSyncColors.neonCyan,
              indicatorWeight: 2,
              labelColor: MindSyncColors.neonCyan,
              unselectedLabelColor: MindSyncColors.textMuted,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
              tabs: const [
                Tab(text: 'FACTORY PRESETS'),
                Tab(text: 'MY SIGNATURES'),
              ],
            ),
          ),

          // ── Tab views ────────────────────────────────────────────
          SizedBox(
            height: 320,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: MindSyncColors.neonCyan,
                      strokeWidth: 2,
                    ),
                  )
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _loadData)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _PresetList(
                            presets: _factoryPresets,
                            isFactory: true,
                            onPresetTap: _loadPreset,
                          ),
                          _PresetList(
                            presets: _savedSignatures,
                            isFactory: false,
                            onPresetTap: _loadPreset,
                            onDelete: _deleteSignature,
                            onFavorite: _toggleFavorite,
                          ),
                        ],
                      ),
          ),

          // ── Save current as signature ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(MindSyncDimensions.md),
            child: _SaveSignatureButton(onSaved: _loadData),
          ),
        ],
      ),
    );
  }

  void _loadPreset(Map<String, dynamic> preset) {
    final params = SynthesisParameters(
      sessionMode:    _parseMode(preset['session_mode'] as String? ?? 'FOCUS'),
      focusDepth:     (preset['focus_depth']   as num? ?? 0.7).toDouble(),
      calmLevel:      (preset['calm_level']    as num? ?? 0.4).toDouble(),
      energyLevel:    (preset['energy_level']  as num? ?? 0.6).toDouble(),
      noiseProfile:   _parseNoise(preset['noise_profile'] as String? ?? 'PINK'),
      noiseVolume:    (preset['noise_volume']  as num? ?? 0.25).toDouble(),
      oscillatorMode: _parseOsc(preset['oscillator_mode'] as String? ?? 'BINAURAL'),
      masterVolume:   (preset['master_volume'] as num? ?? 0.7).toDouble(),
    );

    context.read<AudioEngineBloc>().add(AudioEnginePresetLoaded(params));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Loaded: ${preset['name']}',
          style: const TextStyle(
            fontFamily: 'monospace',
            color: MindSyncColors.neonCyan,
          ),
        ),
        backgroundColor: MindSyncColors.backgroundOverlay,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSignature(String id) async {
    final api = MindSyncApiClient();
    try {
      await api.deleteSignature(id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final api = MindSyncApiClient();
    try {
      await api.toggleFavorite(id);
      await _loadData();
    } catch (_) {}
  }

  SessionMode _parseMode(String v) {
    return SessionMode.values.firstWhere(
      (m) => m.apiValue == v.toUpperCase(),
      orElse: () => SessionMode.focus,
    );
  }

  NoiseProfileMode _parseNoise(String v) {
    return NoiseProfileMode.values.firstWhere(
      (m) => m.apiValue == v.toUpperCase(),
      orElse: () => NoiseProfileMode.pink,
    );
  }

  OscillatorModeType _parseOsc(String v) {
    return OscillatorModeType.values.firstWhere(
      (m) => m.apiValue == v.toUpperCase(),
      orElse: () => OscillatorModeType.binaural,
    );
  }
}

// ── Preset list ────────────────────────────────────────────────────────────

class _PresetList extends StatelessWidget {
  final List<Map<String, dynamic>> presets;
  final bool isFactory;
  final void Function(Map<String, dynamic>) onPresetTap;
  final void Function(String)? onDelete;
  final void Function(String)? onFavorite;

  const _PresetList({
    required this.presets,
    required this.isFactory,
    required this.onPresetTap,
    this.onDelete,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFactory ? Icons.library_music_rounded : Icons.bookmark_border_rounded,
              color: MindSyncColors.textMuted,
              size: 36,
            ),
            const SizedBox(height: MindSyncDimensions.sm),
            Text(
              isFactory ? 'No presets available' : 'No saved signatures yet',
              style: const TextStyle(
                color:    MindSyncColors.textMuted,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(MindSyncDimensions.sm),
      itemCount: presets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final preset = presets[i];
        return _PresetTile(
          preset:     preset,
          isFactory:  isFactory,
          onTap:      () => onPresetTap(preset),
          onDelete:   onDelete != null ? () => onDelete!(preset['id'] as String) : null,
          onFavorite: onFavorite != null ? () => onFavorite!(preset['id'] as String) : null,
        );
      },
    );
  }
}

class _PresetTile extends StatelessWidget {
  final Map<String, dynamic> preset;
  final bool isFactory;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;

  const _PresetTile({
    required this.preset,
    required this.isFactory,
    required this.onTap,
    this.onDelete,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final mode   = (preset['session_mode'] as String? ?? 'FOCUS').toUpperCase();
    final colors = MindSyncColors.gradientForMode(mode);
    final color  = colors.first;
    final isFav  = preset['is_favorite'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MindSyncDimensions.md,
          vertical: MindSyncDimensions.sm + 2,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Mode indicator dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
              ),
            ),
            const SizedBox(width: MindSyncDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset['name'] as String? ?? '—',
                    style: TextStyle(
                      color:      color.withOpacity(0.9),
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if ((preset['description'] as String? ?? '').isNotEmpty)
                    Text(
                      preset['description'] as String,
                      style: const TextStyle(
                        color:    MindSyncColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Action buttons for saved signatures
            if (!isFactory) ...[
              if (onFavorite != null)
                GestureDetector(
                  onTap: onFavorite,
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 16,
                    color: isFav ? MindSyncColors.neonAmber : MindSyncColors.textMuted,
                  ),
                ),
              const SizedBox(width: 8),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: MindSyncColors.neonRed,
                  ),
                ),
            ] else
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: color.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Save signature button ──────────────────────────────────────────────────

class _SaveSignatureButton extends StatelessWidget {
  final VoidCallback onSaved;
  const _SaveSignatureButton({required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSaveDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:        MindSyncColors.neonPurple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(MindSyncDimensions.radiusSm),
          border: Border.all(color: MindSyncColors.neonPurple.withOpacity(0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_rounded, size: 16, color: MindSyncColors.neonPurple),
            SizedBox(width: 8),
            Text(
              'SAVE CURRENT AS SIGNATURE',
              style: TextStyle(
                color:      MindSyncColors.neonPurple,
                fontSize:   11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final params   = context.read<AudioEngineBloc>().state.parameters;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MindSyncColors.backgroundOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MindSyncDimensions.radiusMd),
          side: const BorderSide(color: MindSyncColors.neonPurple, width: 1),
        ),
        title: const Text(
          'SAVE NEURAL SIGNATURE',
          style: TextStyle(
            color: MindSyncColors.neonPurple,
            fontSize: 14,
            fontFamily: 'monospace',
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'Signature Name', 'e.g. Morning Focus Ritual'),
            const SizedBox(height: 12),
            _dialogField(descCtrl, 'Description (optional)', ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL',
              style: TextStyle(color: MindSyncColors.textMuted, fontFamily: 'monospace'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MindSyncColors.neonPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final api = MindSyncApiClient();
              try {
                await api.createSignature({
                  'name':           nameCtrl.text.trim(),
                  'description':    descCtrl.text.trim(),
                  'session_mode':   params.sessionMode.apiValue,
                  'focus_depth':    params.focusDepth,
                  'calm_level':     params.calmLevel,
                  'energy_level':   params.energyLevel,
                  'noise_profile':  params.noiseProfile.apiValue,
                  'noise_volume':   params.noiseVolume,
                  'oscillator_mode': params.oscillatorMode.apiValue,
                  'master_volume':  params.masterVolume,
                  'tags':           <String>[],
                });
                onSaved();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Save failed: $e')),
                  );
                }
              }
            },
            child: const Text('SAVE', style: TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(
        color: MindSyncColors.textPrimary,
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText:  hint,
        labelStyle: const TextStyle(color: MindSyncColors.textMuted, fontFamily: 'monospace'),
        hintStyle:  const TextStyle(color: MindSyncColors.textMuted, fontFamily: 'monospace'),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: MindSyncColors.gridLine),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: MindSyncColors.neonPurple),
        ),
        filled: true,
        fillColor: MindSyncColors.backgroundCard,
      ),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: MindSyncColors.neonRed, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Backend unreachable',
            style: TextStyle(
              color: MindSyncColors.neonRed,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Is the Go server running on :8080?',
            style: const TextStyle(
              color:    MindSyncColors.textMuted,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'RETRY',
              style: TextStyle(
                color: MindSyncColors.neonCyan,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
