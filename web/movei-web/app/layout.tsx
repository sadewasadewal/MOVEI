import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'MOVEI Cinema OS 🎬 | Admin Operations Studio',
  description: 'Central administrative portal for managing movies, shows, cinemas, ticket approvals, and in-app updates for MOVEI iOS.',
  icons: {
    icon: '/favicon.ico'
  }
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="h-full bg-[#070709] text-gray-100 antialiased dark">
      <body className="min-h-full flex flex-col bg-[#070709] text-gray-100 selection:bg-[#bae861] selection:text-black">
        <main className="flex-1 w-full flex flex-col">
          {children}
        </main>
      </body>
    </html>
  );
}
