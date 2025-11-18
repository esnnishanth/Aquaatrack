
'use client';

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarHeader,
  SidebarInset,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { Bell, Droplets, Home, LogOut, Settings, Loader } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Skeleton } from "@/components/ui/skeleton";
import { ManagerProvider, useManager } from "@/contexts/manager-context";

// This component contains the UI that depends on the manager context
function DashboardUI({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const { manager, isLoading } = useManager();

  const handleLogout = () => {
    localStorage.removeItem('loggedInManagerId');
    router.push('/');
  }
  
  return (
    <SidebarProvider>
      <div className="flex min-h-screen">
        <Sidebar className="border-r">
          <SidebarHeader>
            <div className="flex items-center gap-2">
              <div className="bg-primary/10 p-2 rounded-lg border border-primary/20">
                <Droplets className="w-6 h-6 text-primary" />
              </div>
              <h1 className="text-xl font-headline font-semibold">AquaTrack</h1>
            </div>
          </SidebarHeader>
          <SidebarContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton asChild isActive>
                  <Link href="/dashboard">
                    <Home />
                    Dashboard
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton asChild>
                  <Link href="#">
                    <Settings />
                    Settings
                  </Link>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarContent>
          <SidebarFooter>
            {manager ? (
                <div className="flex items-center gap-3 p-2 rounded-lg bg-muted">
                <Avatar>
                    <AvatarImage src="https://placehold.co/40x40.png" alt={manager.name} data-ai-hint="person avatar"/>
                    <AvatarFallback>{manager.name.charAt(0)}</AvatarFallback>
                </Avatar>
                <div className="flex-1">
                    <p className="text-sm font-semibold">{manager.name}</p>
                    <p className="text-xs text-muted-foreground">{manager.email}</p>
                </div>
                <Button variant="ghost" size="icon" onClick={handleLogout}>
                    <LogOut className="w-4 h-4" />
                </Button>
                </div>
            ) : (
                <div className="flex items-center gap-3 p-2 rounded-lg bg-muted">
                    <Skeleton className="h-10 w-10 rounded-full" />
                    <div className="flex-1 space-y-2">
                        <Skeleton className="h-4 w-20" />
                        <Skeleton className="h-3 w-32" />
                    </div>
                </div>
            )}
          </SidebarFooter>
        </Sidebar>

        <SidebarInset>
          <header className="flex items-center justify-between p-2 border-b">
            <SidebarTrigger />
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon">
                <Bell className="h-5 w-5" />
                <span className="sr-only">Notifications</span>
              </Button>
            </div>
          </header>
          <main className="flex-1 overflow-auto bg-background">
            {isLoading ? (
                <div className="flex items-center justify-center h-full">
                    <Loader className="h-8 w-8 animate-spin text-primary" />
                </div>
            ) : children}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
}

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ManagerProvider>
      <DashboardUI>
        {children}
      </DashboardUI>
    </ManagerProvider>
  );
}
