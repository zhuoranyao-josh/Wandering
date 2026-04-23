import 'package:flutter/material.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.startJourneyLabel,
    this.onStartJourney,
    this.onFavorite,
    this.onShare,
  });

  final String startJourneyLabel;
  final VoidCallback? onStartJourney;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // 固定底栏使用白底 + 阴影，形成悬浮层级感。
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onStartJourney,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    startJourneyLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _ActionIconButton(
              icon: Icons.favorite_border_rounded,
              onTap: onFavorite,
            ),
            const SizedBox(width: 8),
            _ActionIconButton(icon: Icons.ios_share_rounded, onTap: onShare),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 21, color: const Color(0xFF1F2937)),
        ),
      ),
    );
  }
}
