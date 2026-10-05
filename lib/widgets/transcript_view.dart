import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../branding.dart';

/// Scrolling transcript of the live conversation, built from the transcriptions
/// LiveKit publishes on [sdk.Session.messages]. Each entry carries its speaker
/// label; newest entries are at the bottom and scroll into view automatically.
class TranscriptView extends StatelessWidget {
  const TranscriptView({super.key});

  @override
  Widget build(BuildContext context) => Consumer<sdk.Session>(
    builder: (ctx, session, _) {
      if (session.messages.isEmpty) {
        return _TranscriptPlaceholder(isAgentConnected: session.agent.isConnected);
      }
      return components.ChatScrollView(
        session: session,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        physics: const BouncingScrollPhysics(),
        messageBuilder: (ctx, message) => _TranscriptEntry(message: message),
      );
    },
  );
}

class _TranscriptEntry extends StatelessWidget {
  const _TranscriptEntry({required this.message});

  final sdk.ReceivedMessage message;

  /// Typed user input and speech-to-text both come from the person; anything
  /// else on the session is the agent speaking.
  bool get _isUserMessage => message.content is sdk.UserInput || message.content is sdk.UserTranscript;

  @override
  Widget build(BuildContext context) {
    final text = message.content.text.trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isUser = _isUserMessage;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isUser ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foreground = isUser ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 5, left: 4, right: 4),
            child: Text(
              isUser ? Branding.userSpeaker : Branding.agentSpeaker,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: foreground, height: 1.35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptPlaceholder extends StatelessWidget {
  const _TranscriptPlaceholder({required this.isAgentConnected});

  final bool isAgentConnected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq, size: 32, color: colorScheme.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              isAgentConnected ? 'Listening' : 'Connecting to the assistant',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (isAgentConnected)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Ask about my work, projects, or experience — the transcript appears here.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.outline, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
