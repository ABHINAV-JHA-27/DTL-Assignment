import { NextRequest, NextResponse } from "next/server";
import {
  getMeeting,
  updateMeetingRecordingState,
} from "@/lib/firebase/meetings";
import { createEgressClient, createRecordingOutput } from "@/lib/livekit/server";
import { isMeetingCodeFormatValid, normalizeMeetingCode } from "@/lib/meeting-code";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      room?: string;
      requestedBy?: string;
    };
    const room = normalizeMeetingCode(body.room?.trim() ?? "");

    if (!room) {
      return NextResponse.json(
        { error: "room is required." },
        { status: 400 },
      );
    }

    if (!isMeetingCodeFormatValid(room)) {
      return NextResponse.json(
        { error: "Enter a valid 9-character meeting code." },
        { status: 400 },
      );
    }

    const meeting = await getMeeting(room);

    if (!meeting) {
      return NextResponse.json(
        { error: "Meeting code not found. Check the code and try again." },
        { status: 404 },
      );
    }

    const egressClient = createEgressClient();
    const activeEgress = await egressClient.listEgress({
      roomName: room,
      active: true,
    });

    if (activeEgress.length > 0) {
      await updateMeetingRecordingState(room, {
        isRecording: true,
        egressId: activeEgress[0].egressId,
        startedBy: body.requestedBy ?? null,
      });

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

    try {
      await updateMeetingRecordingState(room, {
        isRecording: true,
        egressId: info.egressId,
        startedBy: body.requestedBy ?? null,
      });
    } catch (error) {
      await egressClient.stopEgress(info.egressId);
      throw error;
    }

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
