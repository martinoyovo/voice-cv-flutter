# Martino Yovo — Voice CV

A personal page with a voice agent that answers questions about my work. Built on
[LiveKit Agents](https://docs.livekit.io/agents/overview/) with the
[LiveKit Flutter SDK](https://github.com/livekit/client-sdk-flutter), deployed to Vercel as a web app.

The Flutter client runs on web, iOS, macOS, and Android. The voice agent itself lives in a separate
project (`voice-cv`) and registers with LiveKit under the agent name `voice-cv`.

## How it connects

```
browser ──POST /api/token──> Vercel function ──mints JWT──> LiveKit Cloud
   │                         (api/token.ts)                      │
   └──────────── WebRTC, room "cv-<uuid>" ───────────────────────┘
                                   ▲
                         voice-cv agent worker
                      (dispatched by the token's room config)
```

`api/token.ts` is the only place the LiveKit API key and secret exist. For each request it:

- generates a **fresh room** (`cv-<uuid>`) and a **fresh participant identity**, both server-side —
  the request body is ignored, so a caller cannot ask for someone else's room;
- grants only what a conversation needs (`roomJoin` on that one room, publish, subscribe) with a
  15-minute TTL and no room-administration rights;
- attaches a `RoomConfiguration` that explicitly dispatches the `voice-cv` agent. This is required:
  a worker registered with an `agentName` is **not** auto-dispatched to new rooms, so without it the
  room would open with nobody in it.

The client never sees a credential. `lib/controllers/app_ctrl.dart` points an
`EndpointTokenSource` at `/api/token`, resolved against the current page.

## Local development

Run the agent (in the `voice-cv` project) and the Flutter app side by side:

```bash
# in voice-cv/
pnpm dev

# here
flutter pub get
flutter run -d chrome
```

`flutter run -d chrome` serves the app without the Vercel function, so `/api/token` will 404. To get
a working token locally, run the whole thing through the Vercel CLI instead:

```bash
flutter build web
npx vercel dev
```

`vercel dev` serves `build/web` and runs `api/token.ts` on the same origin, which is what the
deployed site does. It reads the three LiveKit variables from `.env.local` — pull them down with
`npx vercel env pull .env.local`.

### Native builds

A native build has no page to resolve `/api/token` against, so pass the deployed endpoint at build
time:

```bash
flutter build apk --dart-define=TOKEN_ENDPOINT=https://<your-deployment>/api/token
```

## Deploying

The project is configured so `build/web` is the site and `api/` are serverless functions
(see `vercel.json`).

```bash
flutter build web --release
npx vercel deploy --prod
```

`scripts/vercel-build.sh` reuses the `build/web` you just uploaded. If it is missing — a
Git-triggered deploy, for instance — the script fetches the pinned Flutter SDK and builds from
source instead, so both paths work. Bump `FLUTTER_VERSION` there when you upgrade Flutter.

### Environment variables

Three variables, set on the Vercel project (Production, Preview, Development):

| Variable | Source |
| --- | --- |
| `LIVEKIT_URL` | LiveKit Cloud project settings (`wss://…`) |
| `LIVEKIT_API_KEY` | LiveKit Cloud → Settings → Keys |
| `LIVEKIT_API_SECRET` | LiveKit Cloud → Settings → Keys |

`LIVEKIT_AGENT_NAME` is optional and defaults to `voice-cv`; set it if the agent worker ever
registers under a different name.

### Known gap: no rate limiting

`/api/token` is unauthenticated and unthrottled. Keys stay server-side and rooms are isolated per
visitor, but anyone can POST it in a loop and run up LiveKit usage. Before this page sees real
traffic, put a limit in front of it — [Vercel WAF rate limiting](https://vercel.com/docs/vercel-waf/rate-limiting-sdk)
or a KV-backed counter keyed on IP.

## The app

### Branding and copy

Name, tagline, button label, and the transcript speaker labels all live in `lib/branding.dart`.

### Live transcript

While connected, `lib/widgets/transcript_view.dart` renders a scrolling transcript of the
conversation from `session.messages`, labelling each entry **You** or **Assistant**. LiveKit supplies
both sides: `UserTranscript` (speech-to-text) and `UserInput` (typed) for the visitor,
`AgentTranscript` for the agent. The transcript is the default view on connect; the control bar
toggles over to a full-screen audio visualizer.

### Text, video, and voice input

- **Voice**: microphone audio. **Requires microphone permissions.**
- **Text**: the message bar, for visitors who would rather type.
- **Video**: optional camera / screen share, if the agent is set up to process visual input.

Docs: [voice](https://docs.livekit.io/agents/start/voice-ai/) ·
[text](https://docs.livekit.io/agents/build/text/) ·
[vision](https://docs.livekit.io/agents/build/vision/#video) ·
[screen share](https://docs.livekit.io/home/client/tracks/screenshare/)

### Session

Built around two objects:

- `livekit_client.Session` — connects to LiveKit, dispatches and observes the agent, and exposes the
  message history via `session.messages` plus helpers like `session.sendText(...)`.
- `livekit_components.RoomContext` / `MediaDeviceContext` — local media tracks (microphone, camera,
  screen share) and their lifecycle.

### Preconnect audio buffer

`preConnectAudio` is on by default, buffering audio before the room connection finishes so the call
feels instant. Turn it off in `SessionOptions` in `lib/controllers/app_ctrl.dart`.

### Virtual avatar / agent video

If the agent publishes a video track (for example via a
[virtual avatar](https://docs.livekit.io/agents/integrations/avatar/)), the app renders it and falls
back to the audio visualizer otherwise.

## Credits

Built from LiveKit's [agent-starter-flutter](https://github.com/livekit-examples/agent-starter-flutter)
template, which is open source under the Apache 2.0 licence (see `LICENSE`).
