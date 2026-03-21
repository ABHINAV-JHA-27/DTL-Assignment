import { NextRequest, NextResponse } from "next/server";
import { AccessToken } from "livekit-server-sdk";

export const runtime = "nodejs";

function createParticipantIdentity(username: string) {
  const normalized = username
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 32);

  const suffix = crypto.randomUUID().slice(0, 8);
  return `${normalized || "participant"}-${suffix}`;
}

export async function GET(request: NextRequest) {
  const room = request.nextUrl.searchParams.get("room")?.trim();
  const username = request.nextUrl.searchParams.get("username")?.trim();
  const apiKey = process.env.LIVEKIT_API_KEY;
  const apiSecret = process.env.LIVEKIT_API_SECRET;
  const serverUrl = process.env.NEXT_PUBLIC_LIVEKIT_URL;

  if (!room || !username) {
    return NextResponse.json(
      { error: "Both room and username are required." },
      { status: 400 },
    );
  }

  if (!apiKey || !apiSecret || !serverUrl) {
    return NextResponse.json(
      { error: "LiveKit server environment variables are not configured." },
      { status: 500 },
    );
  }

  try {
    const identity = createParticipantIdentity(username);
    const token = new AccessToken(apiKey, apiSecret, {
      identity,
      name: username,
      ttl: "1h",
    });

    token.addGrant({
      room,
      roomJoin: true,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    return NextResponse.json({
      token: await token.toJwt(),
      serverUrl,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unable to generate a participant token.",
      },
      { status: 500 },
    );
  }
}
