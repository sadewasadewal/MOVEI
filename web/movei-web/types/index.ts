export type UserRole = 'customer' | 'admin' | 'scanner';

export type MovieStatus = 'draft' | 'published' | 'archived';

export interface Movie {
  id: string;
  title: string;
  slug: string;
  description: string;
  tagline: string;
  poster_url: string;
  backdrop_url: string;
  logo_url?: string;
  trailer_url?: string;
  runtime_minutes: number;
  release_date: string;
  rating: number;
  genres: string[];
  language: string;
  age_rating: string;
  status: MovieStatus;
  created_at?: string;
  updated_at?: string;
}

export interface Cinema {
  id: string;
  name: string;
  address: string;
  city: string;
  latitude?: number;
  longitude?: number;
  phone?: string;
  logo_url?: string;
  status: string;
  screens?: Screen[];
}

export interface Screen {
  id: string;
  cinema_id: string;
  name: string;
  screen_number: number;
  capacity: number;
  screen_type: 'standard' | 'imax' | '3d' | 'dolby';
}

export type SeatType = 'standard' | 'premium' | 'vip' | 'disabled';

export interface Seat {
  id: string;
  screen_id: string;
  row_label: string;
  seat_number: number;
  seat_type: SeatType;
  x_position: number;
  y_position: number;
  is_active: boolean;
  status?: 'available' | 'reserved' | 'selected' | 'sold';
}

export type ShowStatus = 'scheduled' | 'sold_out' | 'cancelled' | 'completed';

export interface Show {
  id: string;
  movie_id: string;
  cinema_id: string;
  screen_id: string;
  start_time: string;
  end_time: string;
  price_standard: number;
  price_premium: number;
  price_vip: number;
  status: ShowStatus;
  movie?: Movie;
  cinema?: Cinema;
  screen?: Screen;
}

export type BookingStatus = 'pending' | 'confirmed' | 'cancelled' | 'expired' | 'completed';
export type TicketStatus = 'pending' | 'reserved' | 'confirmed' | 'used' | 'cancelled' | 'expired';

export interface Booking {
  id: string;
  user_id: string;
  show_id: string;
  booking_reference: string;
  total_amount: number;
  currency: string;
  status: BookingStatus;
  created_at: string;
  show?: Show;
  tickets?: Ticket[];
}

export interface Ticket {
  id: string;
  booking_id: string;
  show_id: string;
  user_id: string;
  seat_id: string;
  ticket_code: string;
  barcode_value: string;
  status: TicketStatus;
  customer_name?: string;
  customer_phone?: string;
  customer_email?: string;
  seat_label?: string;
  movie_title?: string;
  cinema_name?: string;
  screen_name?: string;
  showtime?: string;
  price?: number;
  hold_expires_at?: string | null;
  scanned_at?: string | null;
  scanned_by?: string | null;
  approved_at?: string | null;
  torn?: boolean;
  poster_url?: string;
  backdrop_url?: string;
  created_at?: string;
  seat?: Seat;
  show?: Show;
}

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  avatar_url?: string;
  created_at?: string;
}

export interface AppAnnouncement {
  id: string;
  title: string;
  message: string;
  type: 'announcement' | 'update' | 'maintenance' | 'promo';
  target_version?: string;
  is_active: boolean;
  priority: 'low' | 'normal' | 'high' | 'urgent';
  created_at: string;
}

export type ScanResult = 'valid' | 'already_used' | 'wrong_cinema' | 'invalid' | 'cancelled' | 'expired';

export interface ScanResponse {
  valid: boolean;
  reason: ScanResult;
  message?: string;
  ticket_code?: string;
  movie_title?: string;
  customer_name?: string;
  cinema_name?: string;
  screen_name?: string;
  seat?: string;
  showtime?: string;
}
