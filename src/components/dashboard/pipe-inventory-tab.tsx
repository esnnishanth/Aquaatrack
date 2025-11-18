
'use client';

import { useMemo, useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter
} from "@/components/ui/card";
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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { History, Trash2, MoreVertical, Edit } from "lucide-react";
import { format } from "date-fns";
import type { PipeLog, PipeStockItem } from '@/lib/types';
import { useToast } from '@/hooks/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

interface PipeInventoryTabProps {
    role: 'owner' | 'manager';
    pipeLogs: PipeLog[];
    managerId: string;
    onDataUpdate: () => void;
}

export default function PipeInventoryTab({ role, pipeLogs, managerId, onDataUpdate }: PipeInventoryTabProps) {
  const [isMounted, setIsMounted] = useState(false);
  const { toast } = useToast();
  const [logToDelete, setLogToDelete] = useState<PipeLog | null>(null);
  const [godownPipeStock, setGodownPipeStock] = useState<PipeStockItem[]>([]);
  const [withdrawalForm, setWithdrawalForm] = useState({ size: '', quantity: '' });
  
  const [isAdjustDialogOpen, setIsAdjustDialogOpen] = useState(false);
  const [stockToAdjust, setStockToAdjust] = useState<PipeStockItem | null>(null);
  const [newQuantity, setNewQuantity] = useState('');

  const [stockItemToDelete, setStockItemToDelete] = useState<PipeStockItem | null>(null);

  const fetchGodownStock = async () => {
    try {
      const res = await fetch('/api/godown-pipe-stock');
      if (!res.ok) throw new Error("Failed to fetch godown stock");
      const data = await res.json();
      setGodownPipeStock(data);
    } catch (error) {
       toast({ variant: 'destructive', title: 'Error', description: 'Could not fetch godown pipe stock.' });
    }
  }

  useEffect(() => {
    setIsMounted(true);
    fetchGodownStock();
  }, []);
  
  const pipeBalance = useMemo(() => {
    const validLogs = Array.isArray(pipeLogs) ? pipeLogs : [];
    const balanceMap = new Map<number, number>();

    validLogs.forEach(log => {
      if (typeof log.diameter === 'number' && !isNaN(log.diameter)) {
        const currentQuantity = balanceMap.get(log.diameter) || 0;
        if (log.type === 'Purchase') {
            balanceMap.set(log.diameter, currentQuantity + log.quantity);
        } else {
            balanceMap.set(log.diameter, currentQuantity - log.quantity);
        }
      }
    });

    return Array.from(balanceMap.entries())
        .map(([size, quantity]) => ({ size, quantity }))
        .sort((a, b) => a.size - b.size);
  }, [pipeLogs]);

  const handleWithdrawPipes = async () => {
    const size = parseFloat(withdrawalForm.size);
    const quantity = parseInt(withdrawalForm.quantity, 10);

    if (isNaN(size) || isNaN(quantity) || quantity <= 0) {
      toast({ variant: 'destructive', title: 'Error', description: 'Please select a size and enter a valid quantity.' });
      return;
    }
    
    try {
      const res = await fetch(`/api/managers/${managerId}/pipe-logs/withdraw`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ size, quantity })
      });
      if(!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.error || "Failed to withdraw pipes");
      }
      onDataUpdate();
      fetchGodownStock();
      toast({ title: 'Success', description: `${quantity} pipes of size ${size}" withdrawn successfully.` });
      setWithdrawalForm({ size: '', quantity: '' });
    } catch (error: any) {
      toast({ variant: 'destructive', title: 'Error', description: error.message });
    }
  };

  const confirmDeleteLog = async () => {
    if (!logToDelete) return;
    
    try {
      const res = await fetch(`/api/managers/${managerId}/pipe-logs/${logToDelete.id}`, {
        method: 'DELETE'
      });
      if(!res.ok) throw new Error("Failed to delete log");
      onDataUpdate();
      fetchGodownStock();
      toast({ title: "Success", description: "Pipe log deleted and stock refunded." });
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete pipe log.' });
    } finally {
      setLogToDelete(null);
    }
  }
  
  const handleAdjustClick = (item: PipeStockItem) => {
    setStockToAdjust(item);
    setNewQuantity(String(item.quantity));
    setIsAdjustDialogOpen(true);
  };
  
  const handleSaveStockAdjustment = async () => {
    if (!stockToAdjust) return;
    const newQty = parseInt(newQuantity, 10);
    if (isNaN(newQty) || newQty < 0) {
        toast({ variant: 'destructive', title: 'Error', description: 'Please enter a valid quantity.' });
        return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/pipe-stock/adjust`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ size: stockToAdjust.size, newQuantity: newQty })
      });
      if(!res.ok) throw new Error("Failed to adjust stock");
      onDataUpdate();
      toast({ title: 'Success', description: 'Stock has been adjusted.' });
      setIsAdjustDialogOpen(false);
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not adjust stock.' });
    }
  };
  
  const confirmDeleteStockItem = async () => {
    if (!stockItemToDelete) return;
    
    try {
      const res = await fetch(`/api/managers/${managerId}/pipe-stock/delete`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ size: stockItemToDelete.size })
      });
      if(!res.ok) throw new Error("Failed to delete stock item.");
      onDataUpdate();
      toast({ title: 'Success', description: 'Stock item removed and logged.' });
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete stock item.' });
    } finally {
      setStockItemToDelete(null);
    }
  };


  const validGodownStock = useMemo(() => Array.isArray(godownPipeStock) ? godownPipeStock.filter(item => typeof item.size === 'number' && !isNaN(item.size)) : [], [godownPipeStock]);
  const validPipeBalance = useMemo(() => Array.isArray(pipeBalance) ? pipeBalance.filter(item => typeof item.size === 'number' && !isNaN(item.size) && item.quantity > 0) : [], [pipeBalance]);

  return (
    <>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 items-start">
        <Card>
            <CardHeader className="p-3">
                <CardTitle className="text-base">Central Godown Stock</CardTitle>
                <CardDescription className="text-xs">Total pipes available for all managers.</CardDescription>
            </CardHeader>
            <CardContent className="p-3 pt-0">
                {isMounted ? (
                    validGodownStock.length > 0 ? (
                    <Table>
                        <TableHeader>
                        <TableRow>
                            <TableHead>Size</TableHead>
                            <TableHead className="text-right">Quantity</TableHead>
                        </TableRow>
                        </TableHeader>
                        <TableBody>
                        {validGodownStock.map(item => (
                            <TableRow key={item.size}>
                            <TableCell>{item.size}"</TableCell>
                            <TableCell className="text-right font-medium">{item.quantity.toLocaleString()}</TableCell>
                            </TableRow>
                        ))}
                        </TableBody>
                    </Table>
                    ) : <p className="text-sm text-muted-foreground p-2">No pipes in godown stock.</p>
                ) : <Skeleton className="h-24 w-full" />}
            </CardContent>
        </Card>

        <Card>
            <CardHeader className="p-3">
                <CardTitle className="text-base">Pipe Stock</CardTitle>
                <CardDescription className="text-xs">Pipes currently held by {role === 'manager' ? 'you' : 'this manager'}.</CardDescription>
            </CardHeader>
            <CardContent className="p-3 pt-0">
                {isMounted ? (
                    validPipeBalance.length > 0 ? (
                        <Table>
                        <TableHeader>
                            <TableRow>
                            <TableHead>Size</TableHead>
                            <TableHead className="text-right">Quantity</TableHead>
                            <TableHead className="text-right w-[50px]">Actions</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {validPipeBalance.map(item => (
                            <TableRow key={item.size}>
                                <TableCell>{item.size}"</TableCell>
                                <TableCell className="text-right font-medium">{item.quantity.toLocaleString()}</TableCell>
                                <TableCell className="text-right">
                                    <DropdownMenu>
                                    <DropdownMenuTrigger asChild>
                                    <Button variant="ghost" size="icon" className="h-7 w-7">
                                        <MoreVertical className="h-4 w-4" />
                                    </Button>
                                    </DropdownMenuTrigger>
                                    <DropdownMenuContent align="end">
                                    <DropdownMenuItem onClick={() => handleAdjustClick(item)} className="flex items-center gap-2 cursor-pointer">
                                        <Edit className="h-4 w-4" /> Adjust
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => setStockItemToDelete(item)} className="text-destructive flex items-center gap-2 cursor-pointer">
                                        <Trash2 className="h-4 w-4" /> Delete
                                    </DropdownMenuItem>
                                    </DropdownMenuContent>
                                </DropdownMenu>
                                </TableCell>
                            </TableRow>
                            ))}
                        </TableBody>
                        </Table>
                    ) : <p className="text-sm text-muted-foreground p-2">No pipes in stock.</p>
                ) : <Skeleton className="h-24 w-full" />}
            </CardContent>
            <CardFooter className="flex-col items-start gap-2 border-t p-3">
                <h4 className="font-medium text-sm">Withdraw from Godown</h4>
                <div className="w-full flex flex-col sm:flex-row items-end gap-2">
                    <div className="flex-1 space-y-1.5 w-full">
                    <Label className="text-xs">Pipe Size</Label>
                    <Select value={withdrawalForm.size} onValueChange={value => setWithdrawalForm({...withdrawalForm, size: value})}>
                        <SelectTrigger>
                        <SelectValue placeholder="Select a pipe size" />
                        </SelectTrigger>
                        <SelectContent>
                        {validGodownStock.map(item => (
                            <SelectItem key={item.size} value={String(item.size)}>{item.size}" (Available: {item.quantity})</SelectItem>
                        ))}
                        </SelectContent>
                    </Select>
                    </div>
                    <div className="flex-1 space-y-1.5 w-full">
                    <Label htmlFor='withdraw-quantity' className="text-xs">Quantity</Label>
                    <Input id='withdraw-quantity' type="number" value={withdrawalForm.quantity} onChange={e => setWithdrawalForm({...withdrawalForm, quantity: e.target.value})} />
                    </div>
                    <Button size="sm" onClick={handleWithdrawPipes} disabled={!withdrawalForm.size || !withdrawalForm.quantity} className="w-full sm:w-auto">Withdraw</Button>
                </div>
            </CardFooter>
        </Card>
        
        <div className='lg:col-span-2'>
            <Card>
                <CardHeader className="p-3">
                    <CardTitle className="font-headline text-base flex items-center gap-2"><History/> Pipe Log</CardTitle>
                    <CardDescription className="text-xs">
                        Withdrawals and usage for this manager.
                    </CardDescription>
                </CardHeader>
                <CardContent className="p-0">
                    <Table>
                        <TableHeader>
                        <TableRow>
                            <TableHead>Date</TableHead>
                            <TableHead>Type</TableHead>
                            <TableHead>Qty</TableHead>
                            <TableHead>Info</TableHead>
                            <TableHead className="text-right w-[50px]">Actions</TableHead>
                        </TableRow>
                        </TableHeader>
                        <TableBody>
                        {isMounted ? (
                            (pipeLogs || []).length > 0 ? (
                                (pipeLogs || []).sort((a,b) => new Date(b.date).getTime() - new Date(a.date).getTime()).map((log) => (
                                    <TableRow key={log.id}>
                                    <TableCell>{format(new Date(log.date), 'dd/MM/yy')}</TableCell>
                                    <TableCell>
                                        <Badge variant={log.type === 'Purchase' ? 'success' : (log.relatedBore === 'Stock Adjustment' || log.relatedBore === 'Stock Deletion' ? 'warning' : 'destructive') }>
                                            {log.type === 'Purchase' ? 'In' : 'Out'}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="font-medium">{log.quantity}x{log.diameter}"</TableCell>
                                    <TableCell className="truncate max-w-[80px]">{log.relatedBore || 'N/A'}</TableCell>
                                    <TableCell className="text-right">
                                        {log.type === 'Purchase' && (
                                        <Button variant="ghost" size="icon" onClick={() => setLogToDelete(log)} className="h-7 w-7">
                                            <Trash2 className="h-4 w-4 text-destructive" />
                                        </Button>
                                        )}
                                    </TableCell>
                                    </TableRow>
                                ))
                            ) : (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center h-24">No pipe logs found.</TableCell>
                                </TableRow>
                            )
                        ) : (
                            <>
                                {[...Array(5)].map((_, i) => (
                                    <TableRow key={i}>
                                        <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                                        <TableCell><Skeleton className="h-6 w-12 rounded-full" /></TableCell>
                                        <TableCell><Skeleton className="h-4 w-12" /></TableCell>
                                        <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                                        <TableCell className="text-right"><Skeleton className="h-7 w-7" /></TableCell>
                                    </TableRow>
                                ))}
                            </>
                        )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
      </div>
      
      {/* Log Deletion Alert */}
      <AlertDialog open={!!logToDelete} onOpenChange={() => setLogToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete this pipe log record. If this is a withdrawal record, the pipes will be returned to the godown stock.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setLogToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteLog} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Stock Adjustment Dialog */}
      <Dialog open={isAdjustDialogOpen} onOpenChange={setIsAdjustDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Adjust Stock</DialogTitle>
            <DialogDescription>
              Adjust the quantity for pipe size {stockToAdjust?.size}". This action will be logged.
              You can only decrease the quantity here.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="new-quantity" className="text-right">New Quantity</Label>
              <Input id="new-quantity" type="number" value={newQuantity} onChange={e => setNewQuantity(e.target.value)} className="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsAdjustDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSaveStockAdjustment}>Save Adjustment</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Stock Item Deletion Alert */}
      <AlertDialog open={!!stockItemToDelete} onOpenChange={() => setStockItemToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove all stock for pipe size {stockItemToDelete?.size}" from this manager's inventory and create a "Stock Deletion" log entry. This action cannot be undone.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setStockItemToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteStockItem} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
