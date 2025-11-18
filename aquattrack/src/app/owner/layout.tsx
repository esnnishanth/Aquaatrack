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
import { Bell, Droplets, Home, LogOut, Settings } from "lucide-react";
import Link from "next/link";

export default function OwnerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SidebarProvider>
      <div className="flex min-h-screen">
        <Sidebar className="border-r">
          <SidebarHeader>
            <div className="flex items-center gap-2">
              <div className="bg-primary/10 p-2 rounded-lg border border-primary/20">
                <Droplets className="w-6 h-6 text-primary" />
              </div>
              <h1 className="text-xl font-headline font-semibold">AquaTrack Owner</h1>
            </div>
          </SidebarHeader>
          <SidebarContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton asChild isActive>
                  <Link href="/owner/dashboard">
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
            <div className="flex items-center gap-3 p-2 rounded-lg bg-muted">
              <Avatar>
                <AvatarImage src="https://placehold.co/40x40.png" alt="Owner" data-ai-hint="person avatar"/>
                <AvatarFallback>O</AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <p className="text-sm font-semibold">Owner</p>
                <p className="text-xs text-muted-foreground">owner@aquatrack.co</p>
              </div>
              <Button variant="ghost" size="icon" asChild>
                <a href="/">
                  <LogOut className="w-4 h-4" />
                </a>
              </Button>
            </div>
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
            {children}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
}
