
'use client';

import { useState, useEffect } from 'react';

// THIS HOOK IS NO LONGER IN USE AND IS A CANDIDATE FOR DELETION
// Data is now fetched from the database via API routes.

function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T | ((val: T) => T)) => void] {
  const [storedValue, setStoredValue] = useState<T>(initialValue);

  useEffect(() => {
    // This hook will now only return the initial value on the server and do nothing on the client,
    // effectively disabling it without breaking components that still use it.
  }, []);
  
  const setValue = (value: T | ((val: T) => T)) => {
    // Do nothing.
  };

  return [storedValue, setValue];
}

export default useLocalStorage;
