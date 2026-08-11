-- Vote draw interstitial before tiebreaker race
alter type public.room_phase add value if not exists 'draw' after 'voting';
