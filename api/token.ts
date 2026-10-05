import { randomUUID } from 'node:crypto';
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { AccessToken, RoomAgentDispatch, RoomConfiguration } from 'livekit-server-sdk';

/// Every request mints its own room so visitors never share a conversation.
const ROOM_PREFIX = 'cv-';

/// Long enough to start a call, short enough that a leaked token is near-useless.
/// The room stays open for as long as the session lives; this only bounds joins.
const TOKEN_TTL = '15m';

/// The agent worker registers under this name (see voice-cv `ServerOptions`).
/// Named workers are not auto-dispatched, so the token has to ask for this one
/// explicitly or the room would open with nobody to talk to.
const DEFAULT_AGENT_NAME = 'voice-cv';

const PARTICIPANT_NAME = 'Visitor';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // Credentials must never be cached by a browser or by the edge.
  res.setHeader('Cache-Control', 'no-store');

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const serverUrl = process.env.LIVEKIT_URL;
  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;

  if (!serverUrl || !apiKey || !apiSecret) {
    // Logged server-side only: the response must not describe what is missing.
    console.error('Missing LIVEKIT_URL, LIVEKIT_API_KEY or LIVEKIT_API_SECRET.');
    res.status(500).json({ error: 'Server is not configured' });
    return;
  }

  // Both names are generated here and the request body is ignored, so a caller
  // cannot ask for someone else's room or borrow another visitor's identity.
  const roomName = `${ROOM_PREFIX}${randomUUID()}`;
  const participantIdentity = `visitor-${randomUUID()}`;

  const token = new AccessToken(apiKey, apiSecret, {
    identity: participantIdentity,
    name: PARTICIPANT_NAME,
    ttl: TOKEN_TTL,
  });

  // Just enough to hold a conversation: join this one room, publish mic/camera
  // and text, subscribe to the agent. No room administration of any kind.
  token.addGrant({
    roomJoin: true,
    room: roomName,
    canPublish: true,
    canPublishData: true,
    canSubscribe: true,
  });

  // The room is created implicitly when the visitor joins, and this config is
  // what tells LiveKit to dispatch the agent into it.
  token.roomConfig = new RoomConfiguration({
    agents: [new RoomAgentDispatch({ agentName: process.env.LIVEKIT_AGENT_NAME || DEFAULT_AGENT_NAME })],
  });

  try {
    const participantToken = await token.toJwt();
    // Snake case is the wire format the LiveKit client SDKs expect.
    res.status(200).json({
      server_url: serverUrl,
      participant_token: participantToken,
      participant_name: PARTICIPANT_NAME,
      room_name: roomName,
    });
  } catch (error) {
    console.error('Failed to mint a LiveKit token', error);
    res.status(500).json({ error: 'Could not create a token' });
  }
}
