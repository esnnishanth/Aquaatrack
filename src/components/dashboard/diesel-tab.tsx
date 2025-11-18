
'use client';

import React, { useState, useMemo } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Fuel, PlusCircle, Trash2, History } from "lucide-react";
import { Textarea } from "../ui/textarea";
import type { DieselPurchase, DieselUsage } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { format } from 'date-fns';

interface DieselTabProps {
  role: 'owner' | 'manager';
  dieselPurchases: DieselPurchase[];
  dieselUsage: DieselUsage[];
  managerId: string;
  onDataUpdate: () => void;
}

export default function DieselTab({ role, dieselPurchases, dieselUsage, managerId, onDataUpdate }: DieselTabProps) {
  const { toast } = useToast();
  const [litersUsed, setLitersUsed] = useState('');
  const [purpose, setPurpose] = useState('');
  const [usageToDelete, setUsageToDelete] = useState<DieselUsage | null>(null);

  const dieselBalance = useMemo(() => {
    const totalPurchased = dieselPurchases.reduce((acc, p) => acc + p.liters, 0);
    const totalUsed = dieselUsage.reduce((acc, u) => acc + u.litersUsed, 0);
    return totalPurchased - totalUsed;
  }, [dieselPurchases, dieselUsage]);

  const handleLogUsage = async () => {
    if(!litersUsed || !purpose) {
      toast({ variant: 'destructive', title: 'Error', description: 'Please fill all fields to log usage.' });
      return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/diesel-usage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          litersUsed: parseFloat(litersUsed),
          purpose,
        })
      });
      if(!res.ok) throw new Error("Failed to log diesel usage");

      onDataUpdate();
      toast({ title: 'Success', description: 'Diesel usage logged successfully.' });

      setLitersUsed('');
      setPurpose('');
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not log diesel usage.' });
    }
  };

  const confirmDelete = async () => {
    if (!usageToDelete) return;
    try {
      const res = await fetch(`/api/managers/${managerId}/diesel-usage/${usageToDelete.id}`, {
        method: 'DELETE'
      });
      if(!res.ok) throw new Error("Failed to delete usage record");
      onDataUpdate();
      toast({ title: "Success", description: "Diesel usage record deleted." });
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete usage record.' });
    } finally {
      setUsageToDelete(null);
    }
  };

  return (
    <>
    <div className="grid lg:grid-cols-2 gap-6 items-start">
        <div className='space-y-6'>
            <Card>
                <CardHeader>
                    <CardTitle className="font-headline flex items-center gap-2"><Fuel/>Diesel Stock</CardTitle>
                    <CardDescription>
                    Current diesel availability and usage logging. Purchase more from the Expense tab.
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Card className="bg-secondary">
                        <CardContent className="p-4 flex items-center gap-3">
                            <Fuel className="w-8 h-8 text-muted-foreground" />
                            <div>
                                <p className="text-sm text-muted-foreground">Diesel in Stock</p>
                                <p className="text-3xl font-bold">{dieselBalance.toLocaleString('en-IN')} Liters</p>
                            </div>
                        </CardContent>
                    </Card>
                </CardContent>
            </Card>
            <Card>
                <CardHeader>
                    <CardTitle className="font-headline flex items-center gap-2"><PlusCircle/>Log Diesel Usage</CardTitle>
                    <CardDescription>
                    Record diesel consumed by vehicles or machinery. This will reduce the stock.
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="space-y-2">
                        <Label htmlFor="diesel-used">Diesel Used (Liters)</Label>
                        <Input id="diesel-used" type="number" placeholder="Liters" value={litersUsed} onChange={e => setLitersUsed(e.target.value)} />
                    </div>
                    <div className="space-y-2">
                        <Label htmlFor="usage-purpose">Purpose / Vehicle</Label>
                        <Textarea id="usage-purpose" placeholder="Purpose / Vehicle Details" value={purpose} onChange={e => setPurpose(e.target.value)} />
                    </div>
                </CardContent>
                <CardFooter>
                    <Button className="w-full" onClick={handleLogUsage}>Log Usage</Button>
                </CardFooter>
            </Card>
        </div>

        <Card>
            <CardHeader>
                <CardTitle className="font-headline flex items-center gap-2"><History />Diesel Usage History</CardTitle>
                <CardDescription>
                    A log of all recorded diesel usage.
                </CardDescription>
            </CardHeader>
            <CardContent>
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead>Date</TableHead>
                            <TableHead>Liters Used</TableHead>
                            <TableHead>Purpose</TableHead>
                            {role === 'owner' && <TableHead className="text-right">Actions</TableHead>}
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {dieselUsage.length > 0 ? (
                            dieselUsage.sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime()).map(usage => (
                                <TableRow key={usage.id}>
                                    <TableCell>{format(new Date(usage.date), 'dd/MM/yy')}</TableCell>
                                    <TableCell className="font-medium">{usage.litersUsed} L</TableCell>
                                    <TableCell>{usage.purpose}</TableCell>
                                    {role === 'owner' && (
                                        <TableCell className="text-right">
                                            <Button variant="ghost" size="icon" onClick={() => setUsageToDelete(usage)}>
                                                <Trash2 className="h-4 w-4 text-destructive" />
                                            </Button>
                                        </TableCell>
                                    )}
                                </TableRow>
                            ))
                        ) : (
                            <TableRow>
                                <TableCell colSpan={role === 'owner' ? 4 : 3} className="text-center h-24">
                                    No diesel usage recorded yet.
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </CardContent>
        </Card>
    </div>
    <AlertDialog open={!!usageToDelete} onOpenChange={() => setUsageToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete this diesel usage record.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setUsageToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
