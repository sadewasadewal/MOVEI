'use client';

import React, { use, useState, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { MOCK_SHOWS } from '../../../lib/mock-data';
import { getScreenSeats } from '../../../services/cinema-service';
import { holdSeats, confirmBooking } from '../../../services/booking-service';
import { Seat, Show } from '../../../types';
import SeatMap from '../../../components/SeatMap';
import { ArrowLeft, Clock, Ticket, ShieldCheck, CheckCircle2, AlertCircle } from 'lucide-react';

interface BookingPageProps {
  params: Promise<{ showId: string }>;
}

export default function BookingPage({ params }: BookingPageProps) {
  const resolvedParams = use(params);
  const router = useRouter();

  const show = MOCK_SHOWS.find(s => s.id === resolvedParams.showId) || MOCK_SHOWS[0];

  const [seats, setSeats] = useState<Seat[]>([]);
  const [selectedSeatIds, setSelectedSeatIds] = useState<string[]>([]);
  const [timeLeft, setTimeLeft] = useState<number>(600); // 10 minutes in seconds
  const [isHolding, setIsHolding] = useState<boolean>(false);
  const [isCheckingOut, setIsCheckingOut] = useState<boolean>(false);
  const [bookingSuccessRef, setBookingSuccessRef] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Load seats
  useEffect(() => {
    async function loadSeats() {
      const screenSeats = await getScreenSeats(show.screen_id, show.id);
      setSeats(screenSeats);
    }
    loadSeats();
  }, [show.id, show.screen_id]);

  // Countdown timer
  useEffect(() => {
    if (timeLeft <= 0) return;
    const interval = setInterval(() => {
      setTimeLeft(prev => Math.max(0, prev - 1));
    }, 1000);
    return () => clearInterval(interval);
  }, [timeLeft]);

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;
  const timeFormatted = `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;

  const toggleSeat = (seat: Seat) => {
    if (seat.status === 'sold') return;

    setSelectedSeatIds(prev => {
      if (prev.includes(seat.id)) {
        return prev.filter(id => id !== seat.id);
      } else {
        if (prev.length >= 6) {
          setErrorMsg('Maximum 6 seats can be selected per transaction.');
          return prev;
        }
        setErrorMsg(null);
        return [...prev, seat.id];
      }
    });
  };

  // Calculate pricing
  const selectedSeats = seats.filter(s => selectedSeatIds.includes(s.id));
  const totalPrice = selectedSeats.reduce((sum, seat) => {
    if (seat.seat_type === 'vip') return sum + show.price_vip;
    if (seat.seat_type === 'premium') return sum + show.price_premium;
    return sum + show.price_standard;
  }, 0);

  const handleCheckout = async () => {
    if (selectedSeatIds.length === 0) return;

    try {
      setIsHolding(true);
      setErrorMsg(null);

      // 1. Hold seats atomically via stored procedure
      const holdResult = await holdSeats(show.id, selectedSeatIds);

      // 2. Simulate payment confirmation & confirm booking atomically
      const confirmResult = await confirmBooking(holdResult.booking_id);

      setBookingSuccessRef(confirmResult.booking_reference);
      setIsHolding(false);
    } catch (err: any) {
      console.error(err);
      setErrorMsg(err.message || 'Failed to complete seat hold reservation.');
      setIsHolding(false);
    }
  };

  return (
    <div className="max-w-7xl mx-auto px-4 lg:px-8 py-8 space-y-8">
      
      {/* Top Header Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-white/10 pb-6">
        <div className="flex items-center gap-4">
          <Link
            href={`/movies/${show.movie?.slug || ''}`}
            className="p-2 rounded-xl glass-panel hover:bg-white/10 text-gray-300 border border-white/10 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <div>
            <h1 className="text-2xl font-black text-white">{show.movie?.title}</h1>
            <p className="text-xs text-gray-400">
              {show.cinema?.name} • {show.screen?.name} • {new Date(show.start_time).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
            </p>
          </div>
        </div>

        {/* 10-min Countdown Hold Timer */}
        <div className="flex items-center gap-2.5 px-4 py-2 rounded-xl bg-white/5 border border-white/10 w-fit">
          <Clock className={`w-4 h-4 ${timeLeft < 120 ? 'text-rose-500 animate-pulse' : 'text-[#bae861]'}`} />
          <div className="flex flex-col">
            <span className="text-[10px] uppercase font-bold text-gray-400">Hold Timer</span>
            <span className={`text-xs font-mono font-black ${timeLeft < 120 ? 'text-rose-400' : 'text-[#bae861]'}`}>
              {timeFormatted}
            </span>
          </div>
        </div>
      </div>

      {errorMsg && (
        <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0 text-rose-400" />
          <span>{errorMsg}</span>
        </div>
      )}

      {/* Main Seat Map Area */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
        
        {/* Left 2 Cols: Screen & Interactive Grid */}
        <div className="lg:col-span-2 glass-panel p-6 sm:p-10 rounded-3xl border border-white/10">
          <SeatMap
            seats={seats}
            selectedSeatIds={selectedSeatIds}
            onToggleSeat={toggleSeat}
            show={show}
          />
        </div>

        {/* Right Col: Booking Summary & Atomic Checkout */}
        <div className="glass-panel p-6 rounded-3xl border border-white/10 space-y-6 sticky top-24">
          <div className="border-b border-white/10 pb-4">
            <h3 className="text-base font-extrabold text-white">Order Summary</h3>
            <span className="text-xs text-gray-400">Review selected cinema seats</span>
          </div>

          {/* Selected Seat Badges */}
          <div className="space-y-2">
            <span className="text-xs font-semibold text-gray-400">Selected Seats:</span>
            {selectedSeats.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {selectedSeats.map(seat => (
                  <span
                    key={seat.id}
                    className="px-2.5 py-1 rounded-lg bg-[#bae861]/15 border border-[#bae861]/40 text-[#bae861] font-mono font-bold text-xs"
                  >
                    Row {seat.row_label}-{seat.seat_number} ({seat.seat_type.toUpperCase()})
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-xs text-gray-500 italic">No seats selected yet. Click on the map to choose.</p>
            )}
          </div>

          {/* Pricing breakdown */}
          <div className="space-y-2 text-xs border-t border-white/10 pt-4">
            <div className="flex justify-between text-gray-400">
              <span>Tickets ({selectedSeats.length})</span>
              <span>LKR {totalPrice.toLocaleString()}</span>
            </div>
            <div className="flex justify-between text-gray-400">
              <span>Convenience Fee (Tax inc.)</span>
              <span>LKR 0.00</span>
            </div>
            <div className="flex justify-between text-white font-extrabold text-sm pt-2 border-t border-white/10">
              <span>Total Amount</span>
              <span className="text-[#bae861]">LKR {totalPrice.toLocaleString()}</span>
            </div>
          </div>

          {/* Checkout Button */}
          <button
            onClick={handleCheckout}
            disabled={selectedSeats.length === 0 || isHolding}
            className={`w-full py-3.5 rounded-xl font-extrabold text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-xl transition-all ${
              selectedSeats.length > 0 && !isHolding
                ? 'bg-[#bae861] hover:bg-[#cbf27a] text-black shadow-[#bae861]/25 hover:scale-[1.02]'
                : 'bg-white/10 text-gray-500 cursor-not-allowed'
            }`}
          >
            {isHolding ? (
              <>
                <span className="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
                Reserving Seats...
              </>
            ) : (
              <>
                <Ticket className="w-4 h-4" />
                Pay & Confirm Booking
              </>
            )}
          </button>

          <div className="flex items-center gap-2 text-[11px] text-gray-500 justify-center">
            <ShieldCheck className="w-3.5 h-3.5 text-[#bae861]" />
            <span>Encrypted checkout • Instant digital wallet pass</span>
          </div>
        </div>

      </div>

      {/* Success Modal */}
      {bookingSuccessRef && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-md z-50 flex items-center justify-center p-4">
          <div className="glass-panel max-w-md w-full p-8 rounded-3xl border border-[#bae861]/30 text-center space-y-5 animate-in zoom-in-95 duration-200">
            <div className="w-16 h-16 rounded-full bg-[#bae861]/20 border-2 border-[#bae861] flex items-center justify-center mx-auto text-[#bae861]">
              <CheckCircle2 className="w-8 h-8" />
            </div>

            <div className="space-y-1">
              <span className="text-xs uppercase font-extrabold tracking-widest text-[#bae861]">Booking Confirmed!</span>
              <h3 className="text-2xl font-black text-white">You&apos;re Going to the Movies</h3>
              <p className="text-xs text-gray-400">
                Ref: <strong className="text-white font-mono">{bookingSuccessRef}</strong>
              </p>
            </div>

            <p className="text-xs text-gray-300 leading-relaxed bg-white/5 p-3 rounded-xl border border-white/5">
              Your digital cinema pass is now active in your MOVEI wallet with all selected seats ready for admission.
            </p>

            <div className="flex items-center gap-3 pt-2">
              <Link
                href="/wallet"
                className="flex-1 py-3 rounded-xl bg-[#bae861] text-black font-extrabold text-xs text-center shadow-lg shadow-[#bae861]/25 hover:bg-[#cbf27a] transition-all"
              >
                Go to My Wallet
              </Link>
              <Link
                href="/"
                className="px-4 py-3 rounded-xl bg-white/10 text-white font-bold text-xs hover:bg-white/20 transition-all"
              >
                Home
              </Link>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
