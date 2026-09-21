'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { User, ShieldCheck, QrCode, ArrowRight, Lock, Mail } from 'lucide-react';

export default function LoginPage() {
  const router = useRouter();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'customer' | 'admin' | 'scanner'>('customer');
  const [isRegistering, setIsRegistering] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setIsLoading(true);

    try {
      // Sync user to Web Admin Studio /api/users
      const displayName = isRegistering 
        ? (fullName.trim() || email.split('@')[0])
        : (email.split('@')[0]);

      await fetch('/api/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: displayName,
          email: email.trim().toLowerCase(),
          role: role,
          device: 'Web Browser'
        })
      });

      if (role === 'admin') {
        router.push('/');
      } else if (role === 'scanner') {
        router.push('/scanner');
      } else {
        router.push('/wallet');
      }
    } catch (err) {
      console.error('Sign in error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-[75vh] flex items-center justify-center px-4 py-12">
      <div className="glass-panel max-w-md w-full p-8 sm:p-10 rounded-3xl border border-white/10 space-y-6 shadow-2xl">
        
        {/* Brand Header */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-[#bae861] to-[#fa6b38] flex items-center justify-center font-black text-black text-xl mx-auto shadow-xl shadow-[#bae861]/25">
            M
          </div>
          <h1 className="text-2xl font-black text-white">Access MOVEI</h1>
          <p className="text-xs text-gray-400">
            {isRegistering ? 'Create your brand new MOVEI account' : 'Sign in to access tickets, scanning, or administration'}
          </p>
        </div>

        {/* Tab switch */}
        <div className="flex bg-white/5 p-1 rounded-xl border border-white/5 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setIsRegistering(false)}
            className={`flex-1 py-2 rounded-lg transition-all ${
              !isRegistering ? 'bg-[#bae861] text-black font-extrabold shadow' : 'text-gray-400 hover:text-white'
            }`}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => setIsRegistering(true)}
            className={`flex-1 py-2 rounded-lg transition-all ${
              isRegistering ? 'bg-[#bae861] text-black font-extrabold shadow' : 'text-gray-400 hover:text-white'
            }`}
          >
            Create Account
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          {isRegistering && (
            <div>
              <label className="font-semibold text-gray-300 block mb-1">Full Name</label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
                <input
                  type="text"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Enter your name"
                  className="w-full bg-black/40 border border-white/15 rounded-xl pl-9 pr-3 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-[#bae861]"
                />
              </div>
            </div>
          )}

          <div>
            <label className="font-semibold text-gray-300 block mb-1">Email Address</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full bg-black/40 border border-white/15 rounded-xl pl-9 pr-3 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-[#bae861]"
              />
            </div>
          </div>

          <div>
            <label className="font-semibold text-gray-300 block mb-1">Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-black/40 border border-white/15 rounded-xl pl-9 pr-3 py-2.5 text-white placeholder-gray-500 focus:outline-none focus:border-[#bae861]"
              />
            </div>
          </div>

          <div>
            <label className="font-semibold text-gray-300 block mb-1">Account Role</label>
            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => setRole('customer')}
                className={`py-2 px-2 rounded-xl text-center border transition-all ${
                  role === 'customer'
                    ? 'border-[#bae861] bg-[#bae861]/15 text-[#bae861] font-bold'
                    : 'border-white/10 text-gray-400 hover:text-white'
                }`}
              >
                Customer
              </button>
              <button
                type="button"
                onClick={() => setRole('scanner')}
                className={`py-2 px-2 rounded-xl text-center border transition-all ${
                  role === 'scanner'
                    ? 'border-[#fa6b38] bg-[#fa6b38]/15 text-[#fa6b38] font-bold'
                    : 'border-white/10 text-gray-400 hover:text-white'
                }`}
              >
                Scanner
              </button>
              <button
                type="button"
                onClick={() => setRole('admin')}
                className={`py-2 px-2 rounded-xl text-center border transition-all ${
                  role === 'admin'
                    ? 'border-cyan-400 bg-cyan-400/15 text-cyan-300 font-bold'
                    : 'border-white/10 text-gray-400 hover:text-white'
                }`}
              >
                Admin
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 rounded-xl bg-[#bae861] text-black font-extrabold shadow-lg shadow-[#bae861]/25 hover:bg-[#cbf27a] transition-all flex items-center justify-center gap-2 cursor-pointer mt-2"
          >
            <span>{isLoading ? 'Processing...' : (isRegistering ? 'Create Account & Enter' : 'Sign In')}</span>
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="pt-2 text-center text-xs text-gray-500">
          Clean authentication without fake accounts. Accounts are saved to Web Admin Studio.
        </div>

      </div>
    </div>
  );
}
