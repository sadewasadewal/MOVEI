'use client';

import React from 'react';
import Link from 'next/link';
import { MOCK_MOVIES, MOCK_SHOWS, MOCK_BOOKINGS, MOCK_TICKETS } from '../../lib/mock-data';
import { ShieldCheck, Film, Calendar, Building2, Ticket, TrendingUp, Users, CheckCircle, Plus } from 'lucide-react';

export default function AdminDashboardPage() {
  const totalTicketsSold = MOCK_TICKETS.length;
  const totalRevenue = MOCK_BOOKINGS.reduce((sum, b) => sum + b.total_amount, 0);
  const activeShowsCount = MOCK_SHOWS.filter(s => s.status === 'scheduled').length;
  const admittedCount = MOCK_TICKETS.filter(t => t.status === 'used').length;

  return (
    <div className="max-w-7xl mx-auto px-4 lg:px-8 py-10 space-y-10">
      
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-white/10 pb-6">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-[#bae861]" />
            <span className="text-xs font-bold uppercase tracking-wider text-[#bae861]">
              Management Control Room
            </span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-black text-white mt-1">
            Cinema Operations Dashboard
          </h1>
          <p className="text-sm text-gray-400 mt-1">
            Monitor real-time ticket sales, scheduled shows, screen capacities, and gate entries.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/admin/movies/new"
            className="px-4 py-2.5 rounded-xl bg-[#bae861] text-black font-extrabold text-xs flex items-center gap-1.5 shadow-lg shadow-[#bae861]/20 hover:bg-[#cbf27a] transition-all"
          >
            <Plus className="w-4 h-4" />
            Add New Movie
          </Link>
          <Link
            href="/admin/shows"
            className="px-4 py-2.5 rounded-xl bg-white/10 hover:bg-white/15 text-white font-semibold text-xs border border-white/15 transition-colors"
          >
            Schedule Show
          </Link>
        </div>
      </div>

      {/* 4 KPI Metrics */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        
        <div className="glass-panel p-6 rounded-3xl border border-white/10 space-y-2">
          <div className="flex items-center justify-between text-gray-400">
            <span className="text-xs font-bold uppercase tracking-wider">Tickets Sold</span>
            <Ticket className="w-4 h-4 text-[#bae861]" />
          </div>
          <div className="text-3xl font-black text-white">{totalTicketsSold}</div>
          <div className="text-[11px] text-emerald-400 font-semibold flex items-center gap-1">
            <TrendingUp className="w-3 h-3" /> +18% from last week
          </div>
        </div>

        <div className="glass-panel p-6 rounded-3xl border border-white/10 space-y-2">
          <div className="flex items-center justify-between text-gray-400">
            <span className="text-xs font-bold uppercase tracking-wider">Gross Revenue</span>
            <TrendingUp className="w-4 h-4 text-[#fa6b38]" />
          </div>
          <div className="text-3xl font-black text-white">LKR {totalRevenue.toLocaleString()}</div>
          <div className="text-[11px] text-gray-400">Across 3 cinema venues</div>
        </div>

        <div className="glass-panel p-6 rounded-3xl border border-white/10 space-y-2">
          <div className="flex items-center justify-between text-gray-400">
            <span className="text-xs font-bold uppercase tracking-wider">Active Shows</span>
            <Calendar className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="text-3xl font-black text-white">{activeShowsCount}</div>
          <div className="text-[11px] text-gray-400">Scheduled across halls</div>
        </div>

        <div className="glass-panel p-6 rounded-3xl border border-white/10 space-y-2">
          <div className="flex items-center justify-between text-gray-400">
            <span className="text-xs font-bold uppercase tracking-wider">Admitted at Gates</span>
            <CheckCircle className="w-4 h-4 text-[#bae861]" />
          </div>
          <div className="text-3xl font-black text-[#bae861]">{admittedCount}</div>
          <div className="text-[11px] text-gray-400">Verified via Scanner PWA</div>
        </div>

      </div>

      {/* Admin Modules Navigation Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <Link
          href="/admin/movies"
          className="glass-panel p-6 rounded-3xl border border-white/10 space-y-3 glass-panel-hover"
        >
          <div className="w-10 h-10 rounded-xl bg-[#bae861]/15 text-[#bae861] flex items-center justify-center">
            <Film className="w-5 h-5" />
          </div>
          <h3 className="text-base font-extrabold text-white">Movie Catalog</h3>
          <p className="text-xs text-gray-400">
            Publish or archive movies. Enforces 2:3 posters and 16:9 backdrops with live preview.
          </p>
        </Link>

        <Link
          href="/admin/shows"
          className="glass-panel p-6 rounded-3xl border border-white/10 space-y-3 glass-panel-hover"
        >
          <div className="w-10 h-10 rounded-xl bg-[#fa6b38]/15 text-[#fa6b38] flex items-center justify-center">
            <Calendar className="w-5 h-5" />
          </div>
          <h3 className="text-base font-extrabold text-white">Showtime Scheduling</h3>
          <p className="text-xs text-gray-400">
            Configure showtimes with collision prevention, tiered seat pricing, and duplicate show tools.
          </p>
        </Link>

        <Link
          href="/admin/cinemas"
          className="glass-panel p-6 rounded-3xl border border-white/10 space-y-3 glass-panel-hover"
        >
          <div className="w-10 h-10 rounded-xl bg-purple-500/15 text-purple-400 flex items-center justify-center">
            <Building2 className="w-5 h-5" />
          </div>
          <h3 className="text-base font-extrabold text-white">Cinema Venues</h3>
          <p className="text-xs text-gray-400">
            Manage partner venues, IMAX and Dolby Atmos screens, and seat map row labels.
          </p>
        </Link>

        <Link
          href="/?tab=users"
          className="glass-panel p-6 rounded-3xl border border-white/10 space-y-3 glass-panel-hover"
        >
          <div className="w-10 h-10 rounded-xl bg-[#007aff]/15 text-[#007aff] flex items-center justify-center">
            <Users className="w-5 h-5" />
          </div>
          <h3 className="text-base font-extrabold text-white">Staff & Scanner Accounts</h3>
          <p className="text-xs text-gray-400">
            Provision staff credentials for door scanners and administrators to access the iOS mobile app.
          </p>
        </Link>
      </div>

      {/* Live Recent Bookings Table */}
      <div className="glass-panel p-6 sm:p-8 rounded-3xl border border-white/10 space-y-4">
        <div className="flex items-center justify-between border-b border-white/10 pb-4">
          <div>
            <h3 className="text-lg font-black text-white">Recent Transactions</h3>
            <span className="text-xs text-gray-400">Synchronized Supabase bookings</span>
          </div>
          <span className="text-xs font-mono text-[#bae861] bg-[#bae861]/10 px-2 py-1 rounded">
            Live Feed
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-white/10 text-gray-400 uppercase font-bold">
                <th className="py-3 px-2">Booking Ref</th>
                <th className="py-3 px-2">Movie</th>
                <th className="py-3 px-2">Seats</th>
                <th className="py-3 px-2">Amount</th>
                <th className="py-3 px-2">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {MOCK_BOOKINGS.map(booking => (
                <tr key={booking.id} className="hover:bg-white/5 transition-colors">
                  <td className="py-3 px-2 font-mono font-bold text-white">
                    {booking.booking_reference}
                  </td>
                  <td className="py-3 px-2 text-gray-200">
                    {booking.show?.movie?.title}
                  </td>
                  <td className="py-3 px-2 text-gray-400 font-mono">
                    {booking.tickets?.map(t => `${t.seat?.row_label}${t.seat?.seat_number}`).join(', ') || 'Seats'}
                  </td>
                  <td className="py-3 px-2 font-mono text-[#bae861] font-bold">
                    LKR {booking.total_amount.toLocaleString()}
                  </td>
                  <td className="py-3 px-2">
                    <span className="text-[10px] uppercase font-extrabold px-2 py-0.5 rounded bg-[#bae861]/20 text-[#bae861]">
                      {booking.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}
