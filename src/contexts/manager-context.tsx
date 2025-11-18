
'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import type { Manager } from "@/lib/types";

// Define the shape of the context data
interface ManagerContextType {
  manager: Manager | null;
  isLoading: boolean;
  forceUpdate: () => void; // A function to trigger a data reload
}

// Create the context
const ManagerContext = createContext<ManagerContextType | null>(null);

// Custom hook to use the manager context
export function useManager() {
  const context = useContext(ManagerContext);
  if (!context) {
    throw new Error('useManager must be used within a ManagerProvider');
  }
  return context;
}

// The provider component that wraps the dashboard
export function ManagerProvider({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const [manager, setManager] = useState<Manager | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [updateTrigger, setUpdateTrigger] = useState(0);

  const forceUpdate = useCallback(() => {
    setUpdateTrigger(c => c + 1);
  }, []);

  // Effect to find and set the logged-in manager
  useEffect(() => {
    const managerId = localStorage.getItem('loggedInManagerId');
    if (!managerId) {
      router.push('/');
      return;
    }

    const fetchManagerData = async () => {
      setIsLoading(true);
      try {
        const res = await fetch(`/api/managers/${managerId}`);
        if (res.status === 404) {
          localStorage.removeItem('loggedInManagerId');
          router.push('/');
          return;
        }
        if (!res.ok) {
          throw new Error("Failed to fetch manager data");
        }
        const data = await res.json();
        setManager(data);
      } catch (error) {
        console.error("Error fetching manager data:", error);
        localStorage.removeItem('loggedInManagerId');
        router.push('/');
      } finally {
        setIsLoading(false);
      }
    };
    
    fetchManagerData();
  }, [router, updateTrigger]);
  
  // Memoized context value
  const value = {
    manager,
    isLoading,
    forceUpdate,
  };

  return (
    <ManagerContext.Provider value={value}>
      {children}
    </ManagerContext.Provider>
  );
}
