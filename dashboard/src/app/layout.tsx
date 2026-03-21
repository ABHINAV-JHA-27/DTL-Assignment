import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MeetSpace Dashboard",
  description: "A LiveKit-powered meeting dashboard built with Next.js and Firebase.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
