import { NextRequest, NextResponse } from "next/server";
import {
  getMeeting,
  updateMeetingRecordingState,
} from "@/lib/firebase/meetings";
import { createEgressClient } from "@/lib/livekit/server";
import { isMeetingCodeFormatValid, normalizeMeetingCode } from "@/lib/meeting-code";

export const runtime = "nodejs";

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      room?: string;
      egressId?: string | null;
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
    const targetEgressId =
      body.egressId?.trim() ||
      (
        await egressClient.listEgress({
          roomName: room,
          active: true,
        })
      )[0]?.egressId;

    if (!targetEgressId) {
      await updateMeetingRecordingState(room, {
        isRecording: false,
        egressId: null,
        startedBy: null,
      });

      return NextResponse.json(
        {
          egressId: null,
          status: "EGRESS_COMPLETE",
        },
      );
    }

    const info = await egressClient.stopEgress(targetEgressId);
    await updateMeetingRecordingState(room, {
      isRecording: false,
      egressId: null,
      startedBy: null,
    });

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
