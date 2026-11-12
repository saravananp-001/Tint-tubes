import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../data/progress_repository.dart';
import '../domain/poster_data.dart';
import 'widgets/share_poster.dart';

/// Previews the animated milestone poster and hands it to the system share
/// sheet (WhatsApp, Instagram, messages, ...) as a PNG.
class SharePosterScreen extends StatefulWidget {
  const SharePosterScreen({
    super.key,
    required this.progress,
    required this.data,
  });

  final ProgressRepository progress;
  final PosterData data;

  @override
  State<SharePosterScreen> createState() => _SharePosterScreenState();
}

class _SharePosterScreenState extends State<SharePosterScreen>
    with TickerProviderStateMixin {
  final _posterKey = GlobalKey();
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();
  late final _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  var _format = PosterFormat.story;
  var _sharing = false;

  @override
  void dispose() {
    _intro.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  void _setFormat(PosterFormat format) {
    setState(() => _format = format);
    _intro.forward(from: 0);
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // The image must show the finished poster, not a half-played entrance.
      _intro.value = 1;
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _posterKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: 1080 / _format.size.width,
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tint_tubes_${_format.name}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: widget.data.shareText,
        ),
      );
      // Paid only when an app was actually picked, once per milestone.
      final milestone = widget.data.milestone;
      if (result.status == ShareResultStatus.success && milestone != null) {
        final earned = widget.progress.claimShareReward(
          milestone.$1,
          milestone.$2,
        );
        if (earned > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('+$earned coins for sharing!')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open sharing. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Share your progress',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<PosterFormat>(
                  segments: [
                    for (final f in PosterFormat.values)
                      ButtonSegment(value: f, label: Text(f.label)),
                  ],
                  selected: {_format},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => _setFormat(s.first),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: FittedBox(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: RepaintBoundary(
                        key: _posterKey,
                        child: SharePoster(
                          data: widget.data,
                          format: _format,
                          intro: _intro,
                          twinkle: _twinkle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.data.milestone case (final d, final level))
                  ListenableBuilder(
                    listenable: widget.progress,
                    builder: (context, _) {
                      final claimed = widget.progress.shareRewardClaimed(
                        d,
                        level,
                      );
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            claimed
                                ? 'Share reward collected  '
                                : 'Share to earn  ',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (!claimed) const CoinBadge(coins: kShareReward),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: const Icon(Icons.share_rounded),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Share', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
