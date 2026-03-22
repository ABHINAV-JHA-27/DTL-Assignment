import test from "node:test";
import assert from "node:assert/strict";
import {
  generateMeetingCode,
  getDefaultUsername,
  isMeetingCodeFormatValid,
  normalizeMeetingCode,
} from "./meeting-code.ts";

test("normalizeMeetingCode trims, uppercases, and removes spaces", () => {
  assert.equal(normalizeMeetingCode(" ab c12 def "), "ABC12DEF");
});

test("isMeetingCodeFormatValid accepts a normalized 9-character code", () => {
  assert.equal(isMeetingCodeFormatValid("abc12defg"), true);
  assert.equal(isMeetingCodeFormatValid("ABC12DEF"), false);
  assert.equal(isMeetingCodeFormatValid("ABCD!2DEFG"), false);
});

test("generateMeetingCode returns a valid 9-character code", () => {
  const code = generateMeetingCode();

  assert.equal(code.length, 9);
  assert.match(code, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{9}$/);
});

test("getDefaultUsername returns a guest label", () => {
  const username = getDefaultUsername();

  assert.match(username, /^Guest \d{4}$/);
});
