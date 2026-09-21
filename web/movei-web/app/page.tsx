'use client';

import React, { useState, useEffect, useRef } from 'react';
import { 
  Film, 
  Calendar, 
  CheckCircle2, 
  XCircle, 
  Building2, 
  Radio, 
  LayoutDashboard, 
  Plus, 
  Search, 
  Trash2, 
  Edit3, 
  Eye, 
  Clock, 
  Star, 
  AlertTriangle, 
  Check, 
  X, 
  ArrowUpRight, 
  QrCode, 
  Ticket as TicketIcon, 
  DollarSign, 
  Users, 
  SlidersHorizontal,
  ExternalLink,
  ChevronRight,
  ShieldAlert,
  Smartphone,
  Sparkles,
  UploadCloud,
  Image as ImageIcon,
  RefreshCw
} from 'lucide-react';
import AdminHeader, { AdminTab } from '../components/AdminHeader';
import { 
  MOCK_MOVIES, 
  MOCK_CINEMAS, 
  MOCK_SHOWS, 
  MOCK_TICKETS, 
  MOCK_ANNOUNCEMENTS 
} from '../lib/mock-data';
import { 
  Movie, 
  Cinema, 
  Show, 
  Ticket, 
  AppAnnouncement, 
  MovieStatus, 
  TicketStatus 
} from '../types';

