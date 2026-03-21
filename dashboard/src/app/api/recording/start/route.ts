import { NextRequest, NextResponse } from "next/server";
import { createEgressClient, createRecordingOutput } from "@/lib/livekit/server";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      room?: string;
      requestedBy?: string;
    };
    const room = body.room?.trim();

    if (!room) {
      return NextResponse.json(
        { error: "room is required." },
        { status: 400 },
      );
    }

    const egressClient = createEgressClient();
    const activeEgress = await egressClient.listEgress({
      roomName: room,
      active: true,
    });

    if (activeEgress.length > 0) {
      return NextResponse.json({
        egressId: activeEgress[0].egressId,
        status: activeEgress[0].status,
        requestedBy: body.requestedBy ?? null,
      });
    }

    const info = await egressClient.startRoomCompositeEgress(
      room,
      {
        file: createRecordingOutput(room),
      },
      {
        layout: process.env.LIVEKIT_EGRESS_LAYOUT ?? "speaker-dark",
      },
    );

    return NextResponse.json({
      egressId: info.egressId,
      status: info.status,
      requestedBy: body.requestedBy ?? null,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unable to start recording.",
      },
      { status: 500 },
    );
  }
}
