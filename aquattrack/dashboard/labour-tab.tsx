
'use client';

import { useState, useMemo, useEffect } from "react";
import { format } from "date-fns";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { Worker, LabourPayment } from "@/lib/types";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Download, MoreHorizontal, PlusCircle, Users } from "lucide-react";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogFooter,
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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { Skeleton } from "@/components/ui/skeleton";

interface LabourTabProps {
  workers: Worker[];
  managerId: string;
  onDataUpdate: () => void;
  managerName?: string;
  labourPayments?: LabourPayment[];
}

export default function LabourTab({ workers, managerId, onDataUpdate, managerName, labourPayments = [] }: LabourTabProps) {
  const { toast } = useToast();
  const [isMounted, setIsMounted] = useState(false);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingWorker, setEditingWorker] = useState<Worker | null>(null);
  const [workerToDelete, setWorkerToDelete] = useState<Worker | null>(null);

  const [name, setName] = useState('');
  const [place, setPlace] = useState('');
  const [monthlySalary, setMonthlySalary] = useState('');
  const [monthsWorked, setMonthsWorked] = useState('');
  
  const [isReportDialogOpen, setIsReportDialogOpen] = useState(false);
  const [selectedWorkerForReport, setSelectedWorkerForReport] = useState<string>('');


  useEffect(() => {
    setIsMounted(true);
  }, []);

  const calculateSalaryBalance = (worker: Worker) => {
    return worker.monthlySalary * worker.monthsWorked - worker.amountPaid;
  };

  const totalSalaryBalance = useMemo(() => {
    return workers.reduce((acc, worker) => acc + calculateSalaryBalance(worker), 0);
  }, [workers]);

  const resetForm = () => {
    setName('');
    setPlace('');
    setMonthlySalary('');
    setMonthsWorked('');
    setEditingWorker(null);
  };

  const handleAddClick = () => {
    resetForm();
    setIsDialogOpen(true);
  };

  const handleEditClick = (worker: Worker) => {
    setEditingWorker(worker);
    setName(worker.name);
    setPlace(worker.place);
    setMonthlySalary(String(worker.monthlySalary));
    setMonthsWorked(String(worker.monthsWorked));
    setIsDialogOpen(true);
  };

  const handleDeleteClick = (worker: Worker) => {
    setWorkerToDelete(worker);
  };

  const confirmDelete = async () => {
    if (!workerToDelete) return;
    try {
      const res = await fetch(`/api/managers/${managerId}/workers/${workerToDelete.id}`, {
        method: 'DELETE'
      });
      if (!res.ok) throw new Error("Failed to delete worker");
      onDataUpdate();
      toast({ title: "Success", description: "Worker has been deleted." });
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete worker.' });
    } finally {
      setWorkerToDelete(null);
    }
  };

  const handleSaveWorker = async () => {
    if (!name || !monthlySalary) {
      toast({ variant: "destructive", title: "Error", description: "Name and Monthly Salary are required." });
      return;
    }
    
    const url = editingWorker ? `/api/managers/${managerId}/workers/${editingWorker.id}` : `/api/managers/${managerId}/workers`;
    const method = editingWorker ? 'PUT' : 'POST';

    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name,
          place,
          monthlySalary: parseFloat(monthlySalary) || 0,
          monthsWorked: parseInt(monthsWorked, 10) || 0,
        })
      });

      if (!res.ok) throw new Error(`Failed to ${editingWorker ? 'update' : 'add'} worker`);

      onDataUpdate();
      toast({ title: "Success", description: `Worker has been ${editingWorker ? 'updated' : 'added'}.` });
      setIsDialogOpen(false);
      resetForm();
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: `Could not ${editingWorker ? 'update' : 'add'} worker.` });
    }
  };
  
  const handleDownloadWorkerReport = () => {
    if (!selectedWorkerForReport || !managerName) return;

    const worker = workers.find(w => w.id === selectedWorkerForReport);
    if (!worker) {
      toast({ variant: 'destructive', title: 'Error', description: 'Selected worker not found.' });
      return;
    }
    
    const paymentsForWorker = labourPayments.filter(p => p.workerId === worker.id);
    const totalSalary = worker.monthlySalary * worker.monthsWorked;
    const totalPaid = paymentsForWorker.reduce((acc, p) => acc + p.amount, 0);
    const balance = totalSalary - totalPaid;

    const doc = new jsPDF();
    const primaryColor = [142, 25, 61]; // Burgundy
    
    // Header
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
    doc.text(`AquaTrack Worker Report`, 14, 22);

    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100);
    doc.text(`Worker: ${worker.name}`, 14, 30);
    doc.text(`Manager: ${managerName}`, 14, 36);
    doc.text(`Report Generated: ${format(new Date(), 'dd MMM yyyy, HH:mm')}`, 14, 42);

    // Summary Table
    autoTable(doc, {
      startY: 50,
      head: [['Summary', 'Amount (₹)']],
      body: [
        ['Total Salary (To Date)', `₹${totalSalary.toLocaleString('en-IN')}`],
        ['Total Amount Paid', `₹${totalPaid.toLocaleString('en-IN')}`],
        ['Outstanding Balance', `₹${balance.toLocaleString('en-IN')}`],
      ],
      theme: 'striped',
      headStyles: { fillColor: primaryColor },
      styles: { cellPadding: 2, fontSize: 10 },
      bodyStyles: { fontStyle: 'bold' }
    });

    let lastY = (doc as any).lastAutoTable.finalY || 50;

    // Payment History Table
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(40);
    doc.text('Payment History', 14, lastY + 15);
    
    if (paymentsForWorker.length > 0) {
        const tableColumns = ["Payment Date", "Amount Paid (₹)"];
        const tableRows = paymentsForWorker
          .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
          .map(p => [
              format(new Date(p.date), 'dd MMM yyyy'),
              `₹${p.amount.toLocaleString('en-IN')}`
          ]);

        autoTable(doc, {
            startY: lastY + 20,
            head: [tableColumns],
            body: tableRows,
            theme: 'striped',
            headStyles: { fillColor: primaryColor },
            styles: { cellPadding: 2, fontSize: 9 },
        });
    } else {
        doc.setFontSize(12);
        doc.text('No payment history found for this worker.', 14, lastY + 25);
    }

    const pageCount = doc.internal.getNumberOfPages();
    for(let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setDrawColor(180, 180, 180); // light grey line
        doc.line(14, doc.internal.pageSize.height - 15, doc.internal.pageSize.width - 14, doc.internal.pageSize.height - 15);
        doc.setFontSize(8);
        doc.setTextColor(150);
        doc.text(`Page ${i} of ${pageCount}`, doc.internal.pageSize.width - 25, doc.internal.pageSize.height - 10);
        doc.text(`Report Generated: ${format(new Date(), 'dd MMM yyyy, HH:mm')}`, 14, doc.internal.pageSize.height - 10);
    }

    doc.save(`financial_report_${worker.name.replace(' ', '_')}_${format(new Date(), 'yyyy_MM_dd')}.pdf`);
    
    setIsReportDialogOpen(false);
    setSelectedWorkerForReport('');
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 p-3">
          <div>
            <CardTitle className="font-headline text-base">Labor Management</CardTitle>
          </div>
          <div className="flex items-center gap-2 w-full sm:w-auto flex-wrap justify-start sm:justify-end">
            {managerName && (
               <Button onClick={() => setIsReportDialogOpen(true)} variant="outline" size="sm" className="flex-grow sm:flex-grow-0">
                <Download className="mr-2 h-4 w-4" /> Download Report
              </Button>
            )}
            <Button onClick={handleAddClick} size="sm" className="flex-grow sm:flex-grow-0">
              <PlusCircle className="mr-2 h-4 w-4" /> Add Worker
            </Button>
          </div>
        </CardHeader>
        <CardContent className="space-y-4 p-3">
          <Card className="bg-secondary">
              <CardContent className="p-3 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                      <Users className="w-6 h-6 text-muted-foreground"/>
                      <div>
                          <p className="text-xs text-muted-foreground">Total Salary Balance</p>
                          {isMounted ? (
                            <p className="text-xl font-bold">₹{totalSalaryBalance.toLocaleString('en-IN')}</p>
                          ) : (
                            <Skeleton className="h-7 w-28 mt-1" />
                          )}
                      </div>
                  </div>
              </CardContent>
          </Card>

          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Place</TableHead>
                <TableHead className="text-right">Salary</TableHead>
                <TableHead className="text-right">Balance</TableHead>
                <TableHead className="text-right w-[50px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isMounted ? (
                workers.length > 0 ? (
                  workers.map((worker: Worker) => (
                    <TableRow key={worker.id}>
                      <TableCell className="font-medium">{worker.name}</TableCell>
                      <TableCell>{worker.place}</TableCell>
                      <TableCell className="text-right">
                        ₹{worker.monthlySalary.toLocaleString('en-IN')}
                      </TableCell>
                      <TableCell className="text-right font-semibold">
                        ₹{calculateSalaryBalance(worker).toLocaleString('en-IN')}
                      </TableCell>
                      <TableCell className="text-right">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" className="h-7 w-7 p-0">
                              <span className="sr-only">Open menu</span>
                              <MoreHorizontal className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuLabel>Actions</DropdownMenuLabel>
                            <DropdownMenuItem onClick={() => handleEditClick(worker)}>Edit</DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleDeleteClick(worker)} className="text-destructive">Delete</DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={5} className="text-center h-24">No workers added yet.</TableCell>
                  </TableRow>
                )
              ) : (
                <>
                  {[...Array(3)].map((_, i) => (
                      <TableRow key={i}>
                          <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                          <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                          <TableCell className="text-right"><Skeleton className="h-4 w-16 inline-block" /></TableCell>
                          <TableCell className="text-right"><Skeleton className="h-4 w-16 inline-block" /></TableCell>
                          <TableCell className="text-right"><Skeleton className="h-7 w-7 inline-block rounded-md" /></TableCell>
                      </TableRow>
                  ))}
                </>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      {/* Add/Edit Worker Dialog */}
      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>{editingWorker ? 'Edit Worker' : 'Add New Worker'}</DialogTitle>
                <DialogDescription>
                  {editingWorker ? 'Update the details of the worker.' : 'Enter the details of the new worker.'}
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="name" className="text-right">Name</Label>
                  <Input id="name" value={name} onChange={(e) => setName(e.target.value)} className="col-span-3" />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="place" className="text-right">Place</Label>
                  <Input id="place" value={place} onChange={(e) => setPlace(e.target.value)} className="col-span-3" />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="salary" className="text-right">Monthly Salary (₹)</Label>
                  <Input id="salary" type="number" value={monthlySalary} onChange={(e) => setMonthlySalary(e.target.value)} className="col-span-3" />
                </div>
                <div className="grid grid-cols-4 items-center gap-4">
                  <Label htmlFor="months" className="text-right">Months Worked</Label>
                  <Input id="months" type="number" value={monthsWorked} onChange={(e) => setMonthsWorked(e.target.value)} className="col-span-3" />
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setIsDialogOpen(false)}>Cancel</Button>
                <Button type="submit" onClick={handleSaveWorker}>Save Worker</Button>
              </DialogFooter>
            </DialogContent>
      </Dialog>
      
      {/* Delete Confirmation Dialog */}
      <AlertDialog open={!!workerToDelete} onOpenChange={() => setWorkerToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the worker
              and their associated data.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setWorkerToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

       {/* Worker Report Dialog */}
      <Dialog open={isReportDialogOpen} onOpenChange={setIsReportDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Download Worker Financial Report</DialogTitle>
            <DialogDescription>
              Select a worker to download their detailed financial report.
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="worker-report-select">Worker</Label>
              <Select value={selectedWorkerForReport} onValueChange={setSelectedWorkerForReport}>
                <SelectTrigger id="worker-report-select">
                  <SelectValue placeholder="Select a worker" />
                </SelectTrigger>
                <SelectContent>
                  {workers.map((worker) => (
                    <SelectItem key={worker.id} value={worker.id}>
                      {worker.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => { setIsReportDialogOpen(false); setSelectedWorkerForReport(''); }}>Cancel</Button>
            <Button onClick={handleDownloadWorkerReport} disabled={!selectedWorkerForReport}>Download Report</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