export default function AdminPage() {
  const [activeTab, setActiveTab] = useState<AdminTab>('overview');
  const [searchQuery, setSearchQuery] = useState('');

  // State collections
  const [movies, setMovies] = useState<Movie[]>(MOCK_MOVIES);
  const [shows, setShows] = useState<Show[]>(MOCK_SHOWS);
  const [cinemas, setCinemas] = useState<Cinema[]>(MOCK_CINEMAS);
  const [tickets, setTickets] = useState<Ticket[]>(MOCK_TICKETS);
  const [announcements, setAnnouncements] = useState<AppAnnouncement[]>(MOCK_ANNOUNCEMENTS);
  const [users, setUsers] = useState<{
    id: string;
    name: string;
    email: string;
    role: 'customer' | 'scanner' | 'admin';
    phone?: string;
    device?: string;
    registered_at: string;
  }[]>([]);

  // Filter states
  const [movieStatusFilter, setMovieStatusFilter] = useState<'all' | MovieStatus>('all');
  const [ticketStatusFilter, setTicketStatusFilter] = useState<'all' | TicketStatus>('all');

  // Modals
  const [showAddMovieModal, setShowAddMovieModal] = useState(false);
  const [editingMovie, setEditingMovie] = useState<Movie | null>(null);
  const [showAddShowModal, setShowAddShowModal] = useState(false);
  const [showAddAnnouncementModal, setShowAddAnnouncementModal] = useState(false);
  const [selectedTicketModal, setSelectedTicketModal] = useState<Ticket | null>(null);
  const [showAddCinemaModal, setShowAddCinemaModal] = useState(false);

  // Forms: New Movie
  const [movieForm, setMovieForm] = useState<Partial<Movie>>({
    title: '',
    tagline: '',
    description: '',
    poster_url: '',
    backdrop_url: '',
    trailer_url: '',
    runtime_minutes: 135,
    rating: 8.5,
    release_date: new Date().toISOString().split('T')[0],
    genres: ['Action', 'Sci-Fi'],
    language: 'English',
    age_rating: 'PG-13',
    status: 'published'
  });

  // Poster & Backdrop Upload State & Refs
  const posterFileInputRef = useRef<HTMLInputElement>(null);
  const backdropFileInputRef = useRef<HTMLInputElement>(null);
  const [isUploadingPoster, setIsUploadingPoster] = useState(false);
  const [isUploadingBackdrop, setIsUploadingBackdrop] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [posterInputMode, setPosterInputMode] = useState<'upload' | 'url'>('upload');
  const [usePosterAsBackdrop, setUsePosterAsBackdrop] = useState(true);

  const handlePosterFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsUploadingPoster(true);
    setUploadError(null);
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.error || 'Failed to upload custom poster PNG');
      }
      setMovieForm(prev => ({
        ...prev,
        poster_url: data.url,
        backdrop_url: usePosterAsBackdrop || !prev.backdrop_url ? data.url : prev.backdrop_url,
      }));
    } catch (err: any) {
      setUploadError(err.message || 'Failed to upload poster image');
    } finally {
      setIsUploadingPoster(false);
      if (e.target) e.target.value = '';
    }
  };

  const handleBackdropFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setIsUploadingBackdrop(true);
    setUploadError(null);
    try {
      const formData = new FormData();
      formData.append('file', file);
      const res = await fetch('/api/upload', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (!res.ok || !data.success) {
        throw new Error(data.error || 'Failed to upload backdrop image');
      }
      setMovieForm(prev => ({
        ...prev,
        backdrop_url: data.url,
      }));
    } catch (err: any) {
      setUploadError(err.message || 'Failed to upload backdrop image');
    } finally {
      setIsUploadingBackdrop(false);
      if (e.target) e.target.value = '';
    }
  };

  // Forms: New Show
  const [showForm, setShowForm] = useState({
    movie_id: movies[0]?.id || '',
    cinema_id: cinemas[0]?.id || '',
    screen_id: cinemas[0]?.screens?.[0]?.id || 'sc111111-1111-1111-1111-111111111111',
    start_time: '2026-09-22T19:30',
    price_standard: 1500,
    price_premium: 2000,
    price_vip: 2800
  });

  // Forms: New Announcement
  const [announcementForm, setAnnouncementForm] = useState<Partial<AppAnnouncement>>({
    title: '',
    message: '',
    type: 'announcement',
    target_version: '2.1.0',
    is_active: true,
    priority: 'normal'
  });

  // Derived metrics
  const pendingApprovals = tickets.filter(t => t.status === 'pending');
  const confirmedTickets = tickets.filter(t => t.status === 'confirmed');
  const usedTickets = tickets.filter(t => t.status === 'used');
  const totalRevenue = tickets
    .filter(t => t.status === 'confirmed' || t.status === 'used')
    .reduce((sum, t) => sum + (t.price || 1800), 0);

  // Load movies & users from persistent backend
  useEffect(() => {
    fetch('/api/movies')
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data) && data.length > 0) {
          setMovies(data);
        }
      })
      .catch(err => console.error('Failed to fetch movies:', err));

    fetchUsers();
    fetchTickets();

    const interval = setInterval(() => {
      fetchUsers();
      fetchTickets();
    }, 4000);

    return () => clearInterval(interval);
  }, []);

  const fetchTickets = () => {
    fetch('/api/tickets')
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) setTickets(data);
      })
      .catch(err => console.error('Failed to fetch tickets:', err));
  };

  const fetchUsers = () => {
    fetch('/api/users')
      .then(res => res.json())
      .then(data => {
        if (Array.isArray(data)) setUsers(data);
      })
      .catch(err => console.error('Failed to fetch users:', err));
  };

  const handleDeleteUser = async (id: string) => {
    if (confirm('Delete this user account?')) {
      try {
        await fetch(`/api/users?id=${id}`, { method: 'DELETE' });
        setUsers(prev => prev.filter(u => u.id !== id));
      } catch (err) {
        console.error('Failed to delete user:', err);
      }
    }
  };

  const handleClearAllUsers = async () => {
    if (confirm('Clear all registered users? This cannot be undone.')) {
      try {
        await fetch('/api/users?all=true', { method: 'DELETE' });
        setUsers([]);
      } catch (err) {
        console.error('Failed to clear users:', err);
      }
    }
  };

  // Handlers: Movies
  const handleSaveMovie = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!movieForm.title) return;

    if (editingMovie) {
      const payload = { ...editingMovie, ...movieForm };
      try {
        const res = await fetch('/api/movies', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        const saved = await res.json();
        setMovies(prev => prev.map(m => m.id === editingMovie.id ? saved : m));
      } catch {
        setMovies(prev => prev.map(m => m.id === editingMovie.id ? payload as Movie : m));
      }
      setEditingMovie(null);
    } else {
      const newMovie: Movie = {
        id: `m-${Date.now()}`,
        title: movieForm.title || 'Untitled',
        slug: (movieForm.title || '').toLowerCase().replace(/[^a-z0-9]/g, '-'),
        tagline: movieForm.tagline || '',
        description: movieForm.description || '',
        poster_url: movieForm.poster_url || 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
        backdrop_url: movieForm.backdrop_url || 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1920',
        trailer_url: movieForm.trailer_url || '',
        runtime_minutes: Number(movieForm.runtime_minutes) || 120,
        rating: Number(movieForm.rating) || 8.0,
        release_date: movieForm.release_date || new Date().toISOString().split('T')[0],
        genres: movieForm.genres || ['Drama'],
        language: movieForm.language || 'English',
        age_rating: movieForm.age_rating || 'PG-13',
        status: (movieForm.status as MovieStatus) || 'published'
      };
      try {
        const res = await fetch('/api/movies', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(newMovie)
        });
        const saved = await res.json();
        setMovies(prev => [saved, ...prev.filter(m => m.id !== saved.id)]);
      } catch {
        setMovies(prev => [newMovie, ...prev]);
      }
    }
    setShowAddMovieModal(false);
  };

  const handleDeleteMovie = async (id: string) => {
    if (confirm('Are you sure you want to remove this movie from the platform catalog?')) {
      setMovies(prev => prev.filter(m => m.id !== id));
      try {
        await fetch(`/api/movies?id=${id}`, { method: 'DELETE' });
      } catch (err) {
        console.error('Failed to delete movie:', err);
      }
    }
  };

  const handleToggleMovieStatus = async (movie: Movie) => {
    const nextStatus: MovieStatus = movie.status === 'published' ? 'draft' : 'published';
    setMovies(prev => prev.map(m => m.id === movie.id ? { ...m, status: nextStatus } : m));
    try {
      await fetch('/api/movies', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: movie.id, status: nextStatus })
      });
    } catch (err) {
      console.error('Failed to sync status:', err);
    }
  };

  // Handlers: Tickets
  const handleApproveTicket = (ticketId: string) => {
    setTickets(prev => prev.map(t => {
      if (t.id === ticketId) {
        return { ...t, status: 'confirmed', approved_at: new Date().toISOString() };
      }
      return t;
    }));
    if (selectedTicketModal?.id === ticketId) {
      setSelectedTicketModal(prev => prev ? { ...prev, status: 'confirmed' } : null);
    }
  };

  const handleAdmitTicket = async (ticketId: string) => {
    try {
      const res = await fetch('/api/tickets', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: ticketId, status: 'used', scanned_by: 'Cinema Director (Admin)' })
      });
      const data = await res.json();
      if (data.success && data.ticket) {
        setTickets(prev => prev.map(t => t.id === ticketId ? data.ticket : t));
        if (selectedTicketModal?.id === ticketId) {
          setSelectedTicketModal(data.ticket);
        }
      }
    } catch (err) {
      console.error('Failed to admit ticket:', err);
      // Local fallback
      setTickets(prev => prev.map(t => {
        if (t.id === ticketId) {
          return { ...t, status: 'used', scanned_at: new Date().toISOString() };
        }
        return t;
      }));
      if (selectedTicketModal?.id === ticketId) {
        setSelectedTicketModal(prev => prev ? { ...prev, status: 'used' } : null);
      }
    }
  };

  const handleCancelTicket = (ticketId: string) => {
    if (confirm('Cancel and refund this ticket pass?')) {
      setTickets(prev => prev.map(t => {
        if (t.id === ticketId) {
          return { ...t, status: 'cancelled' };
        }
        return t;
      }));
      if (selectedTicketModal?.id === ticketId) {
        setSelectedTicketModal(prev => prev ? { ...prev, status: 'cancelled' } : null);
      }
    }
  };

  const handleClearAllTickets = async () => {
    if (confirm('Clear all ticket orders and start completely fresh? This will remove all passes from the system.')) {
      try {
        await fetch('/api/tickets?all=true', { method: 'DELETE' });
        setTickets([]);
        if (selectedTicketModal) setSelectedTicketModal(null);
      } catch (err) {
        console.error('Failed to clear tickets:', err);
      }
    }
  };

  // Handlers: Shows
  const handleSaveShow = (e: React.FormEvent) => {
    e.preventDefault();
    const movie = movies.find(m => m.id === showForm.movie_id);
    const cinema = cinemas.find(c => c.id === showForm.cinema_id);
    const screen = cinema?.screens?.find(s => s.id === showForm.screen_id);

    const startDate = new Date(showForm.start_time);
    const endDate = new Date(startDate.getTime() + (movie ? movie.runtime_minutes + 20 : 140) * 60000);

    const newShow: Show = {
      id: `sh-${Date.now()}`,
      movie_id: showForm.movie_id,
      cinema_id: showForm.cinema_id,
      screen_id: showForm.screen_id,
      start_time: startDate.toISOString(),
      end_time: endDate.toISOString(),
      price_standard: Number(showForm.price_standard),
      price_premium: Number(showForm.price_premium),
      price_vip: Number(showForm.price_vip),
      status: 'scheduled',
      movie,
      cinema,
      screen
    };
    setShows([newShow, ...shows]);
    setShowAddShowModal(false);
  };

  const handleCancelShow = (showId: string) => {
    if (confirm('Cancel this screening?')) {
      setShows(prev => prev.map(s => s.id === showId ? { ...s, status: 'cancelled' } : s));
    }
  };

  // Handlers: Announcements
  const handleSaveAnnouncement = (e: React.FormEvent) => {
    e.preventDefault();
    if (!announcementForm.title || !announcementForm.message) return;

    const newAnn: AppAnnouncement = {
      id: `ann-${Date.now()}`,
      title: announcementForm.title,
      message: announcementForm.message,
      type: announcementForm.type || 'announcement',
      target_version: announcementForm.target_version || '2.1.0',
      is_active: announcementForm.is_active !== false,
      priority: announcementForm.priority || 'normal',
      created_at: new Date().toISOString()
    };
    setAnnouncements([newAnn, ...announcements]);
    setShowAddAnnouncementModal(false);
  };

  const handleToggleAnnouncement = (id: string) => {
    setAnnouncements(prev => prev.map(a => a.id === id ? { ...a, is_active: !a.is_active } : a));
  };

  const handleDeleteAnnouncement = (id: string) => {
    setAnnouncements(prev => prev.filter(a => a.id !== id));
  };

  // Search filtering
  const filteredMovies = movies.filter(m => {
    const matchesSearch = !searchQuery || 
      m.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
      m.genres.some(g => g.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesStatus = movieStatusFilter === 'all' || m.status === movieStatusFilter;
    return matchesSearch && matchesStatus;
  });

  const filteredTickets = tickets.filter(t => {
    const matchesSearch = !searchQuery ||
      t.ticket_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.customer_name && t.customer_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (t.movie_title && t.movie_title.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesStatus = ticketStatusFilter === 'all' || t.status === ticketStatusFilter;
    return matchesSearch && matchesStatus;
  });

  return (
    <div className="min-h-screen bg-[#070709] text-gray-100 flex flex-col">
      {/* Executive Header */}
      <AdminHeader
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        pendingApprovalsCount={pendingApprovals.length}
        onNewMovie={() => {
          setEditingMovie(null);
          setMovieForm({
            title: '',
            tagline: '',
            description: '',
            poster_url: '',
            backdrop_url: '',
            trailer_url: '',
            runtime_minutes: 135,
            rating: 8.5,
            release_date: new Date().toISOString().split('T')[0],
            genres: ['Action', 'Sci-Fi'],
            language: 'English',
            age_rating: 'PG-13',
            status: 'published'
          });
          setShowAddMovieModal(true);
        }}
        onNewShow={() => setShowAddShowModal(true)}
        onNewAnnouncement={() => {
          setAnnouncementForm({
            title: '',
            message: '',
            type: 'announcement',
            target_version: '2.1.0',
            is_active: true,
            priority: 'normal'
          });
          setShowAddAnnouncementModal(true);
        }}
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
      />

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        
        {/* ======================= TAB 1: OVERVIEW ======================= */}
        {activeTab === 'overview' && (
          <div className="space-y-8 animate-in fade-in duration-300">
            {/* KPI Cards Grid */}
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">Total Revenue</span>
                  <DollarSign className="w-4 h-4 text-emerald-400" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-white">
                  Rs. {totalRevenue.toLocaleString()}
                </div>
                <span className="text-[10px] text-emerald-400 font-medium mt-1">Confirmed + Admitted</span>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">Active Movies</span>
                  <Film className="w-4 h-4 text-[#bae861]" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-white">
                  {movies.filter(m => m.status === 'published').length}
                </div>
                <span className="text-[10px] text-gray-400 font-medium mt-1">{movies.length} total titles</span>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">Pending Approval</span>
                  <AlertTriangle className="w-4 h-4 text-amber-400" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-amber-400">
                  {pendingApprovals.length}
                </div>
                <span className="text-[10px] text-amber-400/80 font-medium mt-1">Requires review</span>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">Admissions</span>
                  <CheckCircle2 className="w-4 h-4 text-cyan-400" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-white">
                  {usedTickets.length}
                </div>
                <span className="text-[10px] text-cyan-400 font-medium mt-1">Gate scans today</span>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">Screenings</span>
                  <Calendar className="w-4 h-4 text-purple-400" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-white">
                  {shows.filter(s => s.status === 'scheduled').length}
                </div>
                <span className="text-[10px] text-gray-400 font-medium mt-1">Across 3 Cinemas</span>
              </div>

              <div className="bg-white/5 border border-white/10 rounded-2xl p-4 flex flex-col justify-between hover:border-white/20 transition-all">
                <div className="flex items-center justify-between text-gray-400 mb-2">
                  <span className="text-xs font-semibold">iOS Sync</span>
                  <Smartphone className="w-4 h-4 text-[#007aff]" />
                </div>
                <div className="text-xl sm:text-2xl font-black text-emerald-400 flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 inline-block animate-pulse" />
                  Live
                </div>
                <span className="text-[10px] text-gray-400 font-medium mt-1">SwiftData + Supabase</span>
              </div>
            </div>

            {/* Pending Approvals Queue Banner */}
            {pendingApprovals.length > 0 && (
              <div className="bg-gradient-to-r from-amber-500/10 via-amber-500/5 to-transparent border border-amber-500/30 rounded-2xl p-4 sm:p-5 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="p-2.5 bg-amber-500/20 text-amber-400 rounded-xl">
                    <AlertTriangle className="w-6 h-6" />
                  </div>
                  <div>
                    <h3 className="font-bold text-white text-sm sm:text-base">
                      {pendingApprovals.length} Ticket Orders Awaiting Approval
                    </h3>
                    <p className="text-xs text-gray-400">
                      Customers have reserved seats and are waiting for admin pass confirmation to tear in the iOS app.
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setActiveTab('tickets')}
                  className="px-4 py-2 bg-amber-500 hover:bg-amber-400 text-black font-bold text-xs rounded-xl flex items-center gap-1.5 transition-all shadow-lg shadow-amber-500/20 cursor-pointer"
                >
                  <span>Open Approval Queue</span>
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Overview Content 2-Column Split */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              
              {/* Left Column: Recent Ticket Passes */}
              <div className="lg:col-span-2 bg-white/5 border border-white/10 rounded-2xl p-5">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="font-bold text-base text-white">Recent Ticket Orders</h3>
                    <p className="text-xs text-gray-400">Live booking activity from iOS devices</p>
                  </div>
                  <div className="flex items-center gap-2.5">
                    {tickets.length > 0 && (
                      <button
                        onClick={handleClearAllTickets}
                        className="text-[11px] font-semibold text-red-400 hover:text-red-300 bg-red-500/10 hover:bg-red-500/20 px-2.5 py-1 rounded-lg border border-red-500/20 flex items-center gap-1 transition-all cursor-pointer"
                        title="Clear all ticket orders and start fresh"
                      >
                        <Trash2 className="w-3 h-3" />
                        <span>Clear Orders</span>
                      </button>
                    )}
                    <button
                      onClick={() => setActiveTab('tickets')}
                      className="text-xs font-semibold text-[#bae861] hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      View all ({tickets.length})
                      <ArrowUpRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="border-b border-white/10 text-gray-400 font-semibold">
                        <th className="pb-3">Ticket / Code</th>
                        <th className="pb-3">Customer</th>
                        <th className="pb-3">Movie & Venue</th>
                        <th className="pb-3">Status</th>
                        <th className="pb-3 text-right">Quick Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                      {tickets.slice(0, 5).map(t => (
                        <tr key={t.id} className="hover:bg-white/5 transition-colors">
                          <td className="py-3 font-mono font-bold text-white flex items-center gap-2">
                            <TicketIcon className="w-3.5 h-3.5 text-gray-500" />
                            <span>{t.ticket_code}</span>
                          </td>
                          <td className="py-3">
                            <div className="font-medium text-white">{t.customer_name || 'Customer'}</div>
                            <div className="text-[11px] text-gray-500">{t.customer_phone || t.customer_email || '—'}</div>
                          </td>
                          <td className="py-3">
                            <div className="font-medium text-white">{t.movie_title || 'Movie'}</div>
                            <div className="text-[11px] text-gray-400">{t.cinema_name} · <span className="text-[#bae861] font-mono font-bold">{t.seat_label || 'General'}</span></div>
                          </td>
                          <td className="py-3">
                            {t.status === 'used' ? (
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-violet-500/20 text-violet-300 border border-violet-500/30 flex items-center gap-1 w-fit">
                                <span>✂️</span> USED
                              </span>
                            ) : (
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                                t.status === 'confirmed' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
                                t.status === 'pending' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
                                'bg-red-500/20 text-red-400 border border-red-500/30'
                              }`}>
                                {t.status}
                              </span>
                            )}
                          </td>
                          <td className="py-3 text-right">
                            {t.status === 'pending' ? (
                              <button
                                onClick={() => handleApproveTicket(t.id)}
                                className="px-2.5 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-bold rounded-lg text-[11px] transition-all cursor-pointer"
                              >
                                Approve
                              </button>
                            ) : (
                              <button
                                onClick={() => setSelectedTicketModal(t)}
                                className="px-2.5 py-1 bg-white/10 hover:bg-white/15 text-white font-medium rounded-lg text-[11px] transition-all cursor-pointer"
                              >
                                Inspect
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Right Column: Live App Broadcasts & Quick Links */}
              <div className="space-y-6">
                
                {/* Active In-App Broadcasts */}
                <div className="bg-white/5 border border-white/10 rounded-2xl p-5">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="font-bold text-base text-white flex items-center gap-2">
                      <Radio className="w-4 h-4 text-[#bae861]" />
                      Active In-App Broadcasts
                    </h3>
                    <button
                      onClick={() => setShowAddAnnouncementModal(true)}
                      className="text-xs text-[#bae861] hover:underline"
                    >
                      + New
                    </button>
                  </div>
                  <p className="text-xs text-gray-400 mb-4">Messages currently shown to customers in the iOS app</p>

                  <div className="space-y-3">
                    {announcements.slice(0, 3).map(a => (
                      <div key={a.id} className="p-3 bg-white/5 border border-white/5 rounded-xl space-y-1">
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-xs text-white">{a.title}</span>
                          <span className={`text-[9px] font-black uppercase px-1.5 py-0.5 rounded ${
                            a.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-gray-500/20 text-gray-400'
                          }`}>
                            {a.is_active ? 'Active' : 'Disabled'}
                          </span>
                        </div>
                        <p className="text-[11px] text-gray-400 line-clamp-2">{a.message}</p>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Quick Catalog Shortcuts */}
                <div className="bg-gradient-to-br from-white/5 to-white/[0.02] border border-white/10 rounded-2xl p-5 space-y-3">
                  <h3 className="font-bold text-sm text-white">Platform Actions</h3>
                  
                  <button
                    onClick={() => {
                      setEditingMovie(null);
                      setShowAddMovieModal(true);
                    }}
                    className="w-full py-2.5 px-3 bg-white/5 hover:bg-white/10 rounded-xl text-xs font-semibold flex items-center justify-between text-white border border-white/5 transition-all cursor-pointer"
                  >
                    <span className="flex items-center gap-2">
                      <Film className="w-4 h-4 text-[#bae861]" />
                      Publish New Movie Title
                    </span>
                    <Plus className="w-4 h-4 text-gray-400" />
                  </button>

                  <button
                    onClick={() => setShowAddShowModal(true)}
                    className="w-full py-2.5 px-3 bg-white/5 hover:bg-white/10 rounded-xl text-xs font-semibold flex items-center justify-between text-white border border-white/5 transition-all cursor-pointer"
                  >
                    <span className="flex items-center gap-2">
                      <Calendar className="w-4 h-4 text-purple-400" />
                      Schedule Screening Show
                    </span>
                    <Plus className="w-4 h-4 text-gray-400" />
                  </button>

                  <button
                    onClick={() => setActiveTab('tickets')}
                    className="w-full py-2.5 px-3 bg-white/5 hover:bg-white/10 rounded-xl text-xs font-semibold flex items-center justify-between text-white border border-white/5 transition-all cursor-pointer"
                  >
                    <span className="flex items-center gap-2">
                      <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                      Review Pending Approvals ({pendingApprovals.length})
                    </span>
                    <ChevronRight className="w-4 h-4 text-gray-400" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ======================= TAB 2: MOVIES MANAGEMENT ======================= */}
        {activeTab === 'movies' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            {/* Header Toolbar */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white">Movie Catalog Management</h2>
                <p className="text-xs text-gray-400">Add, edit, publish, or archive movie titles appearing in the iOS app</p>
              </div>

              <div className="flex items-center gap-2">
                {/* Status filter pills */}
                <div className="flex items-center bg-white/5 p-1 rounded-xl border border-white/10 text-xs">
                  {(['all', 'published', 'draft', 'archived'] as const).map(st => (
                    <button
                      key={st}
                      onClick={() => setMovieStatusFilter(st)}
                      className={`px-3 py-1 rounded-lg font-semibold capitalize transition-all cursor-pointer ${
                        movieStatusFilter === st
                          ? 'bg-white text-black shadow-sm'
                          : 'text-gray-400 hover:text-white'
                      }`}
                    >
                      {st}
                    </button>
                  ))}
                </div>

                <button
                  onClick={() => {
                    setEditingMovie(null);
                    setMovieForm({
                      title: '',
                      tagline: '',
                      description: '',
                      poster_url: '',
                      backdrop_url: '',
                      trailer_url: '',
                      runtime_minutes: 135,
                      rating: 8.5,
                      release_date: new Date().toISOString().split('T')[0],
                      genres: ['Action', 'Sci-Fi'],
                      language: 'English',
                      age_rating: 'PG-13',
                      status: 'published'
                    });
                    setShowAddMovieModal(true);
                  }}
                  className="flex items-center gap-1.5 px-4 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold text-xs rounded-xl shadow-lg shadow-[#bae861]/15 transition-all cursor-pointer"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Movie</span>
                </button>
              </div>
            </div>

            {/* Movies Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {filteredMovies.map(movie => (
                <div
                  key={movie.id}
                  className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden hover:border-white/20 transition-all flex flex-col group"
                >
                  {/* Backdrop banner */}
                  <div className="relative h-44 w-full overflow-hidden bg-black/50">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={movie.backdrop_url || movie.poster_url}
                      alt={movie.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-[#0d0e12] via-transparent to-black/40" />

                    {/* Status Pill */}
                    <div className="absolute top-3 left-3">
                      <span className={`px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider ${
                        movie.status === 'published' ? 'bg-emerald-500 text-black' :
                        movie.status === 'draft' ? 'bg-amber-500 text-black' :
                        'bg-gray-700 text-white'
                      }`}>
                        {movie.status}
                      </span>
                    </div>

                    {/* Rating Pill */}
                    <div className="absolute top-3 right-3 flex items-center gap-1 px-2 py-0.5 rounded-full bg-black/60 backdrop-blur-md text-xs font-bold text-white border border-white/15">
                      <Star className="w-3 h-3 text-yellow-400 fill-yellow-400" />
                      <span>{movie.rating}</span>
                    </div>
                  </div>

                  {/* Content Info */}
                  <div className="p-4 flex-1 flex flex-col justify-between space-y-3">
                    <div>
                      <h3 className="font-bold text-lg text-white line-clamp-1">{movie.title}</h3>
                      <p className="text-xs text-gray-400 italic line-clamp-1">{movie.tagline || 'Cinema Feature'}</p>
                      
                      <div className="flex flex-wrap gap-1.5 mt-2">
                        {movie.genres.map(g => (
                          <span key={g} className="text-[10px] px-2 py-0.5 rounded-md bg-white/5 text-gray-300 font-medium border border-white/5">
                            {g}
                          </span>
                        ))}
                        <span className="text-[10px] px-2 py-0.5 rounded-md bg-white/5 text-gray-400 font-medium">
                          {movie.runtime_minutes} mins
                        </span>
                      </div>

                      <p className="text-xs text-gray-400 mt-2.5 line-clamp-2">{movie.description}</p>
                    </div>

                    {/* Actions Bar */}
                    <div className="pt-3 border-t border-white/10 flex items-center justify-between gap-2">
                      <button
                        onClick={() => handleToggleMovieStatus(movie)}
                        className={`text-xs font-bold px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                          movie.status === 'published'
                            ? 'bg-amber-500/20 text-amber-300 hover:bg-amber-500/30'
                            : 'bg-emerald-500/20 text-emerald-300 hover:bg-emerald-500/30'
                        }`}
                      >
                        {movie.status === 'published' ? 'Unpublish' : 'Publish to App'}
                      </button>

                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => {
                            setEditingMovie(movie);
                            setMovieForm(movie);
                            setShowAddMovieModal(true);
                          }}
                          className="p-1.5 text-gray-400 hover:text-white bg-white/5 hover:bg-white/10 rounded-lg transition-all cursor-pointer"
                          title="Edit movie"
                        >
                          <Edit3 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteMovie(movie.id)}
                          className="p-1.5 text-red-400 hover:text-red-300 bg-red-500/10 hover:bg-red-500/20 rounded-lg transition-all cursor-pointer"
                          title="Delete movie"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ======================= TAB 3: SHOWTIMES & SCHEDULES ======================= */}
        {activeTab === 'shows' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white">Showtimes & Screen Scheduling</h2>
                <p className="text-xs text-gray-400">Configure movie showtimes, assign screens, and manage ticket pricing tiers</p>
              </div>

              <button
                onClick={() => setShowAddShowModal(true)}
                className="flex items-center gap-1.5 px-4 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold text-xs rounded-xl shadow-lg shadow-[#bae861]/15 transition-all cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Add Show Schedule</span>
              </button>
            </div>

            {/* Shows List */}
            <div className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-white/10 text-gray-400 font-semibold bg-white/[0.02]">
                      <th className="p-4">Movie Title</th>
                      <th className="p-4">Cinema Venue & Screen</th>
                      <th className="p-4">Screening Time</th>
                      <th className="p-4">Pricing Tiers (Std / Prem / VIP)</th>
                      <th className="p-4">Status</th>
                      <th className="p-4 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {shows.map(show => {
                      const movie = movies.find(m => m.id === show.movie_id) || show.movie;
                      const cinema = cinemas.find(c => c.id === show.cinema_id) || show.cinema;
                      const screen = cinema?.screens?.find(s => s.id === show.screen_id) || show.screen;
                      const dateObj = new Date(show.start_time);

                      return (
                        <tr key={show.id} className="hover:bg-white/5 transition-colors">
                          <td className="p-4">
                            <div className="font-bold text-white text-sm">{movie?.title || 'Unknown Title'}</div>
                            <div className="text-[11px] text-gray-400">{movie?.runtime_minutes || 120} mins · {movie?.genres?.join(', ')}</div>
                          </td>
                          <td className="p-4">
                            <div className="font-medium text-white">{cinema?.name || 'Cinemax Colombo'}</div>
                            <div className="text-[11px] text-gray-400">{screen?.name || 'Screen 04'} ({screen?.screen_type?.toUpperCase() || 'IMAX'})</div>
                          </td>
                          <td className="p-4">
                            <div className="font-bold text-white">
                              {dateObj.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                            </div>
                            <div className="text-[11px] text-gray-400">
                              {dateObj.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' })}
                            </div>
                          </td>
                          <td className="p-4">
                            <div className="flex items-center gap-2 font-mono text-white">
                              <span className="text-gray-300">Rs.{show.price_standard}</span>
                              <span className="text-gray-500">/</span>
                              <span className="text-blue-300">Rs.{show.price_premium}</span>
                              <span className="text-gray-500">/</span>
                              <span className="text-purple-300 font-bold">Rs.{show.price_vip}</span>
                            </div>
                          </td>
                          <td className="p-4">
                            <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                              show.status === 'scheduled' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
                              show.status === 'cancelled' ? 'bg-red-500/20 text-red-400 border border-red-500/30' :
                              'bg-purple-500/20 text-purple-400 border border-purple-500/30'
                            }`}>
                              {show.status}
                            </span>
                          </td>
                          <td className="p-4 text-right">
                            {show.status === 'scheduled' && (
                              <button
                                onClick={() => handleCancelShow(show.id)}
                                className="px-2.5 py-1 bg-red-500/15 hover:bg-red-500/25 text-red-400 font-semibold rounded-lg text-xs transition-all cursor-pointer"
                              >
                                Cancel Show
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ======================= TAB 4: TICKET APPROVALS ======================= */}
        {activeTab === 'tickets' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white">Ticket Orders & Approvals</h2>
                <p className="text-xs text-gray-400">Review pending customer reservations, confirm passes, and record admissions</p>
              </div>

              <div className="flex flex-wrap items-center gap-2.5">
                {/* Clear All Ticket Orders Button */}
                <button
                  onClick={handleClearAllTickets}
                  className="px-3 py-1.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 font-bold rounded-xl text-xs transition-all border border-red-500/25 flex items-center gap-1.5 cursor-pointer shadow-sm"
                  title="Clear all ticket orders and start clean"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  <span>Clear All Orders</span>
                </button>

                {/* Status Filter */}
                <div className="flex items-center bg-white/5 p-1 rounded-xl border border-white/10 text-xs">
                  {(['all', 'pending', 'confirmed', 'used', 'cancelled'] as const).map(st => (
                    <button
                      key={st}
                      onClick={() => setTicketStatusFilter(st)}
                      className={`px-3 py-1 rounded-lg font-semibold capitalize transition-all cursor-pointer ${
                        ticketStatusFilter === st
                          ? 'bg-white text-black shadow-sm'
                          : 'text-gray-400 hover:text-white'
                      }`}
                    >
                      {st} {st === 'pending' && pendingApprovals.length > 0 && `(${pendingApprovals.length})`}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Tickets Table */}
            <div className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden shadow-xl">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead>
                    <tr className="border-b border-white/10 text-gray-400 font-semibold bg-white/[0.02]">
                      <th className="p-4">Pass Code / Barcode</th>
                      <th className="p-4">Customer</th>
                      <th className="p-4">Movie & Showtime</th>
                      <th className="p-4">Cinema & Seats</th>
                      <th className="p-4">Price</th>
                      <th className="p-4">Status</th>
                      <th className="p-4 text-right">Approval Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {filteredTickets.map(ticket => (
                      <tr key={ticket.id} className="hover:bg-white/5 transition-colors">
                        <td className="p-4">
                          <button
                            onClick={() => setSelectedTicketModal(ticket)}
                            className="font-mono font-bold text-white hover:text-[#bae861] transition-colors flex items-center gap-1.5 cursor-pointer"
                          >
                            <QrCode className="w-4 h-4 text-gray-400" />
                            {ticket.ticket_code}
                          </button>
                          <div className="text-[10px] text-gray-500 font-mono mt-0.5">{ticket.barcode_value}</div>
                        </td>
                        <td className="p-4">
                          <div className="font-bold text-white">{ticket.customer_name || 'Customer'}</div>
                          <div className="text-[11px] text-gray-400">{ticket.customer_phone || ticket.customer_email || '—'}</div>
                          {ticket.customer_email && ticket.customer_phone && (
                            <div className="text-[10px] text-gray-500">{ticket.customer_email}</div>
                          )}
                        </td>
                        <td className="p-4">
                          <div className="font-bold text-white">{ticket.movie_title || 'Movie'}</div>
                          <div className="text-[11px] text-gray-400">{ticket.showtime || 'Tomorrow, 7:30 PM'}</div>
                        </td>
                        <td className="p-4">
                          <div className="font-medium text-white">{ticket.cinema_name || 'Cinemax Colombo'}</div>
                          <div className="mt-1 flex items-center gap-1.5 flex-wrap">
                            <span className="text-[11px] text-[#bae861] font-mono font-bold bg-[#bae861]/10 px-2 py-0.5 rounded-md border border-[#bae861]/25">
                              {ticket.seat_label || 'General'}
                            </span>
                            {ticket.seat_label && (ticket.seat_label.includes('·') || ticket.seat_label.includes(',')) && (
                              <span className="text-[10px] font-bold text-gray-300 bg-white/10 px-1.5 py-0.5 rounded border border-white/15">
                                {ticket.seat_label.split(/[·,]/).filter(Boolean).length} Seats Pass
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="p-4 font-mono font-bold text-white">
                          Rs. {ticket.price || 1800}
                        </td>
                        <td className="p-4">
                          {ticket.status === 'used' ? (
                            <div className="flex flex-col items-start gap-1">
                              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black tracking-wider bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center gap-1">
                                <span>✂️</span> TORN & ADMITTED
                              </span>
                              {ticket.scanned_at && (
                                <span className="text-[10px] text-gray-400 font-mono">
                                  {new Date(ticket.scanned_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {ticket.scanned_by || 'Staff'}
                                </span>
                              )}
                            </div>
                          ) : (
                            <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                              ticket.status === 'confirmed' ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30' :
                              ticket.status === 'pending' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
                              'bg-red-500/20 text-red-400 border border-red-500/30'
                            }`}>
                              {ticket.status}
                            </span>
                          )}
                        </td>
                        <td className="p-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            {ticket.status === 'pending' && (
                              <button
                                onClick={() => handleApproveTicket(ticket.id)}
                                className="px-3 py-1 bg-emerald-500 hover:bg-emerald-400 text-black font-black rounded-lg text-xs transition-all shadow-md shadow-emerald-500/20 cursor-pointer"
                              >
                                Approve Pass
                              </button>
                            )}

                            {ticket.status === 'confirmed' && (
                              <button
                                onClick={() => handleAdmitTicket(ticket.id)}
                                className="px-2.5 py-1 bg-[#bae861]/20 hover:bg-[#bae861]/30 text-[#bae861] font-bold rounded-lg text-xs transition-all cursor-pointer flex items-center gap-1 border border-[#bae861]/30"
                              >
                                <span>✂️</span> Validate & Tear
                              </button>
                            )}

                            {ticket.status !== 'cancelled' && ticket.status !== 'used' && (
                              <button
                                onClick={() => handleCancelTicket(ticket.id)}
                                className="px-2 py-1 text-red-400 hover:bg-red-500/10 rounded-lg text-xs transition-all cursor-pointer"
                                title="Cancel pass"
                              >
                                Cancel
                              </button>
                            )}

                            <button
                              onClick={() => setSelectedTicketModal(ticket)}
                              className="px-2 py-1 text-gray-400 hover:text-white bg-white/5 rounded-lg text-xs transition-all cursor-pointer"
                            >
                              Inspect
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}

                    {filteredTickets.length === 0 && (
                      <tr>
                        <td colSpan={7} className="text-center py-16">
                          <div className="flex flex-col items-center justify-center max-w-sm mx-auto">
                            <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center mb-4">
                              <TicketIcon className="w-7 h-7 text-gray-400" />
                            </div>
                            <h3 className="text-sm font-bold text-white mb-1">No Ticket Orders</h3>
                            <p className="text-xs text-gray-400 text-center mb-5">
                              {tickets.length === 0
                                ? 'All orders cleared. System is running fresh. Any tickets reserved or scanned from the iOS app will appear here in real time.'
                                : 'No ticket orders match the selected filter.'}
                            </p>
                            <button
                              onClick={fetchTickets}
                              className="px-4 py-2 bg-white/10 hover:bg-white/15 text-white font-bold text-xs rounded-xl flex items-center gap-1.5 transition-all cursor-pointer border border-white/10"
                            >
                              <RefreshCw className="w-3.5 h-3.5" />
                              <span>Refresh Orders</span>
                            </button>
                          </div>
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ======================= TAB 5: CINEMAS & SCREENS ======================= */}
        {activeTab === 'cinemas' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white">Cinemas & Screen Formats</h2>
                <p className="text-xs text-gray-400">Manage theater venues, auditoriums, IMAX/VIP screens, and seat layouts</p>
              </div>

              <button
                onClick={() => setShowAddCinemaModal(true)}
                className="flex items-center gap-1.5 px-4 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold text-xs rounded-xl shadow-lg shadow-[#bae861]/15 transition-all cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Add Cinema Venue</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {cinemas.map(cinema => (
                <div key={cinema.id} className="bg-white/5 border border-white/10 rounded-2xl p-5 space-y-4 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between">
                      <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 to-indigo-600 flex items-center justify-center font-bold text-white">
                        <Building2 className="w-5 h-5" />
                      </div>
                      <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                        {cinema.status}
                      </span>
                    </div>

                    <h3 className="font-bold text-lg text-white mt-3">{cinema.name}</h3>
                    <p className="text-xs text-gray-400">{cinema.address}, {cinema.city}</p>
                    <p className="text-xs text-gray-500 mt-1">{cinema.phone || '+94 11 234 5678'}</p>

                    <div className="mt-4 pt-3 border-t border-white/10 space-y-2">
                      <span className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">Auditorium Screens</span>
                      <div className="space-y-1.5">
                        {cinema.screens?.map(scr => (
                          <div key={scr.id} className="p-2.5 bg-white/5 border border-white/5 rounded-xl flex items-center justify-between text-xs">
                            <div>
                              <span className="font-bold text-white">{scr.name}</span>
                              <span className="text-gray-400 ml-2">({scr.capacity} seats)</span>
                            </div>
                            <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded bg-purple-500/20 text-purple-300">
                              {scr.screen_type}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>

                  <div className="pt-3 border-t border-white/10 flex items-center justify-between text-xs text-gray-400">
                    <span>{cinema.screens?.length || 1} Screens Total</span>
                    <span className="text-[#bae861] font-semibold">Active in iOS App</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ======================= TAB: REGISTERED USERS ======================= */}
        {activeTab === 'users' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white flex items-center gap-2.5">
                  <Users className="w-6 h-6 text-[#bae861]" />
                  Registered Platform Users
                </h2>
                <p className="text-xs text-gray-400">Live accounts registered through the iOS MOVEI app & admin portal</p>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={fetchUsers}
                  className="px-3.5 py-2 bg-white/5 hover:bg-white/10 text-white rounded-xl text-xs font-bold transition flex items-center gap-2 border border-white/10"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  Refresh
                </button>
                {users.length > 0 && (
                  <button
                    onClick={handleClearAllUsers}
                    className="px-3.5 py-2 bg-red-500/10 hover:bg-red-500/20 text-red-400 rounded-xl text-xs font-bold transition flex items-center gap-2 border border-red-500/20"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    Clear All
                  </button>
                )}
              </div>
            </div>

            {/* User Statistics Row */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
              <div className="bg-[#12121a] border border-white/10 rounded-2xl p-4">
                <p className="text-xs font-medium text-gray-400">Total Registered</p>
                <p className="text-2xl font-black text-white mt-1">{users.length}</p>
                <span className="text-[10px] text-gray-500">Live in system</span>
              </div>
              <div className="bg-[#12121a] border border-white/10 rounded-2xl p-4">
                <p className="text-xs font-medium text-gray-400">Customers</p>
                <p className="text-2xl font-black text-[#bae861] mt-1">
                  {users.filter(u => u.role === 'customer').length}
                </p>
                <span className="text-[10px] text-[#bae861]/70">Ticket Buyers</span>
              </div>
              <div className="bg-[#12121a] border border-white/10 rounded-2xl p-4">
                <p className="text-xs font-medium text-gray-400">Scanner Staff</p>
                <p className="text-2xl font-black text-blue-400 mt-1">
                  {users.filter(u => u.role === 'scanner').length}
                </p>
                <span className="text-[10px] text-blue-400/70">Gate Admission</span>
              </div>
              <div className="bg-[#12121a] border border-white/10 rounded-2xl p-4">
                <p className="text-xs font-medium text-gray-400">Administrators</p>
                <p className="text-2xl font-black text-orange-400 mt-1">
                  {users.filter(u => u.role === 'admin').length}
                </p>
                <span className="text-[10px] text-orange-400/70">Cinema Directors</span>
              </div>
            </div>

            {/* Users Table / Empty State */}
            {users.length === 0 ? (
              <div className="bg-[#12121a] border border-white/10 rounded-2xl p-16 text-center">
                <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center mx-auto mb-4 text-gray-500">
                  <Users className="w-7 h-7" />
                </div>
                <h3 className="text-lg font-bold text-white">No Registered Users Yet</h3>
                <p className="text-xs text-gray-400 max-w-sm mx-auto mt-1.5 leading-relaxed">
                  When new customers or staff sign up on the MOVEI iOS app, their user profiles will appear here in real-time.
                </p>
              </div>
            ) : (
              <div className="bg-[#12121a] border border-white/10 rounded-2xl overflow-hidden shadow-2xl">
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm text-gray-300">
                    <thead className="bg-white/5 border-b border-white/10 text-xs font-bold uppercase tracking-wider text-gray-400">
                      <tr>
                        <th className="px-6 py-4">User Details</th>
                        <th className="px-6 py-4">Assigned Role</th>
                        <th className="px-6 py-4">Phone</th>
                        <th className="px-6 py-4">Registered Via</th>
                        <th className="px-6 py-4">Registration Date</th>
                        <th className="px-6 py-4 text-right">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-white/5">
                      {users
                        .filter(u => 
                          (u.name || '').toLowerCase().includes(searchQuery.toLowerCase()) || 
                          (u.email || '').toLowerCase().includes(searchQuery.toLowerCase())
                        )
                        .map(user => (
                          <tr key={user.id} className="hover:bg-white/[0.02] transition">
                            <td className="px-6 py-4">
                              <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#bae861] via-[#007aff] to-[#fa6b38] p-[1.5px]">
                                  <div className="w-full h-full bg-[#161622] rounded-[10px] flex items-center justify-center font-black text-sm text-white">
                                    {(user.name || 'U').charAt(0).toUpperCase()}
                                  </div>
                                </div>
                                <div>
                                  <div className="font-bold text-white">{user.name}</div>
                                  <div className="text-xs text-gray-400">{user.email}</div>
                                </div>
                              </div>
                            </td>
                            <td className="px-6 py-4">
                              <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-[11px] font-black uppercase tracking-wider ${
                                user.role === 'admin'
                                  ? 'bg-orange-500/10 text-orange-400 border border-orange-500/20'
                                  : user.role === 'scanner'
                                  ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                                  : 'bg-[#bae861]/10 text-[#bae861] border border-[#bae861]/20'
                              }`}>
                                {user.role}
                              </span>
                            </td>
                            <td className="px-6 py-4 text-xs text-gray-400">
                              {user.phone || '—'}
                            </td>
                            <td className="px-6 py-4 text-xs text-gray-400">
                              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white/5 border border-white/10 text-gray-300">
                                <Smartphone className="w-3.5 h-3.5 text-[#007aff]" />
                                {user.device || 'iOS App (MOVEI)'}
                              </span>
                            </td>
                            <td className="px-6 py-4 text-xs text-gray-400">
                              {new Date(user.registered_at).toLocaleDateString(undefined, {
                                month: 'short',
                                day: 'numeric',
                                year: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </td>
                            <td className="px-6 py-4 text-right">
                              <button
                                onClick={() => handleDeleteUser(user.id)}
                                className="p-2 text-gray-500 hover:text-red-400 hover:bg-red-500/10 rounded-lg transition"
                                title="Delete user"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </td>
                          </tr>
                        ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ======================= TAB 6: IN-APP UPDATES & ANNOUNCEMENTS ======================= */}
        {activeTab === 'announcements' && (
          <div className="space-y-6 animate-in fade-in duration-300">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div>
                <h2 className="text-2xl font-black tracking-tight text-white">In-App Broadcasts & Version Updates</h2>
                <p className="text-xs text-gray-400">Push promotional announcements, maintenance notices, and version updates directly to iOS users</p>
              </div>

              <button
                onClick={() => {
                  setAnnouncementForm({
                    title: '',
                    message: '',
                    type: 'announcement',
                    target_version: '2.1.0',
                    is_active: true,
                    priority: 'normal'
                  });
                  setShowAddAnnouncementModal(true);
                }}
                className="flex items-center gap-1.5 px-4 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold text-xs rounded-xl shadow-lg shadow-[#bae861]/15 transition-all cursor-pointer"
              >
                <Plus className="w-4 h-4" />
                <span>Create Broadcast</span>
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {announcements.map(ann => (
                <div
                  key={ann.id}
                  className={`border rounded-2xl p-5 space-y-3 transition-all ${
                    ann.is_active ? 'bg-white/5 border-white/15' : 'bg-white/[0.02] border-white/5 opacity-60'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] font-black uppercase px-2 py-0.5 rounded ${
                        ann.type === 'update' ? 'bg-blue-500/20 text-blue-400' :
                        ann.type === 'promo' ? 'bg-[#bae861]/20 text-[#bae861]' :
                        ann.type === 'maintenance' ? 'bg-amber-500/20 text-amber-400' :
                        'bg-purple-500/20 text-purple-400'
                      }`}>
                        {ann.type}
                      </span>
                      {ann.target_version && (
                        <span className="text-[10px] font-mono text-gray-400">
                          v{ann.target_version}
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleToggleAnnouncement(ann.id)}
                        className={`text-xs font-bold px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                          ann.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-gray-500/20 text-gray-400'
                        }`}
                      >
                        {ann.is_active ? 'Broadcasting' : 'Disabled'}
                      </button>
                      <button
                        onClick={() => handleDeleteAnnouncement(ann.id)}
                        className="p-1 text-red-400 hover:text-red-300"
                        title="Delete announcement"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  <h3 className="font-bold text-base text-white">{ann.title}</h3>
                  <p className="text-xs text-gray-300 leading-relaxed">{ann.message}</p>

                  <div className="pt-2 flex items-center justify-between text-[11px] text-gray-500">
                    <span>Priority: {ann.priority.toUpperCase()}</span>
                    <span>{new Date(ann.created_at).toLocaleDateString()}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </main>

      {/* ======================= MODAL: ADD / EDIT MOVIE ======================= */}
      {showAddMovieModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-[#121318] border border-white/15 rounded-3xl max-w-2xl w-full p-6 space-y-5 shadow-2xl animate-in zoom-in-95 duration-200 my-8">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <h3 className="font-bold text-lg text-white">
                {editingMovie ? 'Edit Movie Title' : 'Add New Movie to iOS Catalog'}
              </h3>
              <button
                onClick={() => setShowAddMovieModal(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-white bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveMovie} className="space-y-4 text-xs">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Movie Title *</label>
                  <input
                    type="text"
                    required
                    value={movieForm.title || ''}
                    onChange={e => setMovieForm({ ...movieForm, title: e.target.value })}
                    placeholder="e.g. Wicked, Avatar 3"
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Tagline</label>
                  <input
                    type="text"
                    value={movieForm.tagline || ''}
                    onChange={e => setMovieForm({ ...movieForm, tagline: e.target.value })}
                    placeholder="e.g. Everyone deserves the chance to fly."
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-gray-400 mb-1 font-semibold">Synopsis / Description</label>
                <textarea
                  rows={3}
                  value={movieForm.description || ''}
                  onChange={e => setMovieForm({ ...movieForm, description: e.target.value })}
                  placeholder="Plot summary displayed in iOS details modal..."
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                />
              </div>

              {/* Custom Movie Poster Artwork Section */}
              <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <ImageIcon className="w-4 h-4 text-[#bae861]" />
                    <label className="text-white font-bold text-xs uppercase tracking-wider">
                      Custom Movie Poster Artwork
                    </label>
                  </div>
                  <div className="flex items-center bg-black/40 p-0.5 rounded-lg border border-white/10 text-[10px]">
                    <button
                      type="button"
                      onClick={() => setPosterInputMode('upload')}
                      className={`px-2.5 py-1 rounded-md transition-all font-semibold cursor-pointer ${
                        posterInputMode === 'upload' ? 'bg-[#bae861] text-[#0e0f12]' : 'text-gray-400 hover:text-white'
                      }`}
                    >
                      Upload PNG / Image
                    </button>
                    <button
                      type="button"
                      onClick={() => setPosterInputMode('url')}
                      className={`px-2.5 py-1 rounded-md transition-all font-semibold cursor-pointer ${
                        posterInputMode === 'url' ? 'bg-[#bae861] text-[#0e0f12]' : 'text-gray-400 hover:text-white'
                      }`}
                    >
                      Image URL
                    </button>
                  </div>
                </div>

                {uploadError && (
                  <div className="p-2.5 bg-red-500/10 border border-red-500/30 rounded-xl text-red-300 text-[11px] flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                    <span>{uploadError}</span>
                  </div>
                )}

                {/* Hidden Native File Inputs */}
                <input
                  type="file"
                  ref={posterFileInputRef}
                  onChange={handlePosterFileUpload}
                  accept="image/png,image/jpeg,image/webp,image/jpg"
                  className="hidden"
                />
                <input
                  type="file"
                  ref={backdropFileInputRef}
                  onChange={handleBackdropFileUpload}
                  accept="image/png,image/jpeg,image/webp,image/jpg"
                  className="hidden"
                />

                {posterInputMode === 'upload' ? (
                  <div>
                    {movieForm.poster_url ? (
                      <div className="flex items-center gap-4 bg-black/30 border border-white/10 rounded-xl p-3">
                        {/* 2:3 Vertical Poster Thumbnail */}
                        <div className="relative w-20 h-28 rounded-lg overflow-hidden border border-white/20 bg-black flex-shrink-0 shadow-md group">
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img
                            src={movieForm.poster_url}
                            alt="Movie Poster Preview"
                            className="w-full h-full object-cover"
                          />
                          <div className="absolute top-1 left-1 bg-black/70 text-[#bae861] text-[9px] font-mono px-1 rounded font-bold">
                            2:3
                          </div>
                        </div>

                        <div className="flex-1 min-w-0 space-y-2">
                          <div>
                            <div className="flex items-center gap-1.5 text-[#bae861] font-semibold text-xs">
                              <CheckCircle2 className="w-3.5 h-3.5" />
                              <span>Poster Ready for iOS App</span>
                            </div>
                            <p className="text-[11px] text-gray-400 truncate mt-0.5" title={movieForm.poster_url}>
                              {movieForm.poster_url}
                            </p>
                          </div>

                          <div className="flex items-center gap-2 pt-1">
                            <button
                              type="button"
                              onClick={() => posterFileInputRef.current?.click()}
                              disabled={isUploadingPoster}
                              className="px-3 py-1.5 bg-white/10 hover:bg-white/15 text-white font-medium rounded-lg text-xs flex items-center gap-1.5 transition-all cursor-pointer"
                            >
                              <UploadCloud className="w-3.5 h-3.5 text-[#bae861]" />
                              {isUploadingPoster ? 'Uploading...' : 'Replace Poster PNG'}
                            </button>
                            <button
                              type="button"
                              onClick={() => setMovieForm(prev => ({ ...prev, poster_url: '', backdrop_url: '' }))}
                              className="px-2.5 py-1.5 text-red-400 hover:text-red-300 hover:bg-red-500/10 rounded-lg text-xs transition-all cursor-pointer"
                            >
                              Remove
                            </button>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div
                        onClick={() => posterFileInputRef.current?.click()}
                        className="border-2 border-dashed border-white/20 hover:border-[#bae861]/60 rounded-xl p-6 text-center cursor-pointer transition-all bg-white/[0.01] hover:bg-white/[0.03] group"
                      >
                        <div className="flex flex-col items-center justify-center gap-2">
                          <div className="w-12 h-12 rounded-2xl bg-[#bae861]/10 border border-[#bae861]/20 flex items-center justify-center text-[#bae861] group-hover:scale-110 transition-transform">
                            {isUploadingPoster ? (
                              <RefreshCw className="w-6 h-6 animate-spin" />
                            ) : (
                              <UploadCloud className="w-6 h-6" />
                            )}
                          </div>
                          <div>
                            <p className="text-white font-semibold text-xs">
                              {isUploadingPoster ? 'Uploading custom poster...' : 'Click to Upload Custom Movie Poster PNG'}
                            </p>
                            <p className="text-gray-400 text-[11px] mt-0.5">
                              Supports PNG, JPG, WebP (Ideal ratio 2:3 vertical, e.g. 600×900 or 1200×1800)
                            </p>
                          </div>
                          <span className="mt-1 px-3 py-1 bg-[#bae861] text-[#0e0f12] font-bold rounded-full text-[11px] group-hover:bg-[#c9f274] transition-colors">
                            Browse PNG File
                          </span>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <div>
                    <input
                      type="url"
                      value={movieForm.poster_url || ''}
                      onChange={e => setMovieForm({ ...movieForm, poster_url: e.target.value })}
                      placeholder="https://image.tmdb.org/... or unsplash poster URL"
                      className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                    />
                    <p className="text-[10px] text-gray-500 mt-1">
                      Direct image link (HTTPS) that will be fetched by the iOS app.
                    </p>
                  </div>
                )}

                {/* Optional Backdrop Banner Setting */}
                <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[11px]">
                  <label className="flex items-center gap-2 text-gray-300 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={usePosterAsBackdrop}
                      onChange={e => {
                        const checked = e.target.checked;
                        setUsePosterAsBackdrop(checked);
                        if (checked && movieForm.poster_url) {
                          setMovieForm(prev => ({ ...prev, backdrop_url: prev.poster_url }));
                        }
                      }}
                      className="rounded accent-[#bae861]"
                    />
                    <span>Use this poster artwork for iOS hero backdrop as well</span>
                  </label>

                  {!usePosterAsBackdrop && (
                    <button
                      type="button"
                      onClick={() => backdropFileInputRef.current?.click()}
                      className="text-[#bae861] hover:underline font-semibold flex items-center gap-1 cursor-pointer"
                    >
                      <UploadCloud className="w-3 h-3" />
                      {movieForm.backdrop_url && movieForm.backdrop_url !== movieForm.poster_url ? 'Change 16:9 Banner' : 'Upload 16:9 Banner PNG'}
                    </button>
                  )}
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Runtime (Mins)</label>
                  <input
                    type="number"
                    value={movieForm.runtime_minutes || 120}
                    onChange={e => setMovieForm({ ...movieForm, runtime_minutes: Number(e.target.value) })}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">IMDb / RT Rating</label>
                  <input
                    type="number"
                    step="0.1"
                    value={movieForm.rating || 8.0}
                    onChange={e => setMovieForm({ ...movieForm, rating: Number(e.target.value) })}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Status</label>
                  <select
                    value={movieForm.status || 'published'}
                    onChange={e => setMovieForm({ ...movieForm, status: e.target.value as MovieStatus })}
                    className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  >
                    <option value="published">Published (Live in App)</option>
                    <option value="draft">Draft (Hidden)</option>
                    <option value="archived">Archived</option>
                  </select>
                </div>
              </div>

              <div className="pt-4 border-t border-white/10 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddMovieModal(false)}
                  className="px-4 py-2 bg-white/10 hover:bg-white/15 text-white font-semibold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold rounded-xl shadow-lg shadow-[#bae861]/20 cursor-pointer"
                >
                  {editingMovie ? 'Save Changes' : 'Publish Movie'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================= MODAL: ADD SHOW ======================= */}
      {showAddShowModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#121318] border border-white/15 rounded-3xl max-w-lg w-full p-6 space-y-5 shadow-2xl animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <h3 className="font-bold text-lg text-white">Schedule New Screening</h3>
              <button
                onClick={() => setShowAddShowModal(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-white bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveShow} className="space-y-4 text-xs">
              <div>
                <label className="block text-gray-400 mb-1 font-semibold">Select Movie</label>
                <select
                  value={showForm.movie_id}
                  onChange={e => setShowForm({ ...showForm, movie_id: e.target.value })}
                  className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                >
                  {movies.map(m => (
                    <option key={m.id} value={m.id}>{m.title} ({m.runtime_minutes} mins)</option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Cinema Venue</label>
                  <select
                    value={showForm.cinema_id}
                    onChange={e => {
                      const cid = e.target.value;
                      const c = cinemas.find(item => item.id === cid);
                      setShowForm({
                        ...showForm,
                        cinema_id: cid,
                        screen_id: c?.screens?.[0]?.id || ''
                      });
                    }}
                    className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  >
                    {cinemas.map(c => (
                      <option key={c.id} value={c.id}>{c.name}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Screen</label>
                  <select
                    value={showForm.screen_id}
                    onChange={e => setShowForm({ ...showForm, screen_id: e.target.value })}
                    className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  >
                    {cinemas.find(c => c.id === showForm.cinema_id)?.screens?.map(s => (
                      <option key={s.id} value={s.id}>{s.name} ({s.screen_type.toUpperCase()})</option>
                    ))}
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-gray-400 mb-1 font-semibold">Start Showtime</label>
                <input
                  type="datetime-local"
                  required
                  value={showForm.start_time}
                  onChange={e => setShowForm({ ...showForm, start_time: e.target.value })}
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                />
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Standard (Rs.)</label>
                  <input
                    type="number"
                    value={showForm.price_standard}
                    onChange={e => setShowForm({ ...showForm, price_standard: Number(e.target.value) })}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Premium (Rs.)</label>
                  <input
                    type="number"
                    value={showForm.price_premium}
                    onChange={e => setShowForm({ ...showForm, price_premium: Number(e.target.value) })}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">VIP (Rs.)</label>
                  <input
                    type="number"
                    value={showForm.price_vip}
                    onChange={e => setShowForm({ ...showForm, price_vip: Number(e.target.value) })}
                    className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-white/10 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddShowModal(false)}
                  className="px-4 py-2 bg-white/10 hover:bg-white/15 text-white font-semibold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold rounded-xl shadow-lg shadow-[#bae861]/20 cursor-pointer"
                >
                  Confirm Show
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================= MODAL: BROADCAST UPDATE ======================= */}
      {showAddAnnouncementModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#121318] border border-white/15 rounded-3xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <h3 className="font-bold text-lg text-white">Broadcast In-App Notice</h3>
              <button
                onClick={() => setShowAddAnnouncementModal(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-white bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveAnnouncement} className="space-y-4 text-xs">
              <div>
                <label className="block text-gray-400 mb-1 font-semibold">Title</label>
                <input
                  type="text"
                  required
                  value={announcementForm.title || ''}
                  onChange={e => setAnnouncementForm({ ...announcementForm, title: e.target.value })}
                  placeholder="e.g. Wicked Premier Tickets Now Live"
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                />
              </div>

              <div>
                <label className="block text-gray-400 mb-1 font-semibold">Message</label>
                <textarea
                  rows={3}
                  required
                  value={announcementForm.message || ''}
                  onChange={e => setAnnouncementForm({ ...announcementForm, message: e.target.value })}
                  placeholder="Body of the alert shown to iOS users..."
                  className="w-full bg-white/5 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Type</label>
                  <select
                    value={announcementForm.type || 'announcement'}
                    onChange={e => setAnnouncementForm({ ...announcementForm, type: e.target.value as any })}
                    className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  >
                    <option value="announcement">Announcement</option>
                    <option value="update">App Version Update</option>
                    <option value="promo">Promotion / Premier</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>
                <div>
                  <label className="block text-gray-400 mb-1 font-semibold">Priority</label>
                  <select
                    value={announcementForm.priority || 'normal'}
                    onChange={e => setAnnouncementForm({ ...announcementForm, priority: e.target.value as any })}
                    className="w-full bg-[#1e1f26] border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-[#bae861]"
                  >
                    <option value="low">Low</option>
                    <option value="normal">Normal</option>
                    <option value="high">High</option>
                    <option value="urgent">Urgent</option>
                  </select>
                </div>
              </div>

              <div className="pt-4 border-t border-white/10 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddAnnouncementModal(false)}
                  className="px-4 py-2 bg-white/10 hover:bg-white/15 text-white font-semibold rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#bae861] hover:bg-[#c9f07a] text-black font-bold rounded-xl shadow-lg shadow-[#bae861]/20 cursor-pointer"
                >
                  Broadcast to App
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ======================= MODAL: INSPECT TICKET PASS ======================= */}
      {selectedTicketModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#121318] border border-white/15 rounded-3xl max-w-md w-full p-6 space-y-5 shadow-2xl animate-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <div className="flex items-center gap-2">
                <TicketIcon className="w-5 h-5 text-[#bae861]" />
                <h3 className="font-bold text-lg text-white">Ticket Pass Inspector</h3>
              </div>
              <button
                onClick={() => setSelectedTicketModal(null)}
                className="p-1 rounded-lg text-gray-400 hover:text-white bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4 text-xs">
              {/* Barcode visual */}
              <div className="p-4 bg-white rounded-2xl flex flex-col items-center justify-center space-y-2 text-black">
                <div className="font-mono text-2xl font-black tracking-widest">
                  ||||| | ||| |||| | ||
                </div>
                <div className="font-mono text-xs text-gray-600 font-bold">
                  {selectedTicketModal.barcode_value}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3 p-3 bg-white/5 rounded-xl">
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Pass Code</span>
                  <p className="font-mono font-bold text-white">{selectedTicketModal.ticket_code}</p>
                </div>
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Status</span>
                  <p className="font-bold uppercase text-[#bae861]">{selectedTicketModal.status}</p>
                </div>
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Movie</span>
                  <p className="font-semibold text-white">{selectedTicketModal.movie_title || 'Inception'}</p>
                </div>
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Reserved Seats</span>
                  <p className="font-semibold text-[#bae861] font-mono">{selectedTicketModal.seat_label || 'General'}</p>
                  {selectedTicketModal.seat_label && (selectedTicketModal.seat_label.includes('·') || selectedTicketModal.seat_label.includes(',')) && (
                    <span className="text-[10px] text-gray-400 block font-semibold mt-0.5">
                      {selectedTicketModal.seat_label.split(/[·,]/).filter(Boolean).length} Seats on this pass
                    </span>
                  )}
                </div>
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Customer</span>
                  <p className="font-semibold text-white">{selectedTicketModal.customer_name || 'Customer'}</p>
                </div>
                <div>
                  <span className="text-[10px] text-gray-400 uppercase font-semibold">Amount</span>
                  <p className="font-semibold text-white">Rs. {selectedTicketModal.price || 1800}</p>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="pt-2 flex flex-col gap-2">
                {selectedTicketModal.status === 'pending' && (
                  <button
                    onClick={() => handleApproveTicket(selectedTicketModal.id)}
                    className="w-full py-2.5 bg-emerald-500 hover:bg-emerald-400 text-black font-black text-xs rounded-xl shadow-lg shadow-emerald-500/20 cursor-pointer"
                  >
                    Approve & Issue Pass
                  </button>
                )}

                {selectedTicketModal.status === 'confirmed' && (
                  <button
                    onClick={() => handleAdmitTicket(selectedTicketModal.id)}
                    className="w-full py-2.5 bg-blue-500 hover:bg-blue-400 text-white font-bold text-xs rounded-xl shadow-lg shadow-blue-500/20 cursor-pointer"
                  >
                    Admit / Mark Used at Entrance
                  </button>
                )}

                {selectedTicketModal.status !== 'cancelled' && (
                  <button
                    onClick={() => handleCancelTicket(selectedTicketModal.id)}
                    className="w-full py-2 bg-red-500/15 hover:bg-red-500/25 text-red-400 font-semibold text-xs rounded-xl cursor-pointer"
                  >
                    Cancel Pass & Refund
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
