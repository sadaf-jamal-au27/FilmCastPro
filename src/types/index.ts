export interface User {
  id: string;
  name: string;
  email: string;
  role: FilmRole;
  plan: PricingPlan;
  profileImage?: string;
  bio?: string;
  location?: string;
  experience?: string;
  portfolio: PortfolioItem[];
  createdAt: Date;
}

export interface PortfolioItem {
  id: string;
  title: string;
  description: string;
  type: 'image' | 'video' | 'document';
  url: string;
  thumbnail?: string;
  tags: string[];
  createdAt: Date;
}

export type FilmRole = 
  | 'Producer'
  | 'Director'
  | 'Musician'
  | 'Hero'
  | 'Heroine'
  | 'Character Artist'
  | 'Lighting Technician'
  | 'Transportation'
  | 'Catering'
  | 'VFX Artist'
  | 'Cameraman'
  | 'Costume Designer'
  | 'Acting Trainer'
  | 'Makeup Artist'
  | 'Infrastructure Provider'
  | 'Other';

export type PricingPlan = 'free' | 'silver' | 'gold';

export interface PricingTier {
  name: PricingPlan;
  price: number;
  features: string[];
  portfolioLimit: number;
  featured: boolean;
}