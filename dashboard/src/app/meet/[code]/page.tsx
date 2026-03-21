import { notFound } from "next/navigation";
import { Room } from "@/components/meeting/Room";
import { isMeetingCodeFormatValid, normalizeMeetingCode } from "@/lib/meeting-code";

type MeetingPageProps = {
  params: Promise<{ code: string }>;
  searchParams?: Promise<{ name?: string }>;
};

export default async function MeetingPage({
  params,
  searchParams,
}: MeetingPageProps) {
  const { code } = await params;
  const { name } = (await searchParams) ?? {};
  const normalizedCode = normalizeMeetingCode(code);

  if (!isMeetingCodeFormatValid(normalizedCode)) {
    notFound();
  }

  return <Room roomCode={normalizedCode} initialUsername={name ?? ""} />;
}
