import { supabase, isSupabaseConfigured } from '../lib/supabase';
import { ScanResponse } from '../types';
import { MOCK_TICKETS } from '../lib/mock-data';

export async function validateAndAdmitTicket(
  ticketCode: string,
  scannerId: string = 'u3333333-3333-3333-3333-333333333333',
  cinemaId: string = 'c1111111-1111-1111-1111-111111111111',
  deviceId?: string
): Promise<ScanResponse> {
  if (isSupabaseConfigured && supabase) {
    const { data, error } = await supabase.rpc('validate_and_admit_ticket', {
      p_ticket_code: ticketCode.trim(),
      p_scanner_id: scannerId,
      p_cinema_id: cinemaId,
      p_device_id: deviceId || 'web-browser-scanner'
    });
    if (error) {
      console.error('Scan RPC error:', error);
      return {
        valid: false,
        reason: 'invalid',
        message: error.message || 'Database error during scan'
      };
    }
    return data as ScanResponse;
  }

  // -------------------------------------------------------------------
  // Local file-based admission — persists to tickets.json via API
  // -------------------------------------------------------------------
  const staffName = 'Staff Scanner';

  // Call the REST API which writes to tickets.json
  try {
    const res = await fetch('/api/tickets', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action: 'scan_and_tear',
        ticketCode: ticketCode.trim(),
        scannerStaff: staffName,
      }),
    });

    const json = await res.json();

    if (res.status === 409) {
      // Already admitted
      return {
        valid: false,
        reason: 'already_used',
        message: json.message || 'Ticket was already admitted',
        ticket_code: json.ticket?.ticket_code,
        movie_title: json.ticket?.movie_title,
        customer_name: json.ticket?.customer_name,
        cinema_name: json.ticket?.cinema_name,
        screen_name: json.ticket?.screen_name,
        seat: json.ticket?.seat_label,
        showtime: json.ticket?.showtime,
      };
    }

    if (!res.ok || !json.success) {
      // Ticket not found in tickets.json — fallback to MOCK_TICKETS in-memory
      const ticket = MOCK_TICKETS.find(
        t =>
          t.ticket_code.toUpperCase() === ticketCode.trim().toUpperCase() ||
          t.barcode_value.toUpperCase() === ticketCode.trim().toUpperCase()
      );

      if (!ticket) {
        return { valid: false, reason: 'invalid', message: 'Ticket not found in system' };
      }

      if (ticket.status === 'used') {
        return {
          valid: false,
          reason: 'already_used',
          message: `Already admitted at ${ticket.scanned_at ? new Date(ticket.scanned_at).toLocaleTimeString() : 'earlier'}`,
        };
      }

      ticket.status = 'used';
      ticket.scanned_at = new Date().toISOString();
      ticket.scanned_by = scannerId;

      return {
        valid: true,
        reason: 'valid',
        ticket_code: ticket.ticket_code,
        movie_title: ticket.show?.movie?.title || 'Unknown Title',
        customer_name: 'Customer',
        cinema_name: ticket.show?.cinema?.name || 'Cinema Complex',
        screen_name: ticket.show?.screen?.name || 'Screen 1',
        seat: `${ticket.seat?.row_label ?? ''}${ticket.seat?.seat_number ?? ''}`,
        showtime: ticket.show?.start_time,
      };
    }

    // Success — ticket found in tickets.json and marked used
    const t = json.ticket;
    return {
      valid: true,
      reason: 'valid',
      ticket_code: t.ticket_code,
      movie_title: t.movie_title || 'Cinema Pass',
      customer_name: t.customer_name || 'Customer',
      cinema_name: t.cinema_name || 'Cinemax Colombo',
      screen_name: t.screen_name || 'Screen 04',
      seat: t.seat_label || 'General Admission',
      showtime: t.showtime,
    };
  } catch (err) {
    console.error('[scanner-service] fetch error:', err);
    return { valid: false, reason: 'invalid', message: 'Network error — check server' };
  }
}
