import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const ticketsFilePath = path.join(process.cwd(), 'data', 'tickets.json');

function getTickets(): any[] {
  try {
    if (!fs.existsSync(ticketsFilePath)) {
      fs.writeFileSync(ticketsFilePath, JSON.stringify([], null, 2), 'utf8');
      return [];
    }
    const data = fs.readFileSync(ticketsFilePath, 'utf8');
    const parsed = JSON.parse(data);
    return parsed.map((t: any) => {
      if (t.torn || t.scanned_at) {
        return { ...t, status: 'used', torn: true };
      }
      return t;
    });
  } catch (err) {
    console.error('Error reading tickets:', err);
    return [];
  }
}

function saveTickets(tickets: any[]) {
  try {
    const dir = path.dirname(ticketsFilePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    const cleanTickets = tickets.map((t: any) => {
      if (t.torn || t.scanned_at) {
        return { ...t, status: 'used', torn: true };
      }
      return t;
    });
    fs.writeFileSync(ticketsFilePath, JSON.stringify(cleanTickets, null, 2), 'utf8');
  } catch (err) {
    console.error('Error saving tickets:', err);
  }
}

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const code = searchParams.get('code');
    const tickets = getTickets();

    if (code) {
      const cleanCode = code.trim().toLowerCase();
      const ticket = tickets.find(
        t => t.ticket_code?.toLowerCase() === cleanCode || t.barcode_value?.toLowerCase() === cleanCode
      );
      if (!ticket) {
        return NextResponse.json({ success: false, message: 'Ticket not found' }, { status: 404 });
      }
      return NextResponse.json({ success: true, ticket });
    }

    return NextResponse.json(tickets);
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to fetch tickets' }, { status: 500 });
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();
    const tickets = getTickets();

    // Special Action: Scan, Validate & Tear
    if (body.action === 'scan_and_tear' || body.action === 'admit') {
      const barcode = (body.ticketCode || body.barcode || '').trim();
      const scannerStaff = body.scannerStaff || body.scannerName || 'Staff Scanner';
      const cinemaName = body.cinemaName || body.cinema || 'Cinemax Colombo';

      const existingIndex = tickets.findIndex(
        t =>
          t.ticket_code?.toLowerCase() === barcode.toLowerCase() ||
          t.barcode_value?.toLowerCase() === barcode.toLowerCase() ||
          t.id === barcode
      );

      const now = new Date().toISOString();

      if (existingIndex !== -1) {
        const ticket = tickets[existingIndex];

        if (ticket.status === 'used') {
          return NextResponse.json(
            {
              success: false,
              alreadyUsed: true,
              message: `Ticket was already admitted at ${new Date(ticket.scanned_at || now).toLocaleTimeString()}`,
              ticket
            },
            { status: 409 }
          );
        }

        // Validate and tear the ticket
        const updatedTicket = {
          ...ticket,
          status: 'used',
          scanned_at: now,
          scanned_by: scannerStaff,
          torn: true
        };

        tickets[existingIndex] = updatedTicket;
        saveTickets(tickets);

        return NextResponse.json({
          success: true,
          valid: true,
          action: 'torn',
          message: 'Ticket successfully validated and torn.',
          ticket: updatedTicket
        });
      } else {
        // Create admission record for the scanned ticket
        const newTicket = {
          id: `t-${Date.now()}`,
          booking_id: barcode.split('-').slice(0, 2).join('-') || 'MOV-SCANNED',
          show_id: 'show-external',
          customer_name: (body.customerName || '').trim() || 'Customer',
          movie_title: body.movieTitle || 'Cinema Pass',
          cinema_name: cinemaName,
          screen_name: body.screenName || 'Screen 04',
          seat_label: body.seat || 'General Admission',
          ticket_code: barcode,
          barcode_value: barcode,
          status: 'used',
          torn: true,
          scanned_at: now,
          scanned_by: scannerStaff,
          created_at: now
        };

        tickets.unshift(newTicket);
        saveTickets(tickets);

        return NextResponse.json({
          success: true,
          valid: true,
          action: 'torn',
          message: 'Ticket verified and torn on entry.',
          ticket: newTicket
        });
      }
    }

    // Default: Insert or update booked ticket
    const newTicket = {
      id: body.id || `t-${Date.now()}`,
      booking_id: body.booking_id || body.bookingID || 'MOV-BOOK',
      show_id: body.show_id || body.showID || 'show-01',
      user_id: body.user_id || body.userID || 'guest',
      customer_name: (body.customer_name || body.customerName || '').trim() || 'Customer',
      customer_email: body.customer_email || body.email || '',
      movie_title: body.movie_title || body.movieTitle || 'Wicked',
      cinema_name: body.cinema_name || body.cinemaName || 'Cinemax Colombo',
      screen_name: body.screen_name || body.screenName || 'Screen 04',
      seat_label: body.seat_label || body.seatLabel || 'General',
      ticket_code: body.ticket_code || body.ticketCode || `MOV-${Date.now().toString().slice(-6)}`,
      barcode_value: body.barcode_value || body.barcodeValue || body.ticket_code,
      price: Number(body.price) || 1800,
      status: body.status || 'confirmed',
      showtime: body.showtime || 'Tomorrow, 7:30 PM',
      created_at: new Date().toISOString(),
      poster_url: body.poster_url || body.posterURL || '',
      backdrop_url: body.backdrop_url || body.backdropURL || ''
    };

    const existingIndex = tickets.findIndex(
      t => t.id === newTicket.id ||
           t.ticket_code === newTicket.ticket_code ||
           (t.booking_id && newTicket.booking_id && t.booking_id === newTicket.booking_id && t.booking_id !== 'MOV-BOOK')
    );
    if (existingIndex >= 0) {
      const existing = tickets[existingIndex];
      const existingSeats = (existing.seat_label || '').split(/[·,]/).map((s: string) => s.trim()).filter(Boolean);
      const newSeats = (newTicket.seat_label || '').split(/[·,]/).map((s: string) => s.trim()).filter(Boolean);
      const combinedSeats = Array.from(new Set([...existingSeats, ...newSeats]));
      const mergedSeatLabel = combinedSeats.length > 0 ? combinedSeats.join(' · ') : newTicket.seat_label;

      const wasAlreadyAdmitted = existing.status === 'used' || existing.torn || Boolean(existing.scanned_at) || newTicket.status === 'used';

      tickets[existingIndex] = {
        ...existing,
        ...newTicket,
        seat_label: mergedSeatLabel,
        price: (existing.id !== newTicket.id && existing.price) ? (Number(existing.price) + (Number(newTicket.price) || 0)) : (Number(newTicket.price) || Number(existing.price)),
        status: wasAlreadyAdmitted ? 'used' : (newTicket.status || existing.status),
        torn: wasAlreadyAdmitted ? true : (existing.torn || newTicket.torn || false),
        scanned_at: existing.scanned_at || newTicket.scanned_at,
        scanned_by: existing.scanned_by || newTicket.scanned_by
      };
    } else {
      tickets.unshift(newTicket);
    }

    saveTickets(tickets);
    return NextResponse.json({ success: true, ticket: newTicket }, { status: 201 });
  } catch (error) {
    console.error('Failed to process ticket POST:', error);
    return NextResponse.json({ success: false, error: 'Internal server error' }, { status: 500 });
  }
}

