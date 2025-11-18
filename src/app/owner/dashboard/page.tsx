
'use client';

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { User, PlusCircle, MoreVertical, Eye, Edit, Trash2, Droplet, Hammer } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogFooter,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { Manager, PipeStockItem } from "@/lib/types";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";


export default function OwnerDashboardPage() {
  const { toast } = useToast();
  const [managers, setManagers] = useState<Manager[]>([]);
  const [godownPipeStock, setGodownPipeStock] = useState<PipeStockItem[]>([]);
  
  const [newStock, setNewStock] = useState({ size: '', quantity: '' });
  const [isManagerDialogOpen, setIsManagerDialogOpen] = useState(false);
  const [managerToDelete, setManagerToDelete] = useState<Manager | null>(null);
  const [isMounted, setIsMounted] = useState(false);
  
  const [isGodownStockDialogOpen, setIsGodownStockDialogOpen] = useState(false);
  const [godownStockToEdit, setGodownStockToEdit] = useState<PipeStockItem | null>(null);
  const [editedGodownStockQuantity, setEditedGodownStockQuantity] = useState('');

  const [godownStockToDelete, setGodownStockToDelete] = useState<PipeStockItem | null>(null);
  
  const [managerForm, setManagerForm] = useState<{ id: string | null; name: string; email: string; password?: string }>({
    id: null,
    name: "",
    email: "",
    password: "",
  });

  const fetchManagers = async () => {
    try {
      const res = await fetch('/api/managers');
      if (!res.ok) throw new Error("Failed to fetch managers");
      const data = await res.json();
      setManagers(data);
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not fetch managers.' });
    }
  }

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
    fetchManagers();
    fetchGodownStock();
    setIsMounted(true);
  }, []);

  const calculatePipeStock = (pipeLogs: any[]) => {
    return (pipeLogs || []).reduce((acc, log) => {
        return log.type === 'Purchase' ? acc + log.quantity : acc - log.quantity;
    }, 0);
  }

  const resetManagerForm = () => {
    setManagerForm({ id: null, name: "", email: "", password: "" });
  };

  const handleAddManagerClick = () => {
    resetManagerForm();
    setIsManagerDialogOpen(true);
  };

  const handleEditManagerClick = (manager: Manager) => {
    setManagerForm({ id: manager.id, name: manager.name, email: manager.email, password: manager.password || '' });
    setIsManagerDialogOpen(true);
  };

  const handleDeleteManagerClick = (manager: Manager) => {
    setManagerToDelete(manager);
  };

  const confirmDeleteManager = async () => {
    if (managerToDelete) {
      try {
        const res = await fetch(`/api/managers/${managerToDelete.id}`, { method: 'DELETE' });
        if (!res.ok) throw new Error('Failed to delete manager');
        setManagers(managers.filter(m => m.id !== managerToDelete.id));
        toast({ title: "Success", description: "Manager has been deleted." });
      } catch (error) {
        toast({ variant: 'destructive', title: 'Error', description: 'Could not delete manager.' });
      } finally {
        setManagerToDelete(null);
      }
    }
  };

  const handleSaveManager = async () => {
    if (!managerForm.name || !managerForm.email || (managerForm.id === null && !managerForm.password)) {
      toast({ variant: "destructive", title: "Error", description: "Name, Email, and Password are required for new managers." });
      return;
    }
  
    const method = managerForm.id ? 'PUT' : 'POST';
    const url = managerForm.id ? `/api/managers/${managerForm.id}` : '/api/managers';
  
    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(managerForm),
      });
  
      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.error || 'Failed to save manager');
      }
  
      await fetchManagers(); // Refresh the list
      toast({ title: "Success", description: `Manager ${managerForm.id ? 'updated' : 'added'}.` });
      setIsManagerDialogOpen(false);
      resetManagerForm();
    } catch (error: any) {
      toast({ variant: "destructive", title: "Error", description: error.message });
    }
  };

  const handleAddGodownPipes = async () => {
    const size = parseFloat(newStock.size);
    const quantity = parseInt(newStock.quantity, 10);
    if (isNaN(size) || isNaN(quantity) || size <= 0 || quantity <= 0) {
      toast({ variant: 'destructive', title: 'Error', description: 'Please enter a valid size and quantity.' });
      return;
    }
    
    try {
      const res = await fetch('/api/godown-pipe-stock', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ size, quantity })
      });
      if(!res.ok) throw new Error("Failed to add stock");
      await fetchGodownStock();
      toast({ title: 'Success', description: `${quantity} pipes of size ${size}" added to godown stock.`});
      setNewStock({ size: '', quantity: '' });
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not add godown stock.' });
    }
  };
  
  const handleEditGodownClick = (item: PipeStockItem) => {
    setGodownStockToEdit(item);
    setEditedGodownStockQuantity(String(item.quantity));
    setIsGodownStockDialogOpen(true);
  };

  const handleSaveGodownStock = async () => {
    if (!godownStockToEdit) return;
    const quantity = parseInt(editedGodownStockQuantity, 10);
     if (isNaN(quantity) || quantity < 0) {
      toast({ variant: 'destructive', title: 'Error', description: 'Please enter a valid quantity.' });
      return;
    }

    try {
      const res = await fetch('/api/godown-pipe-stock', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: godownStockToEdit.id, quantity })
      });
      if (!res.ok) throw new Error("Failed to update stock");
      await fetchGodownStock();
      toast({ title: 'Success', description: 'Godown stock updated.' });
      setIsGodownStockDialogOpen(false);
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not update godown stock.' });
    }
  };

  const confirmDeleteGodownStock = async () => {
    if (!godownStockToDelete) return;
    try {
      const res = await fetch('/api/godown-pipe-stock', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: godownStockToDelete.id })
      });
      if (!res.ok) throw new Error("Failed to delete stock item");
      await fetchGodownStock();
      toast({ title: 'Success', description: 'Stock item deleted from godown.' });
      setGodownStockToDelete(null);
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete stock item.' });
    }
  };


  return (
    <>
      <div className="p-2 sm:p-4 space-y-4">
        <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
          <div>
            <h1 className="text-xl font-bold font-headline">Owner Dashboard</h1>
            <p className="text-muted-foreground text-xs">Manage your managers and view their operations.</p>
          </div>
          <Button onClick={handleAddManagerClick} size="sm" className="w-full sm:w-auto">
            <PlusCircle className="mr-2 h-4 w-4" /> Add Manager
          </Button>
        </div>

        <Card>
          <CardHeader className="p-3">
            <CardTitle className="font-headline text-base flex items-center gap-2"><Hammer /> Godown Pipe Stock</CardTitle>
            <CardDescription className="text-xs">Manage the central pipe inventory for all managers.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 p-3">
              {isMounted ? (
                godownPipeStock.length > 0 ? (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Pipe Size</TableHead>
                        <TableHead className="text-right">Quantity</TableHead>
                        <TableHead className="text-right w-[50px]">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {godownPipeStock.map(item => (
                        <TableRow key={item.id}>
                          <TableCell className="font-medium">{item.size}"</TableCell>
                          <TableCell className="text-right font-bold">{item.quantity.toLocaleString()}</TableCell>
                          <TableCell className="text-right">
                             <DropdownMenu>
                              <DropdownMenuTrigger asChild>
                                <Button variant="ghost" size="icon" className="h-7 w-7">
                                  <MoreVertical className="h-4 w-4" />
                                </Button>
                              </DropdownMenuTrigger>
                              <DropdownMenuContent align="end">
                                <DropdownMenuItem onClick={() => handleEditGodownClick(item)} className="flex items-center gap-2 cursor-pointer">
                                  <Edit className="h-4 w-4" /> Edit
                                </DropdownMenuItem>
                                <DropdownMenuItem onClick={() => setGodownStockToDelete(item)} className="text-destructive flex items-center gap-2 cursor-pointer">
                                  <Trash2 className="h-4 w-4" /> Delete
                                </DropdownMenuItem>
                              </DropdownMenuContent>
                            </DropdownMenu>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                ) : <p className="text-sm text-muted-foreground px-2">No pipes in godown stock.</p>
              ) : (
                <div className="space-y-2 px-2">
                  <Skeleton className="h-8 w-full" />
                  <Skeleton className="h-8 w-full" />
                </div>
              )}
            <div className="flex flex-col sm:flex-row items-end gap-2 pt-4 border-t mt-4">
              <div className="grid gap-1.5 w-full sm:flex-1">
                <Label htmlFor="pipe-size">Pipe Size (in)</Label>
                <Input id="pipe-size" type="number" value={newStock.size} onChange={e => setNewStock({...newStock, size: e.target.value})} />
              </div>
              <div className="grid gap-1.5 w-full sm:flex-1">
                <Label htmlFor="pipe-quantity">Quantity</Label>
                <Input id="pipe-quantity" type="number" value={newStock.quantity} onChange={e => setNewStock({...newStock, quantity: e.target.value})} />
              </div>
              <Button onClick={handleAddGodownPipes} size="sm" className="w-full sm:w-auto">Add Stock</Button>
            </div>
          </CardContent>
        </Card>

        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {isMounted ? (
            managers.map(manager => (
              <Card key={manager.id}>
                <CardHeader className="p-3">
                    <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                            <User className="w-8 h-8 p-1.5 rounded-sm bg-muted text-muted-foreground"/>
                            <div>
                              <h3 className="font-semibold text-sm">{manager.name}</h3>
                              <p className="text-xs text-muted-foreground">{manager.email}</p>
                            </div>
                        </div>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-7 w-7">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                           <DropdownMenuItem asChild>
                            <Link href={`/owner/manager/${manager.id}`} className="flex items-center gap-2 cursor-pointer w-full">
                              <Eye className="h-4 w-4" /> View Details
                            </Link>
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleEditManagerClick(manager)} className="flex items-center gap-2 cursor-pointer">
                            <Edit className="h-4 w-4" /> Edit
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => handleDeleteManagerClick(manager)} className="text-destructive flex items-center gap-2 cursor-pointer">
                            <Trash2 className="h-4 w-4" /> Delete
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                  </div>
                </CardHeader>
                <CardContent className="p-3 pt-0">
                    <div className="text-xs text-muted-foreground space-y-2">
                        <div className="flex items-center gap-2"><Droplet className="w-4 h-4 text-primary"/>Total Bores: {manager.data.bores.length}</div>
                        <div className="flex items-center gap-2"><Hammer className="w-4 h-4 text-primary"/>Pipe Stock: {calculatePipeStock(manager.data.pipeLogs)} units</div>
                    </div>
                </CardContent>
              </Card>
            ))
          ) : (
            [...Array(3)].map((_, i) => (
              <Card key={i}>
                <CardHeader className="p-3">
                    <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                            <User className="w-8 h-8 p-1.5 rounded-sm bg-muted text-muted-foreground"/>
                            <div>
                                <Skeleton className="h-5 w-24 mb-1" />
                                <Skeleton className="h-4 w-32" />
                            </div>
                        </div>
                        <Button variant="ghost" size="icon" className="h-7 w-7" disabled>
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                    </div>
                </CardHeader>
                <CardContent className="p-3 pt-0">
                  <div className="text-sm text-muted-foreground space-y-2">
                      <div className="flex items-center gap-2">
                          <Droplet className="w-4 h-4 text-primary"/>
                          <Skeleton className="h-4 w-20" />
                      </div>
                      <div className="flex items-center gap-2">
                          <Hammer className="w-4 h-4 text-primary"/>
                          <Skeleton className="h-4 w-20" />
                      </div>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </div>

      {/* Manager Add/Edit Dialog */}
      <Dialog open={isManagerDialogOpen} onOpenChange={setIsManagerDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>{managerForm.id ? 'Edit Manager' : 'Add New Manager'}</DialogTitle>
            <DialogDescription>
              {managerForm.id ? "Update the details for this manager." : "Enter the details for the new manager."}
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="name" className="text-right">Name</Label>
              <Input id="name" value={managerForm.name} onChange={e => setManagerForm({...managerForm, name: e.target.value})} className="col-span-3" />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="email" className="text-right">Login ID / Email</Label>
              <Input id="email" type="email" value={managerForm.email} onChange={e => setManagerForm({...managerForm, email: e.target.value})} className="col-span-3" />
            </div>
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="password" className="text-right">Password</Label>
              <Input id="password" type="password" value={managerForm.password || ''} onChange={e => setManagerForm({...managerForm, password: e.target.value})} className="col-span-3" placeholder={managerForm.id ? "Leave blank to keep unchanged" : ""}/>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsManagerDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSaveManager}>Save Manager</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
      
      {/* Manager Delete Alert */}
      <AlertDialog open={!!managerToDelete} onOpenChange={() => setManagerToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the manager
              and all of their associated data.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setManagerToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteManager} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Godown Stock Edit Dialog */}
      <Dialog open={isGodownStockDialogOpen} onOpenChange={setIsGodownStockDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>Edit Godown Stock</DialogTitle>
            <DialogDescription>
              Update the quantity for pipe size {godownStockToEdit?.size}".
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-4 items-center gap-4">
              <Label htmlFor="edit-quantity" className="text-right">Quantity</Label>
              <Input id="edit-quantity" type="number" value={editedGodownStockQuantity} onChange={e => setEditedGodownStockQuantity(e.target.value)} className="col-span-3" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsGodownStockDialogOpen(false)}>Cancel</Button>
            <Button onClick={handleSaveGodownStock}>Save Changes</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Godown Stock Delete Alert */}
      <AlertDialog open={!!godownStockToDelete} onOpenChange={() => setGodownStockToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the stock for pipe size {godownStockToDelete?.size}" from the godown.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setGodownStockToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteGodownStock} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
