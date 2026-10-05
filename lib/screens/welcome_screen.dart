import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:provider/provider.dart';

import '../branding.dart';
import '../controllers/app_ctrl.dart' as ctrl;
import '../widgets/agent_status_indicator.dart';
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) {
    final textTheme = Theme.of(ctx).textTheme;
    final colorScheme = Theme.of(ctx).colorScheme;

    return Material(
      child: SafeArea(
        child: Center(
          // Scrollable so the hero still fits on short mobile viewports.
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 24,
              children: [
                const _Monogram(),
                Text(
                  Branding.name,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Text(
                    Branding.tagline,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                // Agent status indicator
                const AgentStatusIndicator(),
                Consumer2<ctrl.AppCtrl, sdk.Session>(
                  builder: (ctx, appCtrl, session, child) {
                    final isProgressing =
                        appCtrl.isSessionStarting || session.connectionState != sdk.ConnectionState.disconnected;
                    return buttons.Button(
                      text: isProgressing ? Branding.connectingLabel : Branding.connectLabel,
                      isProgressing: isProgressing,
                      onPressed: () => appCtrl.connect(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initials mark, standing in for a logo so the page needs no extra asset.
class _Monogram extends StatelessWidget {
  const _Monogram();

  @override
  Widget build(BuildContext ctx) {
    final colorScheme = Theme.of(ctx).colorScheme;

    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.06),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        Branding.monogram,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
