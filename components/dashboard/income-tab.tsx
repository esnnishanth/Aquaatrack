
'use client';

import { useState, useMemo, useEffect } from "react";
import { format } from "date-fns";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
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
import { IndianRupee, Wallet, CalendarIcon, List, Trash2 } from "lucide-react";
import type { Bore, Payment } from "@/lib/types";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";

interface IncomeTabProps {
  role: 'owner' | 'manager';
  bores: Bore[];
  managerId: string;
  onDataUpdate: () => void;
}

const getAmountPaid = (bore: Bore) => (bore.payments || []).reduce((acc, p) => acc + p.amount, 0);
const getBalanceAmount = (bore: Bore) => bore.totalBill - getAmountPaid(bore);

export default function IncomeTab({ role, bores, managerId, onDataUpdate }: IncomeTabProps) {
  const { toast } = useToast();
  const [isMounted, setIsMounted] = useState(false);
  const [selectedBore, setSelectedBore] = useState("");
  const [amountReceived, setAmountReceived] = useState("");
  const [paymentDate, setPaymentDate] = useState<Date | undefined>(new Date());
  const [paymentToDelete, setPaymentToDelete] = useState<(Payment & { boreId: string }) | null>(null);

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const boresWithBalance = bores.filter(
    (bore) => getBalanceAmount(bore) > 0
  );

  const allPayments = useMemo(() => {
    return bores
      .flatMap(bore =>
        (bore.payments || []).map(p => ({ ...p, boreNumber: bore.boreNumber, boreId: bore.id }))
      )
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }, [bores]);

  const handleUpdateBalance = async () => {
    if (!selectedBore || !amountReceived || !paymentDate) {
        toast({
            variant: "destructive",
            title: "Error",
            description: "Please select a bore, payment date, and enter an amount.",
        });
        return;
    }
    
    const amount = parseFloat(amountReceived);
    if (isNaN(amount) || amount <= 0) {
        toast({
            variant: "destructive",
            title: "Error",
            description: "Please enter a valid amount.",
        });
        return;
    }

    const boreToUpdate = bores.find(b => b.id === selectedBore);
    if(boreToUpdate && amount > getBalanceAmount(boreToUpdate)) {
        toast({
            variant: "destructive",
            title: "Error",
            description: `Amount cannot be greater than the balance of ₹${getBalanceAmount(boreToUpdate).toLocaleString('en-IN')}.`,
        });
        return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/bores/${selectedBore}/payments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          amount,
          date: paymentDate
        })
      });
      if(!res.ok) throw new Error("Failed to record payment");

      onDataUpdate();
      toast({
          title: "Success",
          description: `Payment for bore recorded successfully.`,
      });

      // Reset form
      setSelectedBore("");
      setAmountReceived("");
      setPaymentDate(new Date());

    } catch(error) {
      toast({ variant: "destructive", title: "Error", description: "Could not record payment." });
    }
  }

  const confirmDelete = async () => {
    if (!paymentToDelete) return;
    
    try {
      const res = await fetch(`/api/managers/${managerId}/bores/${paymentToDelete.boreId}/payments/${paymentToDelete.id}`, {
        method: 'DELETE'
      });
      if(!res.ok) throw new Error("Failed to delete payment.");

      onDataUpdate();
      toast({ title: "Success", description: "Payment record deleted." });
    } catch(error) {
      toast({ variant: "destructive", title: "Error", description: "Could not delete payment." });
    } finally {
      setPaymentToDelete(null);
    }
  };

  return (
    <>
      <div className="grid lg:grid-cols-2 gap-6 items-start">
          <Card>
              <CardHeader>
              <CardTitle className="font-headline flex items-center gap-2"><Wallet/> Record Income</CardTitle>
              <CardDescription>
                  Log a new payment received for a bore. This will update the bore's balance amount.
              </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
              <div className="space-y-2">
                  <Label htmlFor="bore-select">Select Bore (by Number)</Label>
                  <Select value={selectedBore} onValueChange={setSelectedBore}>
                  <SelectTrigger id="bore-select">
                      <SelectValue placeholder="Select a bore with an outstanding balance" />
                  </SelectTrigger>
                  <SelectContent>
                      {boresWithBalance.length > 0 ? (
                      boresWithBalance.map((bore) => (
                          <SelectItem key={bore.id} value={bore.id}>
                          {bore.boreNumber} (Balance: ₹{getBalanceAmount(bore).toLocaleString('en-IN')})
                          </SelectItem>
                      ))
                      ) : (
                      <SelectItem value="no-bores" disabled>No bores with outstanding balance</SelectItem>
                      )}
                  </SelectContent>
                  </Select>
              </div>
              <div className="space-y-2">
                  <Label htmlFor="payment-date">Payment Date</Label>
                  <Popover>
                      <PopoverTrigger asChild>
                      <Button
                          variant={"outline"}
                          className={cn(
                          "w-full justify-start text-left font-normal",
                          !paymentDate && "text-muted-foreground"
                          )}
                      >
                          <CalendarIcon className="mr-2 h-4 w-4" />
                          {paymentDate ? format(paymentDate, "PPP") : <span>Pick a date</span>}
                      </Button>
                      </PopoverTrigger>
                      <PopoverContent className="w-auto p-0">
                      <Calendar
                          mode="single"
                          selected={paymentDate}
                          onSelect={setPaymentDate}
                          initialFocus
                      />
                      </PopoverContent>
                  </Popover>
                  </div>
              <div className="space-y-2">
                  <Label htmlFor="amount-paid">Amount Received</Label>
                  <div className="relative">
                  <IndianRupee className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input 
                      id="amount-paid" 
                      type="number" 
                      placeholder="Amount" 
                      className="pl-8"
                      value={amountReceived}
                      onChange={e => setAmountReceived(e.target.value)}
                  />
                  </div>
              </div>
              </CardContent>
              <CardFooter>
              <Button className="w-full" onClick={handleUpdateBalance} disabled={!selectedBore || !amountReceived}>Update Balance</Button>
              </CardFooter>
          </Card>
          <Card>
              <CardHeader>
                  <CardTitle className="font-headline flex items-center gap-2"><List/> Income History</CardTitle>
                  <CardDescription>
                      A log of all payments received from all bores.
                  </CardDescription>
              </CardHeader>
              <CardContent>
                  <Table>
                      <TableHeader>
                          <TableRow>
                              <TableHead>Date</TableHead>
                              <TableHead>Bore No.</TableHead>
                              <TableHead>Amount (₹)</TableHead>
                              {role === 'owner' && <TableHead className="text-right">Actions</TableHead>}
                          </TableRow>
                      </TableHeader>
                      <TableBody>
                          {isMounted ? (
                              allPayments.length > 0 ? (
                                  allPayments.map(payment => (
                                      <TableRow key={payment.id}>
                                          <TableCell>{format(new Date(payment.date), 'dd/MM/yy')}</TableCell>
                                          <TableCell className="font-medium">{payment.boreNumber}</TableCell>
                                          <TableCell className="font-semibold">₹{payment.amount.toLocaleString('en-IN')}</TableCell>
                                          {role === 'owner' && (
                                            <TableCell className="text-right">
                                                <Button variant="ghost" size="icon" onClick={() => setPaymentToDelete(payment)}>
                                                    <Trash2 className="h-4 w-4 text-destructive" />
                                                </Button>
                                            </TableCell>
                                          )}
                                      </TableRow>
                                  ))
                              ) : (
                                  <TableRow>
                                      <TableCell colSpan={role === 'owner' ? 4 : 3} className="text-center h-24">No income recorded yet.</TableCell>
                                  </TableRow>
                              )
                          ) : (
                              <>
                                  {[...Array(3)].map((_, i) => (
                                      <TableRow key={i}>
                                          <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                                          <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                                          <TableCell><Skeleton className="h-4 w-24" /></TableCell>
                                          {role === 'owner' && <TableCell className="text-right"><Skeleton className="h-8 w-8" /></TableCell>}
                                      </TableRow>
                                  ))}
                              </>
                          )}
                      </TableBody>
                  </Table>
              </CardContent>
          </Card>
      </div>
      <AlertDialog open={!!paymentToDelete} onOpenChange={() => setPaymentToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete this payment record.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setPaymentToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
