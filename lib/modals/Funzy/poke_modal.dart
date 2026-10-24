import 'package:flutter/material.dart';

import '../../models/fixture_models.dart';
import '../../pages/fan_Funzy_design.dart';

/// Point-based match poke, styled to match SwipeableVotePledgeModal.
///
/// The caller supplies the authoritative points balance and the API callback;
/// this widget never invents or locally persists a balance.
class PokeModal extends StatefulWidget {
  final Fixture fixture;
  final String userId;
  final String username;
  final String channelId;
  final bool isLoggedIn;
  final int pointsBalance;
  final Future<Map<String, dynamic>> Function({
    required String selection,
    required int pointsStake,
  }) onCreatePoke;

  const PokeModal({
    super.key,
    required this.fixture,
    required this.userId,
    required this.username,
    required this.channelId,
    required this.isLoggedIn,
    required this.pointsBalance,
    required this.onCreatePoke,
  });

  static Future<void> show({
    required BuildContext context,
    required Fixture fixture,
    required String userId,
    required String username,
    required String channelId,
    required bool isLoggedIn,
    required int pointsBalance,
    required Future<Map<String, dynamic>> Function({
      required String selection,
      required int pointsStake,
    }) onCreatePoke,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PokeModal(
        fixture: fixture,
        userId: userId,
        username: username,
        channelId: channelId,
        isLoggedIn: isLoggedIn,
        pointsBalance: pointsBalance,
        onCreatePoke: onCreatePoke,
      ),
    );
  }

  @override
  State<PokeModal> createState() => _PokeModalState();
}

class _PokeModalState extends State<PokeModal> {
  final TextEditingController _stakeController =
      TextEditingController(text: '5');
  String _selection = 'home';
  bool _submitting = false;
  String? _error;

  int get _stake => int.tryParse(_stakeController.text.trim()) ?? 0;
  bool get _canSubmit =>
      widget.isLoggedIn &&
      widget.channelId.trim().isNotEmpty &&
      !widget.fixture.isLive &&
      !_submitting &&
      _stake >= 5 &&
      _stake <= widget.pointsBalance &&
      (_selection == 'home' || _selection == 'away');

  @override
  void dispose() {
    _stakeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!widget.isLoggedIn) {
      setState(() => _error = 'Log in to poke a match.');
      return;
    }
    if (widget.channelId.trim().isEmpty) {
      setState(() => _error = 'Join a channel before creating a poke.');
      return;
    }
    if (widget.fixture.isLive) {
      setState(() => _error = 'Pokes are closed once a match goes live.');
      return;
    }
    if (_stake < 5) {
      setState(() => _error = 'The minimum poke is 5 points.');
      return;
    }
    if (_stake > widget.pointsBalance) {
      setState(() => _error = 'You do not have enough points for this poke.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.onCreatePoke(
        selection: _selection,
        pointsStake: _stake,
      );
      if (!mounted) return;
      final success = result['success'] == true ||
          result['status']?.toString().toLowerCase() == 'success';
      if (success) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _error = result['message']?.toString() ??
            result['error']?.toString() ??
            'Could not create the poke. Please try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create the poke. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final canPoke = widget.isLoggedIn &&
        widget.channelId.trim().isNotEmpty &&
        !widget.fixture.isLive &&
        widget.pointsBalance >= 5;
    final projectedBalance = widget.pointsBalance - _stake + (_stake * 2);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        decoration: BoxDecoration(
          color: FanColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FanColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: FanColors.primaryDim,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bolt_rounded,
                          color: FanColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Poke this match',
                            style: TextStyle(
                              color: FanColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Stake points. Someone takes the other side.',
                            style: TextStyle(
                              color: FanColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded,
                          size: 19, color: FanColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FanColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: FanColors.border.withOpacity(0.35)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.fixture.league,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FanColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _TeamChoice(
                              label: widget.fixture.homeTeam,
                              subtitle: 'HOME',
                              selected: _selection == 'home',
                              color: FanColors.primary,
                              onTap: () => setState(() {
                                _selection = 'home';
                                _error = null;
                              }),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('VS',
                                style: TextStyle(
                                  color: FanColors.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                )),
                          ),
                          Expanded(
                            child: _TeamChoice(
                              label: widget.fixture.awayTeam,
                              subtitle: 'AWAY',
                              selected: _selection == 'away',
                              color: FanColors.away,
                              onTap: () => setState(() {
                                _selection = 'away';
                                _error = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FanColors.primaryDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: FanColors.borderActive),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded,
                          color: FanColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your points',
                                style: TextStyle(
                                  color: FanColors.textTertiary,
                                  fontSize: 10,
                                )),
                            Text(
                              '${widget.pointsBalance} pts',
                              style: TextStyle(
                                color: FanColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('MIN 5 PTS',
                          style: TextStyle(
                            color: FanColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Points to stake',
                    style: TextStyle(
                      color: FanColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                TextField(
                  controller: _stakeController,
                  enabled: !_submitting,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: FanColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter points (minimum 5)',
                    hintStyle: TextStyle(
                        color: FanColors.textTertiary, fontSize: 11),
                    filled: true,
                    fillColor: FanColors.surfaceSunken,
                    prefixIcon: Icon(Icons.stars_rounded,
                        color: FanColors.primary, size: 18),
                    suffixText: 'PTS',
                    suffixStyle: TextStyle(
                        color: FanColors.textSecondary,
                        fontWeight: FontWeight.w700),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: FanColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: FanColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: FanColors.primary, width: 1.4),
                    ),
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: FanColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: FanColors.border.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Your pick',
                        value: _selection == 'home'
                            ? widget.fixture.homeTeam
                            : widget.fixture.awayTeam,
                        color: _selection == 'home'
                            ? FanColors.primary
                            : FanColors.away,
                      ),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Opponent stake',
                        value: '$_stake points to match',
                        color: FanColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Divider(color: FanColors.border, height: 1),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'If you win',
                        value: canPoke && _stake >= 5 && _stake <= widget.pointsBalance
                            ? '$projectedBalance pts balance'
                            : '—',
                        color: FanColors.primary,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                if (!canPoke) ...[
                  const SizedBox(height: 8),
                  Text(
                    !widget.isLoggedIn
                        ? 'Log in to create a poke.'
                        : widget.channelId.trim().isEmpty
                            ? 'Join a channel to create a poke.'
                            : widget.fixture.isLive
                                ? 'Pokes close when the match goes live.'
                                : 'You need at least 5 points to poke.',
                    style: TextStyle(color: FanColors.away, fontSize: 11),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(color: FanColors.away, fontSize: 11)),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FanColors.primary,
                      disabledBackgroundColor: FanColors.surfaceSunken,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: FanColors.textTertiary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create poke',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pokes use points only. No draw option.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FanColors.textTertiary,
                    fontSize: 10,
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

class _TeamChoice extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TeamChoice({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : FanColors.surfaceSunken,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : FanColors.border.withOpacity(0.35),
              width: selected ? 1.4 : 0.6,
            ),
          ),
          child: Column(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? color : FanColors.textTertiary,
                size: 18,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? color : FanColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: FanColors.textTertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool emphasized;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                color: FanColors.textTertiary,
                fontSize: 10,
              )),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontSize: emphasized ? 11 : 10,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
