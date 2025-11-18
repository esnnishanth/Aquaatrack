
'use client';

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { useToast } from "@/hooks/use-toast";
import { Droplets, User, Lock } from "lucide-react";
import { useRouter } from "next/navigation";
import { FormEvent, useState, useEffect } from "react";
import type { Manager } from "@/lib/types";


export default function LoginPage() {
  const router = useRouter();
  const { toast } = useToast();
  const [role, setRole] = useState('manager');
  const [loginId, setLoginId] = useState('');
  const [password, setPassword] = useState('');
  const [managers, setManagers] = useState<Manager[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchManagers = async () => {
      try {
        setIsLoading(true);
        const response = await fetch('/api/managers');
        if (!response.ok) {
          throw new Error('Failed to fetch managers for login validation');
        }
        const data = await response.json();
        setManagers(data);
      } catch (error) {
        console.error(error);
        toast({
          variant: "destructive",
          title: "Error",
          description: "Could not load manager data. Please try again later.",
        });
      } finally {
        setIsLoading(false);
      }
    };
    fetchManagers();
  }, [toast]);

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (role === 'owner') {
      if (loginId === 'owner@aquatrack.co' && password === '12345678') {
        router.push('/owner/dashboard');
      } else {
        toast({
          variant: "destructive",
          title: "Login Failed",
          description: "Invalid Owner credentials.",
        });
      }
    } else {
      const manager = managers.find(m => m.email.toLowerCase() === loginId.toLowerCase());
      if (manager && manager.password === password) {
        localStorage.setItem('loggedInManagerId', manager.id);
        router.push('/dashboard');
      } else {
        toast({
          variant: "destructive",
          title: "Login Failed",
          description: "Invalid Manager Login ID or Password.",
        });
      }
    }
  };

  return (
    <main className="flex min-h-screen flex-col lg:flex-row">
      <div className="hidden lg:flex lg:w-1/2 relative bg-cover bg-center" style={{ backgroundImage: "url('https://placehold.co/1000x1200.png')" }} data-ai-hint="water droplet">
        <div className="absolute inset-0 bg-primary/80" />
        <div className="relative z-10 flex flex-col items-center justify-center p-12 text-center text-white">
            <div className="mx-auto bg-white/10 p-4 rounded-full w-fit mb-6 border-4 border-white/20">
            <Droplets className="h-12 w-12 text-white" />
            </div>
            <h1 className="font-headline text-4xl font-bold">AquaTrack</h1>
            <p className="mt-2 text-lg text-white/80">
            The all-in-one solution for managing your borewell business with precision and ease.
            </p>
        </div>
      </div>
      <div className="flex flex-1 items-center justify-center p-6 bg-background">
        <div className="w-full max-w-sm space-y-6">
            <div className="text-center lg:hidden">
                 <div className="mx-auto bg-primary/10 p-3 rounded-full w-fit mb-4 border-4 border-primary/20">
                    <Droplets className="h-8 w-8 text-primary" />
                </div>
            </div>
            <div className="text-center">
                <h1 className="text-3xl font-bold font-headline">Welcome Back</h1>
                <p className="text-muted-foreground">Select your role and enter your credentials.</p>
            </div>
            <form className="space-y-4" onSubmit={handleSubmit}>
                <div className="space-y-3">
                    <Label>Role</Label>
                    <RadioGroup defaultValue="manager" value={role} onValueChange={setRole} className="grid grid-cols-2 gap-4">
                        <Label htmlFor="manager" className="flex flex-col items-center justify-between rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer">
                            <RadioGroupItem value="manager" id="manager" className="sr-only" />
                            <User className="mb-3 h-6 w-6" />
                            Manager
                        </Label>
                        <Label htmlFor="owner" className="flex flex-col items-center justify-between rounded-md border-2 border-muted bg-popover p-4 hover:bg-accent hover:text-accent-foreground peer-data-[state=checked]:border-primary [&:has([data-state=checked])]:border-primary cursor-pointer">
                            <RadioGroupItem value="owner" id="owner" className="sr-only" />
                            <Droplets className="mb-3 h-6 w-6" />
                            Owner
                        </Label>
                    </RadioGroup>
                </div>
                <div className="space-y-2">
                    <Label htmlFor="loginId">Login ID</Label>
                    <div className="relative">
                        <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input id="loginId" placeholder="e.g. manager@email.com" className="pl-9" value={loginId} onChange={e => setLoginId(e.target.value)} />
                    </div>
                </div>
                <div className="space-y-2">
                    <Label htmlFor="password">Password</Label>
                    <div className="relative">
                        <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input id="password" type="password" placeholder="••••••••" className="pl-9" value={password} onChange={e => setPassword(e.target.value)} />
                    </div>
                </div>
                <Button type="submit" className="w-full font-bold" size="lg" disabled={isLoading}>
                    {isLoading ? 'Loading...' : 'Login'}
                </Button>
            </form>
        </div>
      </div>
    </main>
  );
}