export async function PATCH(req: Request) {
  try {
    const body = await req.json();
    const tickets = getTickets();
    const { id, ticket_code, status, scanned_by } = body;

    const index = tickets.findIndex(t => t.id === id || t.ticket_code === ticket_code);
    if (index === -1) {
      return NextResponse.json({ success: false, error: 'Ticket not found' }, { status: 404 });
    }

    const now = new Date().toISOString();
    const updated = {
      ...tickets[index],
      status: status || tickets[index].status,
      scanned_at: status === 'used' ? (tickets[index].scanned_at || now) : tickets[index].scanned_at,
      scanned_by: scanned_by || tickets[index].scanned_by || 'Staff Scanner',
      torn: status === 'used' ? true : tickets[index].torn
    };

    tickets[index] = updated;
    saveTickets(tickets);

    return NextResponse.json({ success: true, ticket: updated });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to update ticket' }, { status: 500 });
  }
}

export async function DELETE(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const id = searchParams.get('id');
    const all = searchParams.get('all');

    if (all === 'true') {
      saveTickets([]);
      return NextResponse.json({ success: true, message: 'All tickets cleared.' });
    }

    if (id) {
      const tickets = getTickets();
      const filtered = tickets.filter(t => t.id !== id && t.ticket_code !== id);
      saveTickets(filtered);
      return NextResponse.json({ success: true, message: 'Ticket deleted.' });
    }

    return NextResponse.json({ success: false, error: 'Missing ticket id' }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to delete ticket' }, { status: 500 });
  }
}
