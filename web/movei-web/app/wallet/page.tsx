'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { MOCK_TICKETS } from '../../lib/mock-data';
import { Ticket } from '../../types';
import BarcodeView from '../../components/BarcodeView';
import { MoreHorizontal, Trash2, RotateCcw, ChevronRight, Smartphone, CheckCircle2 } from 'lucide-react';

export default function WalletPage() {
  const [tickets, setTickets] = useState<Ticket[]>(MOCK_TICKETS);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const [tornTicketIds, setTornTicketIds] = useState<string[]>(['tk-103']); // tk-103 is used in seed
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const activeTicket = tickets[selectedIndex] || tickets[0];
  const isTorn = activeTicket ? tornTicketIds.includes(activeTicket.id) : false;

  const toggleTear = (ticketId: string) => {
    setTornTicketIds(prev =>
      prev.includes(ticketId) ? prev.filter(id => id !== ticketId) : [...prev, ticketId]
    );
  };

  const handleDeleteActive = () => {
    if (!activeTicket) return;
    setTickets(prev => prev.filter(t => t.id !== activeTicket.id));
    setSelectedIndex(0);
    setIsMenuOpen(false);
  };

  const handleClearAll = () => {
    if (confirm('Clear all passes from your wallet?')) {
      setTickets([]);
      setIsMenuOpen(false);
    }
  };

  // Stacked peek card indices (up to 2 cards behind)
  const peekIndices = () => {
    if (tickets.length <= 1) return [];
    const count = Math.min(tickets.length - 1, 2);
    const indices: number[] = [];
    for (let i = 1; i <= count; i++) {
      indices.push((selectedIndex + i) % tickets.length);
    }
    return indices.reverse();
  };

  return (
    <div className="ios-canvas min-h-screen pb-44 pt-4 sm:pt-8 px-4 max-w-lg mx-auto select-none">
      
      {/* 1. iOS Large Header & Three Dots Menu */}
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold font-sans tracking-tight text-[#14171a]">
          Movie Wallet
        </h1>

        <div className="relative">
          <button
            onClick={() => setIsMenuOpen(!isMenuOpen)}
            className="w-10 h-10 rounded-full flex items-center justify-center text-[#14171a] hover:bg-black/5 active:bg-black/10 transition-colors"
            title="Options"
          >
            <MoreHorizontal className="w-6 h-6" />
          </button>

          {isMenuOpen && (
            <div className="absolute right-0 mt-1 w-56 rounded-2xl bg-white shadow-2xl border border-black/5 py-1.5 z-40 animate-in fade-in zoom-in-95">
              {activeTicket && (
                <button
                  onClick={handleDeleteActive}
                  className="w-full px-4 py-2.5 text-xs text-rose-500 font-semibold flex items-center gap-2 hover:bg-rose-50 text-left"
                >
                  <Trash2 className="w-4 h-4" />
                  Delete Active Pass
                </button>
              )}
              {tickets.length > 0 && (
                <button
                  onClick={handleClearAll}
                  className="w-full px-4 py-2.5 text-xs text-rose-600 font-bold flex items-center gap-2 hover:bg-rose-50 border-t border-gray-100 text-left"
                >
                  <Trash2 className="w-4 h-4" />
                  Clear All Passes ({tickets.length})
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      {/* 2. Section Header: YOUR PASSES + X PASSES pill */}
      <div className="flex items-center justify-between mb-8">
        <span className="text-xs font-bold uppercase tracking-widest text-[#6b6e73]">
          YOUR PASSES
        </span>

        {tickets.length > 0 && (
          <span className="text-[11px] font-bold tracking-wider text-[#14171a] bg-white px-3 py-1 rounded-full shadow-sm">
            {tickets.length} {tickets.length === 1 ? 'PASS' : 'PASSES'}
          </span>
        )}
      </div>

      {tickets.length === 0 ? (
        /* Empty Wallet Card */
        <div className="ios-card p-12 text-center space-y-3">
          <div className="w-14 h-14 rounded-full bg-gray-100 flex items-center justify-center mx-auto text-gray-400">
            🎟️
          </div>
          <h3 className="text-base font-bold text-[#14171a]">No Upcoming Passes</h3>
          <p className="text-xs text-[#6b6e73] max-w-xs mx-auto">
            When you book cinema tickets, your passes will appear right here.
          </p>
          <Link
            href="/"
            className="inline-block mt-2 px-5 py-2.5 rounded-full bg-[#007AFF] text-white text-xs font-bold shadow"
          >
            Explore Movies
          </Link>
        </div>
      ) : (
        <>
          {/* 3. Stacked 3D Card Deck matching iOS WalletView */}
          <div className="relative mb-12" style={{ paddingTop: `${peekIndices().length * 34}px` }}>
            
            {/* Peek Cards stacked behind */}
            {peekIndices().map((idx, pos) => {
              const peekTicket = tickets[idx];
              const level = peekIndices().length - 1 - pos;
              const offsetY = -(level + 1) * 34;
              const scale = 1.0 - (level + 1) * 0.035;

              return (
                <div
                  key={peekTicket.id}
                  onClick={() => setSelectedIndex(idx)}
                  className="absolute inset-x-0 rounded-3xl overflow-hidden shadow-md cursor-pointer transition-all duration-300"
                  style={{
                    top: 0,
                    transform: `translateY(${offsetY}px) scale(${scale})`,
                    zIndex: pos + 1
                  }}
                >
                  <div className="h-28 w-full relative bg-gray-900 overflow-hidden">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={peekTicket.show?.movie?.backdrop_url || peekTicket.show?.movie?.poster_url}
                      alt={peekTicket.show?.movie?.title}
                      className="w-full h-full object-cover opacity-70"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                    <div className="absolute top-3 left-4 text-[10px] font-black tracking-widest text-[#bae861]">
                      MOVEI CINEMA
                    </div>
                  </div>
                </div>
              );
            })}

            {/* Active Ticket Card (1:1 iOS WalletTicketCard) */}
            <div 
              className="relative z-20 transition-all duration-300 cursor-pointer"
              onClick={() => toggleTear(activeTicket.id)}
            >
              {/* Upper Section: Image + Dark Ink Details */}
              <div className="rounded-t-3xl overflow-hidden shadow-xl bg-[#14171a]">
                
                {/* Backdrop header */}
                <div className="relative h-64 sm:h-72 w-full overflow-hidden bg-black">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={activeTicket.show?.movie?.backdrop_url || activeTicket.show?.movie?.poster_url}
                    alt={activeTicket.show?.movie?.title}
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-transparent to-black/90" />

                  {/* Header bar */}
                  <div className="absolute top-4 inset-x-5 flex justify-between items-start text-white">
                    <div className="flex flex-col">
                      <span className="text-sm font-black tracking-wider text-white">MOVEI</span>
                      <span className="text-[10px] font-bold tracking-widest text-[#bae861]">CINEMA</span>
                    </div>
                    <div className="text-right">
                      <span className="text-xs font-bold block">
                        {new Date(activeTicket.show?.start_time || Date.now()).toLocaleDateString('en-US', { day: 'numeric', month: 'short' })}
                      </span>
                      <span className="text-[11px] font-medium text-white/80 block">
                        {new Date(activeTicket.show?.start_time || Date.now()).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  </div>

                  {/* Movie Title */}
                  <div className="absolute bottom-3 left-5 right-5">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-[#bae861] block mb-1">
                      MOVIE PASS
                    </span>
                    <h2 className="text-2xl font-bold text-white tracking-tight leading-tight">
                      {activeTicket.show?.movie?.title}
                    </h2>
                  </div>
                </div>

                {/* Venue, Screen, Seats row */}
                <div className="px-5 py-4 flex justify-between items-center text-white border-t border-white/10">
                  <div>
                    <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider block">Venue</span>
                    <span className="text-xs font-semibold text-white">
                      {activeTicket.show?.cinema?.name || 'Scope Cinemas'}
                    </span>
                  </div>
                  <div>
                    <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider block">Screen</span>
                    <span className="text-xs font-semibold text-white">
                      {activeTicket.show?.screen?.screen_number ? String(activeTicket.show.screen.screen_number).padStart(2, '0') : '04'}
                    </span>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] uppercase font-bold text-gray-400 tracking-wider block">Seats</span>
                    <span className="text-xs font-bold text-white">
                      {activeTicket.seat ? `${activeTicket.seat.row_label}${activeTicket.seat.seat_number}` : 'B4 • B5'}
                    </span>
                  </div>
                </div>

                {/* Perforation Line with Punch Cutouts matching iOS */}
                <div 
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleTear(activeTicket.id);
                  }}
                  className="relative w-full h-6 overflow-hidden bg-[#14171a] cursor-pointer hover:opacity-90"
                  title="Tap to tear ticket"
                >
                  <div className="absolute -left-3 top-0 w-6 h-6 rounded-full bg-[#f2f2f7]" />
                  <div className="absolute -right-3 top-0 w-6 h-6 rounded-full bg-[#f2f2f7]" />
                  <div className="absolute inset-x-5 top-3 border-b border-dashed border-gray-500" />
                </div>
              </div>

              {/* Physical Tear Separation Gap */}
              <div 
                className="transition-all duration-300 overflow-hidden flex items-center justify-center"
                style={{ height: isTorn ? '22px' : '0px' }}
              >
                {isTorn && (
                  <span className="text-[9px] uppercase tracking-widest text-[#6b6e73] font-bold">
                    • Torn for Admission •
                  </span>
                )}
              </div>

              {/* Lower Section: Pure White Stub with Barcode */}
              <div className={`bg-white rounded-b-3xl p-5 shadow-xl transition-all duration-300 ${isTorn ? 'rounded-t-2xl' : ''}`}>
                <div className="relative">
                  
                  {/* Barcode SVG */}
                  <div className={isTorn ? 'opacity-40' : 'opacity-100'}>
                    <BarcodeView 
                      value={activeTicket.barcode_value || activeTicket.ticket_code} 
                      showText={false}
                    />
                    <div className="text-center font-mono text-[11px] text-[#6b6e73] mt-1 font-semibold tracking-widest">
                      {activeTicket.ticket_code}
                    </div>
                  </div>

                  {/* Red ADMITTED Ink Stamp (1:1 iOS TicketDetailView) */}
                  {isTorn && (
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none animate-in zoom-in-90 duration-200">
                      <div className="border-2 border-red-500 border-dashed rounded-lg px-5 py-2 text-red-500 transform -rotate-6 bg-red-50/80 backdrop-blur-sm shadow-sm flex flex-col items-center">
                        <div className="flex items-center gap-1.5 text-lg font-black tracking-widest">
                          <CheckCircle2 className="w-5 h-5 fill-red-500 text-white" />
                          <span>ADMITTED</span>
                        </div>
                        <span className="text-[10px] font-bold tracking-wider text-red-600">
                          {new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })} • Gate 1
                        </span>
                      </div>
                    </div>
                  )}

                </div>

                {/* Tape Ticket Back Undo button when torn */}
                {isTorn && (
                  <div className="text-center mt-3 pt-2 border-t border-gray-100">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        toggleTear(activeTicket.id);
                      }}
                      className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6b6e73] hover:text-black"
                    >
                      <RotateCcw className="w-3.5 h-3.5" />
                      Tape Ticket Back
                    </button>
                  </div>
                )}
              </div>

            </div>
          </div>

          {/* 4. ALL PASSES List matching iOS WalletView */}
          {tickets.length > 1 && (
            <div className="space-y-3 mt-8">
              <span className="text-xs font-bold uppercase tracking-widest text-[#6b6e73] block mb-2">
                ALL PASSES
              </span>

              {tickets.map((ticket, index) => (
                <div
                  key={ticket.id}
                  onClick={() => setSelectedIndex(index)}
                  className={`ios-card p-3.5 flex items-center gap-3.5 cursor-pointer transition-all active:scale-[0.98] ${
                    index === selectedIndex ? 'ring-2 ring-[#14171a]' : ''
                  }`}
                >
                  {/* Poster Thumbnail */}
                  <div className="w-14 h-14 rounded-xl overflow-hidden bg-gray-900 shrink-0">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={ticket.show?.movie?.poster_url || ticket.show?.movie?.backdrop_url}
                      alt={ticket.show?.movie?.title}
                      className="w-full h-full object-cover"
                    />
                  </div>

                  <div className="flex-1 min-w-0">
                    <span className="text-[10px] uppercase font-bold text-[#6b6e73] tracking-wider block">
                      NEXT MOVIE
                    </span>
                    <h4 className="text-sm font-bold text-[#14171a] truncate">
                      {ticket.show?.movie?.title}
                    </h4>
                    <span className="text-xs text-[#6b6e73]">
                      {new Date(ticket.show?.start_time || Date.now()).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short' })} at {new Date(ticket.show?.start_time || Date.now()).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>

                  <ChevronRight className="w-4 h-4 text-gray-400 shrink-0" />
                </div>
              ))}
            </div>
          )}
        </>
      )}

    </div>
  );
}
