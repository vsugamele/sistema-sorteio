import React, { createContext, useContext, useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface PointsContextType {
  points: {
    approved: number;
    pending: number;
  };
  fetchPoints: () => Promise<void>;
  isRefreshing: boolean;
}

const PointsContext = createContext<PointsContextType | undefined>(undefined);

const RETRY_DELAY = 3000; // 3 seconds between retries
const MAX_RETRIES = 3;
const REFRESH_INTERVAL = 10000; // 10 seconds

export function PointsProvider({ children }: { children: React.ReactNode }) {
  const [points, setPoints] = useState({ approved: 0, pending: 0 });
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastRefresh, setLastRefresh] = useState(Date.now());
  const [retryCount, setRetryCount] = useState(0);
  const [retryTimeout, setRetryTimeout] = useState<NodeJS.Timeout | null>(null);
  const [error, setError] = useState<Error | null>(null);

  // Clear points when user is not authenticated
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_OUT') {
        setPoints({ approved: 0, pending: 0 });
      } else if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
        // Fetch points immediately when user signs in or token is refreshed
        console.log('Auth state changed to:', event, '- fetching points');
        fetchPoints(true);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Function to check if points have changed
  const havePointsChanged = (newPoints: { approved: number; pending: number }) => {
    return newPoints.approved !== points.approved || newPoints.pending !== points.pending;
  };

  const fetchPoints = async (retry = true) => {
    try {
      setIsRefreshing(true);
      setError(null);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setPoints({ approved: 0, pending: 0 });
        setIsRefreshing(false);
        return;
      }

      console.log('Fetching points for user:', user.id);

      // Get available and pending points
      const [
        { data: availablePoints, error: pointsError },
        { data: pendingPoints, error: pendingError }
      ] = await Promise.all([
        supabase.rpc('get_available_points_v2', { user_uuid: user.id }),
        supabase.rpc('get_pending_points_v2', { user_uuid: user.id })
      ]);

      console.log('Points response:', { availablePoints, pendingPoints });

      if (pointsError || pendingError) {
        // Clear any existing retry timeout
        if (retryTimeout) {
          clearTimeout(retryTimeout);
        }

        // If we should retry and haven't exceeded max retries
        if (retry && retryCount < MAX_RETRIES) {
          const timeout = setTimeout(() => {
            setRetryCount(prev => prev + 1);
            fetchPoints(true);
          }, RETRY_DELAY);
          setRetryTimeout(timeout);
          return;
        }

        const error = pointsError || pendingError;
        console.error('Error fetching points:', error);
        setError(error);
        setPoints({ approved: 0, pending: 0 });
        return;
      }

      // Reset retry count on successful fetch
      setRetryCount(0);
      if (retryTimeout) {
        clearTimeout(retryTimeout);
        setRetryTimeout(null);
      }

      // Calculate new points
      const newPoints = {
        approved: availablePoints || 0,
        pending: Math.max(0, pendingPoints || 0)
      };

      // Only update if points have changed
      if (havePointsChanged(newPoints)) {
        setPoints(newPoints);
      }

      setLastRefresh(Date.now());
    } catch (err) {
      setError(err as Error);
      console.error('Error fetching points:', err);
      setPoints({ approved: 0, pending: 0 });
    } finally {
      setIsRefreshing(false);
    }
  };

  // Auto-refresh points every 30 seconds if there are pending points
  useEffect(() => {
    if (points.pending > 0 || error) {
      const intervalId = setInterval(async () => {
        const timeSinceLastRefresh = Date.now() - lastRefresh;
        // Only refresh if it's been more than 30 seconds since the last refresh
        if (timeSinceLastRefresh >= REFRESH_INTERVAL) {
          await fetchPoints(true);
        }
      }, REFRESH_INTERVAL);
      
      return () => {
        clearInterval(intervalId);
        if (retryTimeout) {
          clearTimeout(retryTimeout);
        }
      };
    }
  }, [points.pending, lastRefresh, error]);

  useEffect(() => {
    const setupRealtimeSubscription = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      // Subscribe to realtime updates
      const channel = supabase
        .channel('points_changes')
        .on('postgres_changes', 
          {
            event: '*',
            schema: 'public',
            table: 'deposits',
            filter: `user_id=eq.${user.id}`
          }, 
          () => fetchPoints(true)
        )
        .on('postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'user_missions',
            filter: `user_id=eq.${user.id}`
          },
          () => fetchPoints(true)
        )
        .subscribe();

      // Initial fetch
      fetchPoints();

      return () => {
        if (retryTimeout) {
          clearTimeout(retryTimeout);
        }
        channel.unsubscribe();
      };
    };

    setupRealtimeSubscription();
  }, []);

  return (
    <PointsContext.Provider value={{ points, fetchPoints, isRefreshing }}>
      {children}
    </PointsContext.Provider>
  );
}

export function usePoints() {
  const context = useContext(PointsContext);
  if (context === undefined) {
    throw new Error('usePoints must be used within a PointsProvider');
  }
  return context;
}