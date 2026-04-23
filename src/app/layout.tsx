import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "交通費申請システム",
  description: "社員向け交通費申請・管理システム",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body className="min-h-screen bg-gray-50 text-gray-900 antialiased">
        {children}
      </body>
    </html>
  );
}
