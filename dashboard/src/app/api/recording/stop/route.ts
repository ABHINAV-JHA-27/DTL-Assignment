import { NextRequest, NextResponse } from "next/server";
import { createEgressClient } from "@/lib/livekit/server";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      room?: string;
      egressId?: string | null;
    };
    const room = body.room?.trim();

    if (!room) {
      return NextResponse.json(
        { error: "room is required." },
        { status: 400 },
      );
    }

    const egressClient = createEgressClient();
    const targetEgressId =
      body.egressId?.trim() ||
      (
        await egressClient.listEgress({
          roomName: room,
          active: true,
        })
      )[0]?.egressId;

    if (!targetEgressId) {
      return NextResponse.json(
        { error: "No active recording found for this room." },
        { status: 404 },
      );
    }

    const info = await egressClient.stopEgress(targetEgressId);

    return NextResponse.json({
      egressId: info.egressId,
      status: info.status,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unable to stop recording.",
      },
      { status: 500 },
    );
  }
}
