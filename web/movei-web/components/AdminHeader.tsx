'use client';

import React from 'react';
import { 
  Film, 
  Calendar, 
  CheckCircle2, 
  Building2, 
  Radio, 
  LayoutDashboard, 
  Plus, 
  Smartphone, 
  Search,
  Sparkles,
  Users
} from 'lucide-react';

export type AdminTab = 'overview' | 'movies' | 'shows' | 'tickets' | 'cinemas' | 'users' | 'announcements';

interface AdminHeaderProps {
  activeTab: AdminTab;
  setActiveTab: (tab: AdminTab) => void;
  pendingApprovalsCount: number;
  onNewMovie: () => void;
  onNewShow: () => void;
  onNewAnnouncement: () => void;
  searchQuery: string;
  setSearchQuery: (q: string) => void;
}

export default function AdminHeader({
  activeTab,
  setActiveTab,
  pendingApprovalsCount,
  onNewMovie,
  onNewShow,
  onNewAnnouncement,
  searchQuery,
  setSearchQuery
}: AdminHeaderProps) {
  const tabs: { id: AdminTab; label: string; icon: React.ElementType; badge?: number }[] = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'movies', label: 'Movies & Releases', icon: Film },
    { id: 'shows', label: 'Showtimes', icon: Calendar },
    { id: 'tickets', label: 'Ticket Approvals', icon: CheckCircle2, badge: pendingApprovalsCount },
    { id: 'cinemas', label: 'Cinemas & Screens', icon: Building2 },
    { id: 'users', label: 'Registered Users', icon: Users },
    { id: 'announcements', label: 'In-App Updates', icon: Radio },
  ];

  return (
    <header className="sticky top-0 z-40 w-full bg-[#0a0a0f]/90 backdrop-blur-xl border-b border-white/10 select-none shadow-2xl">
      {/* Top Banner Row */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
        
        {/* Brand & iOS Status */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#bae861] via-[#007aff] to-[#fa6b38] p-[1.5px] shadow-lg shadow-[#bae861]/20">
            <div className="w-full h-full bg-black rounded-[10px] flex items-center justify-center font-black text-white text-base">
              M
            </div>
          </div>
          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-lg tracking-wider text-white">MOVEI</span>
              <span className="text-[10px] uppercase font-black tracking-widest px-2 py-0.5 rounded-full bg-[#bae861]/20 text-[#bae861] border border-[#bae861]/30">
                Admin Studio
              </span>
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-400">
              <span className="flex h-2 w-2 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span>Syncing with iOS App (Active)</span>
            </div>
          </div>
        </div>

        {/* Global Search */}
        <div className="hidden md:flex flex-1 max-w-xs relative items-center">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 pointer-events-none" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search catalog, tickets, codes..."
            className="w-full bg-white/5 border border-white/10 rounded-xl pl-9 pr-3 py-1.5 text-xs text-white placeholder-gray-500 focus:outline-none focus:border-[#bae861]/60 transition-colors"
          />
        </div>

        {/* Quick Actions */}
        <div className="flex items-center gap-2 sm:gap-3">
          <button
            onClick={onNewMovie}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#bae861] text-black hover:bg-[#c9f07a] font-bold text-xs tracking-tight transition-all shadow-md shadow-[#bae861]/15 cursor-pointer active:scale-95"
          >
            <Plus className="w-4 h-4" />
            <span className="hidden sm:inline">Add Movie</span>
          </button>

          <button
            onClick={onNewShow}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/15 text-white border border-white/10 font-semibold text-xs tracking-tight transition-all cursor-pointer active:scale-95"
          >
            <Plus className="w-4 h-4" />
            <span className="hidden sm:inline">Add Show</span>
          </button>

          <button
            onClick={onNewAnnouncement}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-[#007aff]/30 to-[#fa6b38]/30 hover:from-[#007aff]/40 hover:to-[#fa6b38]/40 text-white border border-white/15 font-semibold text-xs tracking-tight transition-all cursor-pointer active:scale-95"
          >
            <Radio className="w-3.5 h-3.5 text-[#bae861]" />
            <span className="hidden sm:inline">Broadcast</span>
          </button>

          <div className="hidden lg:flex items-center gap-1.5 pl-2 border-l border-white/10 text-xs text-gray-400">
            <Smartphone className="w-4 h-4 text-gray-500" />
            <span className="text-[11px] font-mono text-gray-400">iOS 17+</span>
          </div>
        </div>
      </div>

      {/* Navigation Tabs Row */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center gap-2 overflow-x-auto no-scrollbar border-t border-white/5 py-2">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-3.5 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition-all cursor-pointer ${
                isActive
                  ? 'bg-white text-black shadow-md shadow-white/10'
                  : 'text-gray-400 hover:text-white hover:bg-white/5'
              }`}
            >
              <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-black' : 'text-gray-400'}`} />
              <span>{tab.label}</span>
              {tab.badge !== undefined && tab.badge > 0 && (
                <span className={`px-1.5 py-0.2 rounded-full text-[10px] font-extrabold ${
                  isActive ? 'bg-red-500 text-white' : 'bg-red-500/80 text-white'
                }`}>
                  {tab.badge}
                </span>
              )}
            </button>
          );
        })}
      </div>
    </header>
  );
}
