import { PricingTier } from '../types';

export const pricingTiers: PricingTier[] = [
  {
    name: 'free',
    price: 0,
    features: [
      'Basic profile creation',
      'Up to 5 portfolio items',
      'Standard search visibility',
      'Community support'
    ],
    portfolioLimit: 5,
    featured: false
  },
  {
    name: 'silver',
    price: 29,
    features: [
      'Enhanced profile features',
      'Up to 25 portfolio items',
      'Priority search ranking',
      'Video portfolio support',
      'Analytics dashboard',
      'Email support'
    ],
    portfolioLimit: 25,
    featured: true
  },
  {
    name: 'gold',
    price: 99,
    features: [
      'Premium profile with custom branding',
      'Unlimited portfolio items',
      'Top search placement',
      'HD video support',
      'Advanced analytics',
      'Priority support',
      'Portfolio website builder',
      'Lead generation tools'
    ],
    portfolioLimit: Infinity,
    featured: false
  }
];

export const filmRoles = [
  'Producer',
  'Director', 
  'Musician',
  'Hero',
  'Heroine',
  'Character Artist',
  'Lighting Technician',
  'Transportation',
  'Catering',
  'VFX Artist',
  'Cameraman',
  'Costume Designer',
  'Acting Trainer',
  'Makeup Artist',
  'Infrastructure Provider',
  'Other'
] as const;