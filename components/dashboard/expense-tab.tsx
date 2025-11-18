
'use client';

import React, { useState, useMemo } from 'react';
import { format } from "date-fns";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import type { Worker, NormalExpense, LabourPayment } from "@/lib/types";
import { useToast } from '@/hooks/use-toast';
import { cn } from '@/lib/utils';
import { History, Trash2, CalendarIcon } from 'lucide-react';
import { Badge } from '../ui/badge';

interface ExpenseTabProps {
  role: 'owner' | 'manager';
  workers: Worker[];
  normalExpenses: NormalExpense[];
  labourPayments: LabourPayment[];
  managerId: string;
  onDataUpdate: () => void;
}


export default function ExpenseTab(props : ExpenseTabProps) {
  const { role, workers, normalExpenses, labourPayments, managerId, onDataUpdate } = props;
  const { toast } = useToast();

  // State for Normal Expense
  const [normalDesc, setNormalDesc] = useState('');
  const [normalPrice, setNormalPrice] = useState('');
  const [expenseToDelete, setExpenseToDelete] = useState<(NormalExpense & {type: string}) | null>(null);

  // State for Labour Payment
  const [selectedWorker, setSelectedWorker] = useState('');
  const [labourAmount, setLabourAmount] = useState('');
  
  // State for Pipe Purchase
  const [pipeCost, setPipeCost] = useState('');
  const [pipePurchaseDate, setPipePurchaseDate] = useState<Date | undefined>(new Date());

  // State for Diesel Purchase
  const [dieselLiters, setDieselLiters] = useState('');
  const [dieselCost, setDieselCost] = useState('');

  const allExpensesForHistory = useMemo(() => {
    const combined = [
      ...normalExpenses.map(e => ({
        ...e,
        type: 'Normal',
        category: e.description.includes('Purchase') ? 'Asset' : 'Normal',
      })),
      ...(labourPayments && workers
        ? labourPayments.map(p => {
            const worker = workers.find(w => w.id === p.workerId);
            return {
              id: p.id,
              date: p.date,
              description: `Payment to ${
                worker ? worker.name : 'Unknown Worker'
              }`,
              amount: p.amount,
              type: 'Labour',
              category: 'Labour',
            };
          })
        : []),
    ];
    return combined.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    );
  }, [normalExpenses, labourPayments, workers, role]);

  const calculateSalaryBalance = (worker: Worker) => {
    return worker.monthlySalary * worker.monthsWorked - worker.amountPaid;
  };

  const handleSaveNormalExpense = async () => {
    if (!normalDesc || !normalPrice) {
      toast({ variant: 'destructive', title: 'Error', description: 'Please fill all fields for normal expense.' });
      return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/expenses/normal`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          description: normalDesc,
          amount: parseFloat(normalPrice),
          date: new Date(),
        })
      });
      if (!res.ok) throw new Error('Failed to save expense');
      onDataUpdate();
      toast({ title: 'Success', description: 'Normal expense saved.' });
      setNormalDesc('');
      setNormalPrice('');
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not save expense.' });
    }
  };

  const handleRecordLabourPayment = async () => {
    if(!selectedWorker || !labourAmount) {
        toast({ variant: 'destructive', title: 'Error', description: 'Please select a worker and enter an amount.' });
        return;
    }
    try {
        const res = await fetch(`/api/managers/${managerId}/expenses/labour`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                workerId: selectedWorker,
                amount: parseFloat(labourAmount),
                date: new Date(),
            })
        });
        if (!res.ok) throw new Error('Failed to record labour payment');

        onDataUpdate();
        toast({ title: 'Success', description: 'Labour payment recorded and added to expenses.' });
        setSelectedWorker('');
        setLabourAmount('');
    } catch (error) {
        toast({ variant: 'destructive', title: 'Error', description: 'Could not record labour payment.' });
    }
  };
  
  const handleAddPipePurchase = async () => {
    if(!pipeCost || !pipePurchaseDate) {
        toast({ variant: 'destructive', title: 'Error', description: 'Please provide a cost and date.' });
        return;
    }
    try {
        const res = await fetch(`/api/managers/${managerId}/expenses/normal`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                description: `Pipe Purchase`,
                amount: parseFloat(pipeCost),
                date: pipePurchaseDate,
            })
        });
        if (!res.ok) throw new Error('Failed to record pipe purchase expense');
        onDataUpdate();
        toast({ title: 'Success', description: 'Pipe purchase expense recorded.' });
        setPipeCost('');
        setPipePurchaseDate(new Date());
    } catch (error) {
        toast({ variant: 'destructive', title: 'Error', description: 'Could not record pipe purchase expense.' });
    }
  };
  
  const handleAddDieselPurchase = async () => {
    if(!dieselLiters || !dieselCost) {
        toast({ variant: 'destructive', title: 'Error', description: 'Please fill all fields for diesel purchase.' });
        return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/expenses/diesel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          liters: parseFloat(dieselLiters),
          cost: parseFloat(dieselCost),
          date: new Date(),
        })
      });
      if(!res.ok) throw new Error("Failed to add diesel purchase");

      onDataUpdate();
      toast({ title: 'Success', description: 'Diesel purchase added to stock and expenses.' });
      setDieselLiters('');
      setDieselCost('');
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not add diesel purchase.' });
    }
  };

  const confirmDeleteExpense = async () => {
    if (!expenseToDelete) return;

    let url;
    if (expenseToDelete.type === 'Labour') {
        url = `/api/managers/${managerId}/expenses/labour/${expenseToDelete.id}`;
    } else {
        url = `/api/managers/${managerId}/expenses/normal/${expenseToDelete.id}`;
    }

    try {
        const res = await fetch(url, { method: 'DELETE' });
        if (!res.ok) throw new Error(`Failed to delete ${expenseToDelete.type.toLowerCase()} expense`);
        onDataUpdate();
        toast({ title: 'Success', description: 'Expense record deleted.' });
    } catch (error) {
        toast({ variant: 'destructive', title: 'Error', description: 'Could not delete expense record.' });
    } finally {
        setExpenseToDelete(null);
    }
  };

  const canDeleteExpense = (expense: NormalExpense & {type: string}) => {
    if (role === 'manager' && expense.type === 'Labour') return false;
    if (role === 'manager' && expense.description.startsWith('Diesel Purchase')) return false;
    return true;
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="font-headline">Expense Management</CardTitle>
          <CardDescription>
            Log all business-related expenses in their respective categories.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="normal" className="w-full">
            <TabsList className={cn("grid w-full h-auto", "grid-cols-2 md:grid-cols-4")}>
              <TabsTrigger value="normal">Normal</TabsTrigger>
              <TabsTrigger value="labour">Labour</TabsTrigger>
              <TabsTrigger value="pipe">Pipe Purchase</TabsTrigger>
              <TabsTrigger value="diesel">Diesel Purchase</TabsTrigger>
            </TabsList>
            
            <TabsContent value="normal" className="mt-4">
              <Card className="border-none shadow-none">
                <CardHeader>
                  <CardTitle>Normal Expense</CardTitle>
                  <CardDescription>Log general expenses like repairs, supplies, etc.</CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="exp-desc">Expense Description</Label>
                    <Textarea id="exp-desc" placeholder="Description" value={normalDesc} onChange={e => setNormalDesc(e.target.value)} />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="exp-price">Price (₹)</Label>
                    <Input id="exp-price" type="number" placeholder="Price (₹)" value={normalPrice} onChange={e => setNormalPrice(e.target.value)} />
                  </div>
                </CardContent>
                <CardFooter>
                  <Button onClick={handleSaveNormalExpense}>Save Expense</Button>
                </CardFooter>
              </Card>
            </TabsContent>

            {workers && (
              <TabsContent value="labour" className="mt-4">
                <Card className="border-none shadow-none">
                    <CardHeader>
                        <CardTitle>Labour Payment</CardTitle>
                        <CardDescription>Record salary payments to workers. This will reduce their salary balance and be recorded as an expense.</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="space-y-2">
                            <Label htmlFor="worker-select">Select Worker</Label>
                            <Select value={selectedWorker} onValueChange={setSelectedWorker}>
                                <SelectTrigger id="worker-select">
                                    <SelectValue placeholder="Select a worker to pay" />
                                </SelectTrigger>
                                <SelectContent>
                                    {workers.map((worker) => (
                                    <SelectItem key={worker.id} value={worker.id}>
                                        {worker.name} (Balance: ₹{calculateSalaryBalance(worker).toLocaleString('en-IN')})
                                    </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                        </div>
                        <div className="space-y-2">
                            <Label htmlFor="labour-amount">Amount Given (₹)</Label>
                            <Input id="labour-amount" type="number" placeholder="Amount" value={labourAmount} onChange={e => setLabourAmount(e.target.value)} />
                        </div>
                    </CardContent>
                    <CardFooter>
                        <Button onClick={handleRecordLabourPayment}>Record Payment</Button>
                    </CardFooter>
                </Card>
              </TabsContent>
            )}

            <TabsContent value="pipe" className="mt-4">
              <Card className="border-none shadow-none">
                  <CardHeader>
                      <CardTitle>Pipe Purchase</CardTitle>
                      <CardDescription>Log pipe purchase expenses. This will NOT update inventory.</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                      <div className="space-y-2">
                          <Label htmlFor="pipe-purchase-date">Paid Date</Label>
                          <Popover>
                              <PopoverTrigger asChild>
                              <Button
                                  variant={"outline"}
                                  className={cn(
                                  "w-full justify-start text-left font-normal",
                                  !pipePurchaseDate && "text-muted-foreground"
                                  )}
                              >
                                  <CalendarIcon className="mr-2 h-4 w-4" />
                                  {pipePurchaseDate ? format(pipePurchaseDate, "PPP") : <span>Pick a date</span>}
                              </Button>
                              </PopoverTrigger>
                              <PopoverContent className="w-auto p-0">
                              <Calendar
                                  mode="single"
                                  selected={pipePurchaseDate}
                                  onSelect={setPipePurchaseDate}
                                  initialFocus
                              />
                              </PopoverContent>
                          </Popover>
                      </div>
                      <div className="space-y-2">
                          <Label htmlFor="pipe-cost">Total Cost (₹)</Label>
                          <Input id="pipe-cost" type="number" placeholder="Cost (₹)" value={pipeCost} onChange={e => setPipeCost(e.target.value)} />
                      </div>
                  </CardContent>
                  <CardFooter>
                      <Button onClick={handleAddPipePurchase}>Record Expense</Button>
                  </CardFooter>
              </Card>
            </TabsContent>

            <TabsContent value="diesel" className="mt-4">
              <Card className="border-none shadow-none">
                  <CardHeader>
                      <CardTitle>Diesel Purchase</CardTitle>
                      <CardDescription>Log diesel fuel purchases. This will update the diesel stock and be recorded as an expense.</CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-4">
                      <div className="space-y-2">
                          <Label htmlFor="diesel-liters">Liters Purchased</Label>
                          <Input id="diesel-liters" type="number" placeholder="Liters" value={dieselLiters} onChange={e => setDieselLiters(e.target.value)} />
                      </div>
                      <div className="space-y-2">
                          <Label htmlFor="diesel-cost">Total Cost (₹)</Label>
                          <Input id="diesel-cost" type="number" placeholder="Cost (₹)" value={dieselCost} onChange={e => setDieselCost(e.target.value)}/>
                      </div>
                  </CardContent>
                  <CardFooter>
                      <Button onClick={handleAddDieselPurchase}>Add to Stock & Expense</Button>
                  </CardFooter>
              </Card>
            </TabsContent>

          </Tabs>
        </CardContent>
      </Card>
      
      <Card>
        <CardHeader>
            <CardTitle className="font-headline flex items-center gap-2"><History />Expense History</CardTitle>
            <CardDescription>
                A log of all normal, pipe, diesel, and labour expenses.
            </CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Description</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {allExpensesForHistory.length > 0 ? (
                allExpensesForHistory.map(exp => (
                  <TableRow key={exp.id}>
                    <TableCell>{format(new Date(exp.date), 'dd/MM/yy')}</TableCell>
                    <TableCell><Badge variant={exp.category === 'Labour' ? 'warning' : 'secondary'}>{exp.category}</Badge></TableCell>
                    <TableCell>{exp.description}</TableCell>
                    <TableCell className="font-medium">₹{exp.amount.toLocaleString('en-IN')}</TableCell>
                    <TableCell className="text-right">
                      {canDeleteExpense(exp) ? (
                        <Button variant="ghost" size="icon" onClick={() => setExpenseToDelete(exp)}>
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      ) : (
                         <Button variant="ghost" size="icon" disabled title="Certain expense types cannot be deleted by a manager.">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell colSpan={5} className="h-24 text-center">
                    No expenses recorded yet.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <AlertDialog open={!!expenseToDelete} onOpenChange={() => setExpenseToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete this expense record.
              {expenseToDelete?.type === 'Labour' && " The amount will be added back to the worker's balance."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setExpenseToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteExpense} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
