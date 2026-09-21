import { Movie, Cinema, Show, Booking, Ticket, Profile, AppAnnouncement } from '../types';

export const MOCK_MOVIES: Movie[] = [
  {
    id: 'm-wicked',
    title: 'Wicked',
    slug: 'wicked',
    tagline: 'Everyone deserves the chance to fly.',
    description: 'Elphaba, an ostracized but fiery girl and Glinda, a bubbly popular aristocrat, forge an improbable bond in the magical land of Oz, before destiny pulls them into the legendary conflict.',
    poster_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=600&h=900&q=80',
    backdrop_url: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=1920&h=1080&q=80',
    trailer_url: 'https://www.youtube.com/watch?v=6COmYeLsz4c',
    runtime_minutes: 160,
    release_date: '2024-11-22',
    rating: 8.5,
    genres: ['Fantasy', 'Musical', 'Adventure'],
    language: 'English',
    age_rating: 'PG',
    status: 'published'
  },
  {
    id: 'm-inception',
    title: 'Inception',
    slug: 'inception',
    tagline: 'Your mind is the scene of the crime.',
    description: 'A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O., but his tragic past may doom the project and his team to disaster.',
    poster_url: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=600&h=900&q=80',
    backdrop_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1920&h=1080&q=80',
    trailer_url: 'https://www.youtube.com/watch?v=YoHD9XEInc0',
    runtime_minutes: 148,
    release_date: '2010-07-16',
    rating: 8.8,
    genres: ['Action', 'Sci-Fi', 'Adventure'],
    language: 'English',
    age_rating: 'PG-13',
    status: 'published'
  },
  {
    id: 'm-oppenheimer',
    title: 'Oppenheimer',
    slug: 'oppenheimer',
    tagline: 'The world forever changes.',
    description: 'The story of American scientist J. Robert Oppenheimer and his role in the development of the atomic bomb during World War II.',
    poster_url: 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?auto=format&fit=crop&w=600&h=900&q=80',
    backdrop_url: 'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?auto=format&fit=crop&w=1920&h=1080&q=80',
    trailer_url: 'https://www.youtube.com/watch?v=uYPbbksJxIg',
    runtime_minutes: 180,
    release_date: '2023-07-21',
    rating: 8.9,
    genres: ['Biography', 'Drama', 'History'],
    language: 'English',
    age_rating: 'R',
    status: 'published'
  },
  {
    id: 'm-interstellar',
    title: 'Interstellar',
    slug: 'interstellar',
    tagline: 'Mankind was born on Earth. It was never meant to die here.',
    description: 'When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot, Joseph Cooper, is tasked to pilot a spacecraft, along with a team of researchers, to find a new planet for humans.',
    poster_url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=600&h=900&q=80',
    backdrop_url: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=1920&h=1080&q=80',
    trailer_url: 'https://www.youtube.com/watch?v=zSWdZVtXT7E',
    runtime_minutes: 169,
    release_date: '2014-11-07',
    rating: 8.7,
    genres: ['Adventure', 'Drama', 'Sci-Fi'],
    language: 'English',
    age_rating: 'PG-13',
    status: 'published'
  },
  {
    id: 'm-spiderman',
    title: 'Spider-Man: Brand New Day',
    slug: 'spider-man--brand-new-day',
    tagline: 'Even if no one remembers me, I\'ll keep protecting.',
    description: 'A forgotten Peter Parker lives alone as a full-time Spider-Man until mounting pressure triggers a dangerous change and a powerful new enemy emerges.',
    poster_url: 'https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=600&q=90',
    backdrop_url: 'https://images.unsplash.com/photo-1531259683007-016a7b628fc3?auto=format&fit=crop&w=1800&q=90',
    trailer_url: '',
    runtime_minutes: 145,
    rating: 8.8,
    release_date: '2026-09-21',
    genres: ['Action', 'Sci-Fi', 'Superhero'],
    language: 'English',
    age_rating: 'PG-13',
    status: 'published'
  },
  {
    id: 'm-pak',
    title: 'PAK',
    slug: 'pak',
    tagline: 'A new cinematic force begins.',
    description: 'An intense thrilling odyssey of resilience, courage and unyielding redemption.',
    poster_url: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&w=600&q=80',
    backdrop_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1920&h=1080&q=80',
    trailer_url: '',
    runtime_minutes: 135,
    rating: 8.5,
    release_date: '2026-09-21',
    genres: ['Action', 'Thriller'],
    language: 'English',
    age_rating: 'PG-13',
    status: 'published'
  }
];

