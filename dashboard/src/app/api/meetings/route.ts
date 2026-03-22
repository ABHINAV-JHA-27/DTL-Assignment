import { NextRequest, NextResponse } from "next/server";
import {
  createMeetingWithGeneratedCode,
  getMeeting,
} from "@/lib/firebase/meetings";
import { isMeetingCodeFormatValid, normalizeMeetingCode } from "@/lib/meeting-code";

export const runtime = "nodejs";

export async function GET(request: NextRequest) {
  try {
    const code = normalizeMeetingCode(
      request.nextUrl.searchParams.get("code")?.trim() ?? "",
    );

    if (!code) {
      return NextResponse.json(
        { error: "Meeting code is required." },
        { status: 400 },
      );
    }

    if (!isMeetingCodeFormatValid(code)) {
      return NextResponse.json(
        { error: "Enter a valid 9-character meeting code." },
        { status: 400 },
      );
    }

    const meeting = await getMeeting(code);

    if (!meeting) {
      return NextResponse.json(
        { error: "Meeting code not found. Check the code and try again." },
        { status: 404 },
      );
    }

    return NextResponse.json({
      code: meeting.code,
      exists: true,
    });
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unable to validate the meeting code.",
      },
      { status: 500 },
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      createdBy?: string;
    };
    const createdBy = body.createdBy?.trim();

    if (!createdBy) {
      return NextResponse.json(
        { error: "createdBy is required." },
        { status: 400 },
      );
    }

    const meeting = await createMeetingWithGeneratedCode(createdBy);

    return NextResponse.json(
      {
        code: meeting.code,
      },
      { status: 201 },
    );
  } catch (error) {
    return NextResponse.json(
      {
        error:
          error instanceof Error
            ? error.message
            : "Unable to create a meeting right now.",
      },
      { status: 500 },
    );
  }
}
