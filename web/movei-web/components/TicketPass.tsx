'use client';

import React, { useState } from 'react';
import { Ticket } from '../types';
import BarcodeView from './BarcodeView';
import { Calendar, Clock, MapPin, CheckCircle2, Download, Smartphone } from 'lucide-react';

interface TicketPassProps {
  ticket: Ticket;
  onTear?: (ticketId: string) => void;
}

export default function TicketPass({ ticket, onTear }: TicketPassProps) {
  const isUsedInitially = ticket.status === 'used';
  const [isTorn, setIsTorn] = useState(isUsedInitially);

  const movie = ticket.show?.movie;
  const cinema = ticket.show?.cinema;
  const screen = ticket.show?.screen;
  const seat = ticket.seat;
  const startTime = ticket.show?.start_time ? new Date(ticket.show.start_time) : new Date();

  const handleTear = () => {
    if (!isTorn) {
      setIsTorn(true);
      if (onTear) {
        onTear(ticket.id);
      }
    }
  };

  return (
    <div className="w-full max-w-sm mx-auto select-none transition-all duration-300">
      
      {/* Top Main Ticket Card */}
      <div 
        onClick={handleTear}
        className={`relative bg-[#161a22] border border-white/10 rounded-t-2xl overflow-hidden shadow-2xl transition-all duration-300 cursor-pointer ${
          isTorn ? 'border-b-0' : 'rounded-b-none'
        }`}
      >
        {/* Admitted Stamp watermark if torn */}
        {isTorn && (
          <div className="absolute top-4 right-4 z-20 transform rotate-12 border-2 border-[#bae861] text-[#bae861] font-black text-xs px-2.5 py-1 rounded tracking-widest uppercase bg-[#bae861]/10 backdrop-blur-sm animate-in fade-in zoom-in-75">
            ADMITTED
          </div>
        )}

        {/* Movie Poster Backdrop Strip */}
        <div className="h-32 w-full relative overflow-hidden bg-gray-900">
          {movie?.backdrop_url && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={movie.backdrop_url}
              alt={movie.title}
              className="w-full h-full object-cover opacity-50"
            />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-[#161a22] via-[#161a22]/60 to-transparent" />
          
          <div className="absolute bottom-3 left-4 right-4">
            <span className="text-[10px] font-bold uppercase tracking-wider text-[#bae861] bg-[#bae861]/10 px-2 py-0.5 rounded">
              {movie?.age_rating || 'PG-13'} • {movie?.runtime_minutes || 120}m
            </span>
            <h3 className="text-lg font-extrabold text-white mt-1 truncate">
              {movie?.title || 'Cinema Pass'}
            </h3>
          </div>
        </div>

        {/* Ticket Details */}
        <div className="p-4 space-y-3">
          <div className="flex items-center gap-2 text-xs text-gray-300">
            <MapPin className="w-3.5 h-3.5 text-[#bae861] shrink-0" />
            <span className="truncate">{cinema?.name || 'Colombo City Centre'}</span>
          </div>

          <div className="grid grid-cols-3 gap-2 bg-white/5 p-2.5 rounded-xl border border-white/5 text-center">
            <div>
              <span className="text-[10px] uppercase font-bold text-gray-400 block">Date</span>
              <span className="text-xs font-semibold text-white">
                {startTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
              </span>
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-gray-400 block">Time</span>
              <span className="text-xs font-semibold text-white">
                {startTime.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
              </span>
            </div>
            <div>
              <span className="text-[10px] uppercase font-bold text-gray-400 block">Seat</span>
              <span className="text-xs font-black text-[#bae861]">
                {seat ? `${seat.row_label}${seat.seat_number}` : 'F5'}
              </span>
            </div>
          </div>

          <div className="flex justify-between items-center text-[11px] text-gray-400 px-1 pt-1">
            <span>Screen: <strong className="text-gray-200">{screen?.name || 'Screen 1'}</strong></span>
            <span>Ref: <strong className="font-mono text-gray-200">{ticket.ticket_code}</strong></span>
          </div>
        </div>

        {/* Perforation Cutouts on sides */}
        <div className="relative w-full h-4 overflow-hidden">
          <div className="absolute -left-3 top-0 w-6 h-6 rounded-full bg-[#0b0d0f] border-r border-white/10" />
          <div className="absolute -right-3 top-0 w-6 h-6 rounded-full bg-[#0b0d0f] border-l border-white/10" />
          {/* Dashed perforation line */}
          <div className="absolute inset-x-4 top-2.5 border-b border-dashed border-gray-600" />
        </div>
      </div>

      {/* Torn space separation (normal ticket size, clean physical gap) */}
      <div 
        className="transition-all duration-300 overflow-hidden"
        style={{ height: isTorn ? '24px' : '0px' }}
      >
        {isTorn && (
          <div className="h-full flex items-center justify-center">
            <span className="text-[9px] uppercase tracking-widest text-[#bae861] font-bold">
              • Torn for Admission •
            </span>
          </div>
        )}
      </div>

      {/* Bottom Stub: Barcode */}
      <div 
        onClick={handleTear}
        className={`bg-[#161a22] border border-white/10 rounded-b-2xl p-4 shadow-2xl transition-all duration-300 cursor-pointer ${
          isTorn ? 'border-t rounded-t-xl' : 'border-t-0'
        }`}
      >
        <BarcodeView value={ticket.barcode_value || ticket.ticket_code} />

        {/* Pass Actions */}
        <div className="mt-3 pt-3 border-t border-white/10 flex items-center justify-between text-[10px] text-gray-500 font-mono">
          <span>Digital Cinema Admission</span>
          <span>
            {isTorn ? 'Status: Admitted' : 'Tap to tear ticket'}
          </span>
        </div>
      </div>

    </div>
  );
}
