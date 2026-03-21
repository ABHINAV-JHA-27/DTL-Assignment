const MEETING_CODE_LENGTH = 9;
const MEETING_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function normalizeMeetingCode(code: string) {
  return code.trim().toUpperCase().replace(/\s+/g, "");
}

export function isMeetingCodeFormatValid(code: string) {
  return /^[A-Z0-9]{9}$/.test(normalizeMeetingCode(code));
}

export function generateMeetingCode() {
  return Array.from({ length: MEETING_CODE_LENGTH }, () => {
    const index = Math.floor(Math.random() * MEETING_CODE_ALPHABET.length);
    return MEETING_CODE_ALPHABET[index];
  }).join("");
}

export function getDefaultUsername() {
  const suffix = Math.floor(1000 + Math.random() * 9000);
  return `Guest ${suffix}`;
}