export const MOCK_CINEMAS: Cinema[] = [
  {
    id: 'cin-01',
    name: 'Cinemax Colombo',
    city: 'Colombo',
    address: '42 Galle Road, Colombo 03',
    phone: '+94 11 234 5678',
    status: 'active',
    screens: [
      {
        id: 'sc111111-1111-1111-1111-111111111111',
        cinema_id: 'cin-01',
        name: 'Screen 04 (IMAX Laser)',
        screen_number: 4,
        capacity: 120,
        screen_type: 'imax'
      }
    ]
  },
  {
    id: 'cin-02',
    name: 'Majestic Cineplex',
    city: 'Colombo',
    address: '10 Station Road, Bambalapitiya',
    phone: '+94 11 258 1234',
    status: 'active',
    screens: [
      {
        id: 'sc222222-2222-2222-2222-222222222222',
        cinema_id: 'cin-02',
        name: 'Screen 01 (Platinum)',
        screen_number: 1,
        capacity: 90,
        screen_type: 'standard'
      }
    ]
  },
  {
    id: 'cin-03',
    name: 'Scope Cinemas Colombo City',
    city: 'Colombo',
    address: 'Colombo City Centre, 137 Sir James Pieris Mawatha',
    phone: '+94 11 777 8899',
    status: 'active',
    screens: [
      {
        id: 'sc333333-3333-3333-3333-333333333333',
        cinema_id: 'cin-03',
        name: 'Screen 02 (Dolby Atmos)',
        screen_number: 2,
        capacity: 105,
        screen_type: 'standard'
      }
    ]
  }
];

export const MOCK_SHOWS: Show[] = [
  {
    id: 'sh-wicked-01',
    movie_id: 'm-wicked',
    cinema_id: 'cin-01',
    screen_id: 'sc111111-1111-1111-1111-111111111111',
    start_time: '2026-09-22T14:00:00Z',
    end_time: '2026-09-22T16:40:00Z',
    price_standard: 1200,
    price_premium: 1800,
    price_vip: 2500,
    status: 'scheduled',
    movie: MOCK_MOVIES[0],
    cinema: MOCK_CINEMAS[0],
    screen: MOCK_CINEMAS[0].screens![0]
  },
  {
    id: 'sh-spiderman-01',
    movie_id: 'm-spiderman',
    cinema_id: 'cin-01',
    screen_id: 'sc111111-1111-1111-1111-111111111111',
    start_time: '2026-09-22T17:30:00Z',
    end_time: '2026-09-22T20:00:00Z',
    price_standard: 1400,
    price_premium: 2000,
    price_vip: 2800,
    status: 'scheduled',
    movie: MOCK_MOVIES[4],
    cinema: MOCK_CINEMAS[0],
    screen: MOCK_CINEMAS[0].screens![0]
  },
  {
    id: 'sh-inception-01',
    movie_id: 'm-inception',
    cinema_id: 'cin-02',
    screen_id: 'sc222222-2222-2222-2222-222222222222',
    start_time: '2026-09-22T19:00:00Z',
    end_time: '2026-09-22T21:30:00Z',
    price_standard: 1000,
    price_premium: 1500,
    price_vip: 2200,
    status: 'scheduled',
    movie: MOCK_MOVIES[1],
    cinema: MOCK_CINEMAS[1],
    screen: MOCK_CINEMAS[1].screens![0]
  },
  {
    id: 'sh-oppenheimer-01',
    movie_id: 'm-oppenheimer',
    cinema_id: 'cin-03',
    screen_id: 'sc333333-3333-3333-3333-333333333333',
    start_time: '2026-09-22T20:00:00Z',
    end_time: '2026-09-22T23:00:00Z',
    price_standard: 1500,
    price_premium: 2200,
    price_vip: 3000,
    status: 'scheduled',
    movie: MOCK_MOVIES[2],
    cinema: MOCK_CINEMAS[2],
    screen: MOCK_CINEMAS[2].screens![0]
  },
  {
    id: 'sh-interstellar-01',
    movie_id: 'm-interstellar',
    cinema_id: 'cin-03',
    screen_id: 'sc333333-3333-3333-3333-333333333333',
    start_time: '2026-09-23T15:00:00Z',
    end_time: '2026-09-23T17:50:00Z',
    price_standard: 1500,
    price_premium: 2200,
    price_vip: 3000,
    status: 'scheduled',
    movie: MOCK_MOVIES[3],
    cinema: MOCK_CINEMAS[2],
    screen: MOCK_CINEMAS[2].screens![0]
  },
  {
    id: 'sh-pak-01',
    movie_id: 'm-pak',
    cinema_id: 'cin-02',
    screen_id: 'sc222222-2222-2222-2222-222222222222',
    start_time: '2026-09-23T18:00:00Z',
    end_time: '2026-09-23T20:15:00Z',
    price_standard: 1100,
    price_premium: 1600,
    price_vip: 2400,
    status: 'scheduled',
    movie: MOCK_MOVIES[5],
    cinema: MOCK_CINEMAS[1],
    screen: MOCK_CINEMAS[1].screens![0]
  }
];

export const MOCK_USERS: Profile[] = [];

export const MOCK_TICKETS: Ticket[] = [];

export const MOCK_BOOKINGS: Booking[] = [];

export const MOCK_ANNOUNCEMENTS: AppAnnouncement[] = [
  {
    id: 'ann-01',
    title: 'Brand New MOVEI Cinema System Live',
    message: 'Featuring Wicked, Inception, Oppenheimer, Interstellar, Spider-Man, and PAK.',
    type: 'promo',
    is_active: true,
    priority: 'high',
    created_at: new Date().toISOString()
  }
];
