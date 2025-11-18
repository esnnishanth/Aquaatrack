
'use client';

import { useState, useEffect, useMemo } from "react";
import { format } from "date-fns";
import type { DateRange } from "react-day-picker";
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
  CardFooter
} from "@/components/ui/card";
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
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { PlusCircle, List, CalendarIcon, MoreHorizontal, Trash2, UserPlus, Edit, Eye, ArrowUp, ArrowDown, ArrowUpDown, FileDown } from "lucide-react";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import type { Bore, PipeLog, Agent, PipeEntry } from "@/lib/types";
import { useToast } from "@/hooks/use-toast";
import { cn } from "@/lib/utils";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "../ui/separator";

interface BoreTabProps {
  role: 'owner' | 'manager';
  bores: Bore[];
  pipeLogs: PipeLog[];
  agents: Agent[];
  managerId: string;
  onDataUpdate: () => void;
}

interface PipeFormEntry {
    id: string;
    size: string;
    length: string;
    pricePerPipeFoot: string;
}


const getAmountPaid = (bore: Bore) => (bore.payments || []).reduce((acc, p) => acc + p.amount, 0);
const getBalanceAmount = (bore: Bore) => bore.totalBill - getAmountPaid(bore);

export default function BoreTab({ role, bores, pipeLogs, agents, managerId, onDataUpdate }: BoreTabProps) {
  const { toast } = useToast();
  const [isMounted, setIsMounted] = useState(false);
  
  // Form state
  const [date, setDate] = useState<Date | undefined>(new Date());
  const [totalFeet, setTotalFeet] = useState('');
  const [pricePerFeet, setPricePerFeet] = useState('');
  const [pipeEntries, setPipeEntries] = useState<PipeFormEntry[]>([{ id: `pipe-${Date.now()}`, size: '', length: '', pricePerPipeFoot: '' }]);
  const [agentName, setAgentName] = useState('');
  const [amountPaidInitial, setAmountPaidInitial] = useState('0');
  
  // Other component state
  const [boreToDelete, setBoreToDelete] = useState<Bore | null>(null);
  const [boreForDetails, setBoreForDetails] = useState<Bore | null>(null);
  const [totalBill, setTotalBill] = useState(0);
  const [newBoreNumber, setNewBoreNumber] = useState('');

  // Agent Management State
  const [isAgentDialogOpen, setIsAgentDialogOpen] = useState(false);
  const [agentNameInput, setAgentNameInput] = useState('');
  const [agentToEdit, setAgentToEdit] = useState<Agent | null>(null);
  const [agentToDelete, setAgentToDelete] = useState<Agent | null>(null);
  
  // Agent Balance Report State
  const [isBalanceReportDialogOpen, setIsBalanceReportDialogOpen] = useState(false);
  const [selectedAgentForReport, setSelectedAgentForReport] = useState<string>('');

  // Sorting and Filtering State
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'ascending' | 'descending' }>({ key: 'date', direction: 'descending' });
  const [agentFilter, setAgentFilter] = useState('all');
  const [statusFilter, setStatusFilter] = useState('all');
  const [dateRange, setDateRange] = useState<DateRange | undefined>();

  useEffect(() => {
    setIsMounted(true);
    const latestBoreNumber = bores.length > 0 
        ? Math.max(...bores.map(b => parseInt(b.boreNumber.replace('B', ''), 10)))
        : 0;
    setNewBoreNumber(`B${String(latestBoreNumber + 1).padStart(3, '0')}`);
  }, [bores]);

  const managerPipeStock = useMemo(() => {
    if (!pipeLogs || pipeLogs.length === 0) return [];
    
    const balanceMap = new Map<number, number>();

    pipeLogs.forEach(log => {
        const currentQuantity = balanceMap.get(log.diameter) || 0;
        if (log.type === 'Purchase') {
            balanceMap.set(log.diameter, currentQuantity + log.quantity);
        } else {
            balanceMap.set(log.diameter, currentQuantity - log.quantity);
        }
    });

    return Array.from(balanceMap.entries())
        .map(([size, quantity]) => ({ size, quantity }))
        .filter(item => item.quantity > 0)
        .sort((a, b) => a.size - b.size);
  }, [pipeLogs]);

  useEffect(() => {
    const _totalFeet = parseFloat(totalFeet) || 0;
    const _pricePerFeet = parseFloat(pricePerFeet) || 0;
    const _amountPaid = parseFloat(amountPaidInitial) || 0;

    const boreCost = _totalFeet * _pricePerFeet;
    const pipeCost = pipeEntries.reduce((acc, entry) => {
        const length = parseFloat(entry.length) || 0;
        const price = parseFloat(entry.pricePerPipeFoot) || 0;
        return acc + (length * price);
    }, 0);
    
    const calculatedBill = boreCost + pipeCost;
    setTotalBill(calculatedBill);
  }, [totalFeet, pricePerFeet, pipeEntries, amountPaidInitial]);
  
  const filteredAndSortedBores = useMemo(() => {
    let filteredItems = [...bores];

    if (dateRange?.from) {
      filteredItems = filteredItems.filter(bore => {
        const boreDate = new Date(bore.date);
        boreDate.setHours(0,0,0,0);
        const fromDate = new Date(dateRange.from!);
        fromDate.setHours(0,0,0,0);

        if (dateRange.to) {
          const toDate = new Date(dateRange.to);
          toDate.setHours(0,0,0,0);
          return boreDate >= fromDate && boreDate <= toDate;
        }

        return boreDate.getTime() === fromDate.getTime();
      });
    }

    if (agentFilter !== 'all') {
      filteredItems = filteredItems.filter(bore => bore.agentName === agentFilter);
    }
    
    if (statusFilter !== 'all') {
      filteredItems = filteredItems.filter(bore => {
        const balance = getBalanceAmount(bore);
        if (statusFilter === 'paid') return balance <= 0;
        if (statusFilter === 'pending') return balance > 0;
        return true;
      });
    }

    if (sortConfig.key) {
        filteredItems.sort((a, b) => {
            let aValue: any;
            let bValue: any;

            switch (sortConfig.key) {
                case 'date':
                    aValue = new Date(a.date).getTime();
                    bValue = new Date(b.date).getTime();
                    break;
                default:
                    return 0;
            }
            
            if (aValue < bValue) {
                return sortConfig.direction === 'ascending' ? -1 : 1;
            }
            if (aValue > bValue) {
                return sortConfig.direction === 'ascending' ? 1 : -1;
            }
            return 0;
        });
    }
    return filteredItems;
  }, [bores, sortConfig, agentFilter, statusFilter, dateRange]);


  const requestSort = (key: string) => {
    let direction: 'ascending' | 'descending' = 'ascending';
    if (sortConfig.key === key && sortConfig.direction === 'ascending') {
        direction = 'descending';
    }
    setSortConfig({ key, direction });
  };

  const getSortIcon = (key: string) => {
    if (sortConfig.key !== key) {
        return <ArrowUpDown className="ml-2 h-3 w-3" />;
    }
    if (sortConfig.direction === 'ascending') {
        return <ArrowUp className="ml-2 h-3 w-3" />;
    }
    return <ArrowDown className="ml-2 h-3 w-3" />;
  };

  const handleAddPipeEntry = () => {
    setPipeEntries([...pipeEntries, { id: `pipe-${Date.now()}`, size: '', length: '', pricePerPipeFoot: '' }]);
  };

  const handleRemovePipeEntry = (id: string) => {
    setPipeEntries(pipeEntries.filter(entry => entry.id !== id));
  };

  const handlePipeEntryChange = (id: string, field: keyof PipeFormEntry, value: string) => {
    setPipeEntries(pipeEntries.map(entry => entry.id === id ? { ...entry, [field]: value } : entry));
  };


  const handleAddBore = async () => {
    if (!date) {
      toast({ variant: "destructive", title: "Error", description: "Please select a date." });
      return;
    }

    const pipesNeededPerSize = pipeEntries.reduce((acc, entry) => {
        const size = parseFloat(entry.size);
        if (isNaN(size) || !entry.length || parseFloat(entry.length) <= 0) return acc;

        const pipesNeeded = Math.ceil((parseFloat(entry.length) || 0) / 20);
        acc.set(size, (acc.get(size) || 0) + pipesNeeded);
        return acc;
    }, new Map<number, number>());

    let inventoryError = '';
    for (const [size, needed] of pipesNeededPerSize.entries()) {
        const stock = managerPipeStock.find(s => s.size === size)?.quantity || 0;
        if (needed > stock) {
            inventoryError = `You need ${needed} pipes of size ${size}", but only have ${stock} in stock.`;
            break;
        }
    }

    if (inventoryError) {
        toast({ variant: "destructive", title: "Error: Insufficient Pipe Stock", description: inventoryError, duration: 5000 });
        return;
    }
    
    const initialPaymentAmount = parseFloat(amountPaidInitial) || 0;

    const newBoreData = {
      date,
      boreNumber: newBoreNumber,
      totalFeet: parseFloat(totalFeet) || 0,
      pricePerFeet: parseFloat(pricePerFeet) || 0,
      pipesUsed: pipeEntries.filter(p => p.size && p.length).map(p => ({
          size: parseFloat(p.size),
          length: parseFloat(p.length) || 0,
          pricePerPipeFoot: parseFloat(p.pricePerPipeFoot) || 0,
      })),
      agentName,
      totalBill,
      initialPayment: initialPaymentAmount,
      pipeLogs: Array.from(pipesNeededPerSize.entries()).map(([size, quantity]) => ({
          type: 'Usage',
          quantity,
          diameter: size,
      }))
    };

    try {
        const res = await fetch(`/api/managers/${managerId}/bores`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newBoreData),
        });

        if (!res.ok) throw new Error("Failed to add bore");

        toast({
            title: "Success",
            description: `Bore ${newBoreNumber} has been added & pipe stock updated.`,
        });

        onDataUpdate();

        // Reset form
        setDate(new Date());
        setTotalFeet('');
        setPricePerFeet('');
        setPipeEntries([{ id: `pipe-${Date.now()}`, size: '', length: '', pricePerPipeFoot: '' }]);
        setAgentName('');
        setAmountPaidInitial('0');

    } catch (error) {
        toast({ variant: "destructive", title: "Error", description: "Could not add bore." });
    }
  };
  
  const confirmDelete = async () => {
      if (!boreToDelete) return;
      try {
        const res = await fetch(`/api/managers/${managerId}/bores/${boreToDelete.id}`, {
            method: 'DELETE',
        });
        if (!res.ok) throw new Error("Failed to delete bore");
        onDataUpdate();
        toast({ title: "Success", description: "Bore and related data deleted." });
      } catch (error) {
        toast({ variant: "destructive", title: "Error", description: "Could not delete bore." });
      } finally {
        setBoreToDelete(null);
      }
  };

  const handleOpenAgentDialog = (agent: Agent | null) => {
    if (agent) {
        setAgentToEdit(agent);
        setAgentNameInput(agent.name);
    } else {
        setAgentToEdit(null);
        setAgentNameInput('');
    }
    setIsAgentDialogOpen(true);
  };

  const handleSaveAgent = async () => {
    if (!agentNameInput.trim()) {
        toast({ variant: "destructive", title: "Error", description: "Agent name cannot be empty." });
        return;
    }
    if (agents.some(a => a.name.toLowerCase() === agentNameInput.trim().toLowerCase() && a.id !== agentToEdit?.id)) {
        toast({ variant: "destructive", title: "Error", description: "An agent with this name already exists." });
        return;
    }

    const url = agentToEdit ? `/api/managers/${managerId}/agents/${agentToEdit.id}` : `/api/managers/${managerId}/agents`;
    const method = agentToEdit ? 'PUT' : 'POST';

    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: agentNameInput.trim() })
      });
      if (!res.ok) throw new Error(`Failed to ${agentToEdit ? 'update' : 'add'} agent`);
      onDataUpdate();
      toast({ title: "Success", description: `Agent ${agentToEdit ? 'updated' : 'added'}.` });
    } catch(error) {
      toast({ variant: 'destructive', title: 'Error', description: `Could not ${agentToEdit ? 'update' : 'add'} agent.` });
    } finally {
      setAgentNameInput('');
      setAgentToEdit(null);
    }
  };

  const confirmDeleteAgent = async () => {
    if (!agentToDelete) return;
    
    const isAgentInUse = bores.some(b => b.agentName === agentToDelete.name);
    if (isAgentInUse) {
        toast({
            variant: "destructive",
            title: "Cannot Delete Agent",
            description: "This agent is assigned to one or more bores and cannot be deleted.",
        });
        setAgentToDelete(null);
        return;
    }

    try {
      const res = await fetch(`/api/managers/${managerId}/agents/${agentToDelete.id}`, {
        method: 'DELETE'
      });
      if (!res.ok) throw new Error("Failed to delete agent");
      onDataUpdate();
      toast({ title: "Success", description: "Agent deleted." });
    } catch (error) {
      toast({ variant: 'destructive', title: 'Error', description: 'Could not delete agent.' });
    } finally {
      setAgentToDelete(null);
    }
  };
  
  const handleDownloadAgentBalanceReport = () => {
    if (!selectedAgentForReport) return;

    const agent = agents.find(a => a.id === selectedAgentForReport);
    if (!agent) {
        toast({ variant: 'destructive', title: 'Error', description: 'Selected agent not found.' });
        return;
    }

    const agentBores = bores.filter(b => b.agentName === agent.name);
    const totalBalance = agentBores.reduce((acc, bore) => acc + getBalanceAmount(bore), 0);

    const doc = new jsPDF();
    const primaryColor = [142, 25, 61]; // Burgundy

    // Header
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
    doc.text(`Agent Balance Report`, 14, 22);

    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100);
    doc.text(`Agent: ${agent.name}`, 14, 30);
    doc.text(`Report Generated: ${format(new Date(), 'dd MMM yyyy, HH:mm')}`, 14, 36);

    // Summary
    autoTable(doc, {
        startY: 45,
        head: [['Summary', 'Amount (₹)']],
        body: [
            ['Total Outstanding Balance', `₹${totalBalance.toLocaleString('en-IN')}`],
        ],
        theme: 'striped',
        headStyles: { fillColor: primaryColor },
        styles: { cellPadding: 3, fontSize: 10 },
        bodyStyles: { fontStyle: 'bold', fontSize: 12 }
    });
    
    let lastY = (doc as any).lastAutoTable.finalY || 45;

    // Bore Details Table
    if (agentBores.length > 0) {
        doc.setFontSize(14);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(40);
        doc.text('Bore Details', 14, lastY + 15);

        const tableColumns = ["Date", "Bore No.", "Total Bill (₹)", "Paid (₹)", "Balance (₹)"];
        const tableRows = agentBores
            .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
            .map(bore => [
                format(new Date(bore.date), 'dd/MM/yy'),
                bore.boreNumber,
                bore.totalBill.toLocaleString('en-IN'),
                getAmountPaid(bore).toLocaleString('en-IN'),
                getBalanceAmount(bore).toLocaleString('en-IN')
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
        doc.text('No bores found for this agent.', 14, lastY + 25);
    }
    
    // Footer
    const pageCount = doc.internal.getNumberOfPages();
    for(let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        doc.setDrawColor(180, 180, 180);
        doc.line(14, doc.internal.pageSize.height - 15, doc.internal.pageSize.width - 14, doc.internal.pageSize.height - 15);
        doc.setFontSize(8);
        doc.setTextColor(150);
        doc.text(`Page ${i} of ${pageCount}`, doc.internal.pageSize.width - 25, doc.internal.pageSize.height - 10);
    }

    doc.save(`balance_report_${agent.name.replace(/\s/g, '_')}_${format(new Date(), 'yyyyMMdd')}.pdf`);
    
    setIsBalanceReportDialogOpen(false);
    setSelectedAgentForReport('');
  };


  return (
    <>
      <div className="grid lg:grid-cols-3 gap-4">
        <div className="lg:col-span-1">
          <Card>
            <CardHeader className="p-3">
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
                <CardTitle className="font-headline text-base flex items-center gap-2"><PlusCircle/> Add New Bore</CardTitle>
                {role === 'owner' && (
                  <div className="flex items-center gap-2 w-full sm:w-auto">
                    <Button variant="outline" size="sm" onClick={() => setIsBalanceReportDialogOpen(true)} className="flex-1 sm:flex-none">
                      <FileDown className="mr-1 h-3 w-3" /> Balance
                    </Button>
                    <Button variant="outline" size="sm" onClick={() => handleOpenAgentDialog(null)} className="flex-1 sm:flex-none">
                      <UserPlus className="mr-1 h-3 w-3" /> Agents
                    </Button>
                  </div>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-3 p-3">
                <div className="grid gap-1.5">
                    <Label htmlFor="date" className="text-xs">Date</Label>
                    <Popover>
                        <PopoverTrigger asChild>
                        <Button
                            variant={"outline"}
                            size="sm"
                            className={cn(
                            "w-full justify-start text-left font-normal",
                            !date && "text-muted-foreground"
                            )}
                        >
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {date ? format(date, "PPP") : <span>Pick a date</span>}
                        </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0">
                        <Calendar
                            mode="single"
                            selected={date}
                            onSelect={setDate}
                            initialFocus
                        />
                        </PopoverContent>
                    </Popover>
                </div>
                <div className="grid gap-1.5">
                    <Label className="text-xs">Bore Number</Label>
                    <div className="flex h-8 w-full items-center rounded-sm border border-input bg-muted px-3 py-2 text-sm text-muted-foreground">
                        {newBoreNumber}
                    </div>
                </div>
                <div className="grid grid-cols-2 gap-2">
                    <div className="grid gap-1.5">
                        <Label htmlFor="total-feet" className="text-xs">Total Feet</Label>
                        <Input id="total-feet" type="number" value={totalFeet} onChange={e => setTotalFeet(e.target.value)} />
                    </div>
                    <div className="grid gap-1.5">
                        <Label htmlFor="price-per-feet" className="text-xs">Price/Feet (₹)</Label>
                        <Input id="price-per-feet" type="number" value={pricePerFeet} onChange={e => setPricePerFeet(e.target.value)} />
                    </div>
                </div>

                <div className="space-y-2 rounded-sm border p-2">
                    <Label className="text-xs px-1">Pipes Used</Label>
                    {pipeEntries.map((entry, index) => (
                         <div key={entry.id} className="flex flex-col sm:flex-row gap-2 items-end relative sm:pr-8">
                            <div className="grid gap-1.5 flex-1 min-w-[60px] w-full">
                                {index === 0 && <Label htmlFor={`pipe-size-${entry.id}`} className="text-xs">Size</Label>}
                                <Select value={entry.size} onValueChange={(value) => handlePipeEntryChange(entry.id, 'size', value)} disabled={managerPipeStock.length === 0}>
                                <SelectTrigger id={`pipe-size-${entry.id}`}>
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                    {managerPipeStock.map(pipe => (
                                        <SelectItem key={`${entry.id}-${pipe.size}`} value={String(pipe.size)}>{pipe.size}" ({pipe.quantity})</SelectItem>
                                    ))}
                                </SelectContent>
                                </Select>
                            </div>
                            <div className="grid gap-1.5 flex-1 min-w-[60px] w-full">
                                {index === 0 && <Label htmlFor={`pipe-length-${entry.id}`} className="text-xs">Length</Label>}
                                <Input id={`pipe-length-${entry.id}`} type="number" value={entry.length} onChange={(e) => handlePipeEntryChange(entry.id, 'length', e.target.value)} />
                            </div>
                            <div className="grid gap-1.5 flex-1 min-w-[60px] w-full">
                                {index === 0 && <Label htmlFor={`pipe-price-${entry.id}`} className="text-xs">Price/ft</Label>}
                                <Input id={`pipe-price-${entry.id}`} type="number" value={entry.pricePerPipeFoot} onChange={(e) => handlePipeEntryChange(entry.id, 'pricePerPipeFoot', e.target.value)} />
                            </div>
                            {pipeEntries.length > 1 && (
                                <Button variant="ghost" size="icon" className="absolute right-0 bottom-1 text-destructive hover:bg-destructive/10 h-7 w-7" onClick={() => handleRemovePipeEntry(entry.id)}>
                                    <Trash2 className="h-4 w-4" />
                                </Button>
                            )}
                        </div>
                    ))}
                    <Button variant="outline" size="sm" onClick={handleAddPipeEntry} className="w-full">
                        <PlusCircle className="mr-2 h-4 w-4" /> Add Another Pipe
                    </Button>
                </div>
              
              <div className="grid gap-1.5">
                <Label htmlFor="agent-name" className="text-xs">Agent Name</Label>
                <Select value={agentName} onValueChange={setAgentName} disabled={agents.length === 0}>
                  <SelectTrigger id="agent-name">
                      <SelectValue placeholder="Select an agent" />
                  </SelectTrigger>
                  <SelectContent>
                      {agents.map(agent => (
                          <SelectItem key={agent.id} value={agent.name}>{agent.name}</SelectItem>
                      ))}
                  </SelectContent>
                </Select>
                {agents.length === 0 && <p className="text-xs text-muted-foreground">No agents found. An owner must add agents first.</p>}
              </div>
              <div className="grid gap-1.5">
                  <Label htmlFor="amount-paid-initial" className="text-xs">Amount Paid (Initial)</Label>
                  <Input id="amount-paid-initial" type="number" value={amountPaidInitial} onChange={e => setAmountPaidInitial(e.target.value)} />
                </div>
              <Card className="bg-muted p-2 space-y-1 mt-2">
                  <div className="flex justify-between text-xs">
                      <p className="text-muted-foreground">Total Bill</p>
                      <p className="font-medium">₹{totalBill.toLocaleString('en-IN')}</p>
                  </div>
                  <div className="flex justify-between text-xs">
                      <p className="text-muted-foreground">Amount Paid</p>
                      <p className="font-medium">₹{(parseFloat(amountPaidInitial) || 0).toLocaleString('en-IN')}</p>
                  </div>
                  <Separator/>
                  <div className="flex justify-between text-xs font-semibold">
                      <p>Balance</p>
                      <p>₹{(totalBill - (parseFloat(amountPaidInitial) || 0)).toLocaleString('en-IN')}</p>
                  </div>
              </Card>
            </CardContent>
            <CardFooter className="p-3">
              <Button size="sm" className="w-full" onClick={handleAddBore}>Add Bore</Button>
            </CardFooter>
          </Card>
        </div>
        <div className="lg:col-span-2">
          <Card>
            <CardHeader className="p-3">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                  <CardTitle className="font-headline text-base flex items-center gap-2"><List/> Bore History</CardTitle>
                  <div className="flex items-center gap-2 flex-wrap">
                      <Popover>
                        <PopoverTrigger asChild>
                            <Button
                            id="date"
                            variant={"outline"}
                            size="sm"
                            className={cn(
                                "w-full sm:w-[180px] justify-start text-left font-normal",
                                !dateRange && "text-muted-foreground"
                            )}
                            >
                            <CalendarIcon className="mr-2 h-4 w-4" />
                            {dateRange?.from ? (
                                dateRange.to ? (
                                <>
                                    {format(dateRange.from, "LLL dd, y")} -{" "}
                                    {format(dateRange.to, "LLL dd, y")}
                                </>
                                ) : (
                                format(dateRange.from, "LLL dd, y")
                                )
                            ) : (
                                <span>Filter by date</span>
                            )}
                            </Button>
                        </PopoverTrigger>
                        <PopoverContent className="w-auto p-0" align="end">
                            <Calendar
                            initialFocus
                            mode="range"
                            defaultMonth={dateRange?.from}
                            selected={dateRange}
                            onSelect={setDateRange}
                            numberOfMonths={2}
                            />
                        </PopoverContent>
                      </Popover>
                      <Select value={agentFilter} onValueChange={setAgentFilter} disabled={agents.length === 0}>
                          <SelectTrigger className="w-full sm:w-[120px]" size="sm">
                              <SelectValue placeholder="Agent" />
                          </SelectTrigger>
                          <SelectContent>
                              <SelectItem value="all">All Agents</SelectItem>
                              {agents.map(agent => (
                                  <SelectItem key={agent.id} value={agent.name}>{agent.name}</SelectItem>
                              ))}
                          </SelectContent>
                      </Select>
                      <Select value={statusFilter} onValueChange={setStatusFilter}>
                          <SelectTrigger className="w-full sm:w-[100px]" size="sm">
                              <SelectValue placeholder="Status" />
                          </SelectTrigger>
                          <SelectContent>
                              <SelectItem value="all">All Statuses</SelectItem>
                              <SelectItem value="paid">Paid</SelectItem>
                              <SelectItem value="pending">Pending</SelectItem>
                          </SelectContent>
                      </Select>
                  </div>
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                  <TableHeader>
                      <TableRow>
                          <TableHead>
                            <Button variant="ghost" onClick={() => requestSort('date')} className="px-2 h-8 text-xs">
                                Date {getSortIcon('date')}
                            </Button>
                          </TableHead>
                          <TableHead>Bore No.</TableHead>
                          <TableHead>Agent</TableHead>
                          <TableHead>Total Bill</TableHead>
                          <TableHead>Balance</TableHead>
                          <TableHead>Status</TableHead>
                          {role === 'owner' && <TableHead className="text-right">Actions</TableHead>}
                      </TableRow>
                  </TableHeader>
                  <TableBody>
                      {isMounted ? (
                        filteredAndSortedBores.length > 0 ? (
                          filteredAndSortedBores.map(bore => {
                              const amountPaid = getAmountPaid(bore);
                              const balanceAmount = getBalanceAmount(bore);
                              return (
                                <TableRow key={bore.id}>
                                    <TableCell>{format(new Date(bore.date), 'dd/MM/yy')}</TableCell>
                                    <TableCell className="font-semibold">{bore.boreNumber}</TableCell>
                                    <TableCell>{bore.agentName}</TableCell>
                                    <TableCell>₹{bore.totalBill.toLocaleString('en-IN')}</TableCell>
                                    <TableCell className="font-medium">₹{balanceAmount.toLocaleString('en-IN')}</TableCell>
                                    <TableCell>
                                        {balanceAmount <= 0 ? (
                                            <Badge variant="success">Paid</Badge>
                                        ) : (
                                            <Badge variant="warning">Pending</Badge>
                                        )}
                                    </TableCell>
                                    {role === 'owner' && (
                                      <TableCell className="text-right">
                                        <DropdownMenu>
                                          <DropdownMenuTrigger asChild>
                                            <Button variant="ghost" size="icon" className="h-7 w-7">
                                              <MoreHorizontal className="h-4 w-4" />
                                            </Button>
                                          </DropdownMenuTrigger>
                                          <DropdownMenuContent align="end">
                                            <DropdownMenuItem onClick={() => setBoreForDetails(bore)} className="flex items-center gap-2 cursor-pointer">
                                              <Eye className="h-4 w-4" /> View Details
                                            </DropdownMenuItem>
                                            <DropdownMenuItem onClick={() => setBoreToDelete(bore)} className="text-destructive flex items-center gap-2 cursor-pointer">
                                              <Trash2 className="h-4 w-4" /> Delete
                                            </DropdownMenuItem>
                                          </DropdownMenuContent>
                                        </DropdownMenu>
                                      </TableCell>
                                    )}
                                </TableRow>
                              )
                          })
                        ) : (
                          <TableRow>
                            <TableCell colSpan={role === 'owner' ? 7 : 6} className="text-center h-24">No bores match the current filters.</TableCell>
                          </TableRow>
                        )
                      ) : (
                          <>
                              {[...Array(3)].map((_, i) => (
                                  <TableRow key={i}>
                                      <TableCell><Skeleton className="h-4 w-16" /></TableCell>
                                      <TableCell><Skeleton className="h-4 w-12" /></TableCell>
                                      <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                                      <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                                      <TableCell><Skeleton className="h-4 w-20" /></TableCell>
                                      <TableCell><Skeleton className="h-4 w-14" /></TableCell>
                                      {role === 'owner' && <TableCell className="text-right"><Skeleton className="h-7 w-7 rounded-md" /></TableCell>}
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
      <AlertDialog open={!!boreToDelete} onOpenChange={() => setBoreToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the bore record and its related pipe usage history.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setBoreToDelete(null)}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

       <Dialog open={!!boreForDetails} onOpenChange={() => setBoreForDetails(null)}>
        <DialogContent className="sm:max-w-md">
            <DialogHeader>
                <DialogTitle>Bore Details: {boreForDetails?.boreNumber}</DialogTitle>
            </DialogHeader>
            {boreForDetails && (
                <div className="space-y-3 text-sm max-h-[70vh] overflow-y-auto pr-2">
                    <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Date:</span>
                        <span className="font-medium">{format(new Date(boreForDetails.date), "PPP")}</span>
                    </div>
                    <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Agent Name:</span>
                        <span className="font-medium">{boreForDetails.agentName}</span>
                    </div>
                    <Separator/>
                    <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Drilling:</span>
                        <span className="font-medium">{boreForDetails.totalFeet.toLocaleString('en-IN')} ft @ ₹{boreForDetails.pricePerFeet}/ft</span>
                    </div>

                    <div className="space-y-2">
                        <span className="text-muted-foreground">Pipes Used:</span>
                        {(boreForDetails.pipesUsed || []).length > 0 ? (
                             <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>Size</TableHead>
                                        <TableHead>Len</TableHead>
                                        <TableHead>Price/ft</TableHead>
                                        <TableHead className="text-right">Subtotal</TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {boreForDetails.pipesUsed.map((pipe, index) => (
                                        <TableRow key={`${pipe.size}-${index}`}>
                                            <TableCell>{pipe.size}"</TableCell>
                                            <TableCell>{pipe.length} ft</TableCell>
                                            <TableCell>₹{pipe.pricePerPipeFoot}</TableCell>
                                            <TableCell className="text-right">₹{(pipe.length * pipe.pricePerPipeFoot).toLocaleString('en-IN')}</TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>
                        ) : (
                            <p className="text-center font-medium py-2">No pipes were used for this bore.</p>
                        )}
                    </div>
                    <Separator/>
                    <div className="grid grid-cols-2 items-center font-medium">
                        <span className="text-muted-foreground">Total Bill:</span>
                        <span className="font-bold text-base">₹{boreForDetails.totalBill.toLocaleString('en-IN')}</span>
                    </div>
                    <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Amount Paid:</span>
                        <span className="font-medium">₹{getAmountPaid(boreForDetails).toLocaleString('en-IN')}</span>
                    </div>
                    <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Balance:</span>
                        <span className="font-bold text-base">₹{getBalanceAmount(boreForDetails).toLocaleString('en-IN')}</span>
                    </div>
                     <div className="grid grid-cols-2 items-center">
                        <span className="text-muted-foreground">Status:</span>
                        <span>
                            {getBalanceAmount(boreForDetails) <= 0 ? (
                                <Badge variant="success">Paid</Badge>
                            ) : (
                                <Badge variant="warning">Pending</Badge>
                            )}
                        </span>
                    </div>
                </div>
            )}
            <DialogFooter>
                <Button variant="secondary" onClick={() => setBoreForDetails(null)}>Close</Button>
            </DialogFooter>
        </DialogContent>
    </Dialog>

      <Dialog open={isAgentDialogOpen} onOpenChange={setIsAgentDialogOpen}>
        <DialogContent>
            <DialogHeader>
                <DialogTitle>{agentToEdit ? "Edit Agent" : "Manage Agents"}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
                <div className="space-y-2">
                    <Label htmlFor="agent-name-input">{agentToEdit ? "Edit Agent Name" : "Add New Agent"}</Label>
                    <div className="flex gap-2">
                        <Input id="agent-name-input" value={agentNameInput} onChange={e => setAgentNameInput(e.target.value)} />
                        <Button onClick={handleSaveAgent}>{agentToEdit ? "Save" : "Add"}</Button>
                        {agentToEdit && <Button variant="outline" onClick={() => { setAgentToEdit(null); setAgentNameInput(''); }}>Cancel</Button>}
                    </div>
                </div>

                <div className="space-y-2">
                    <Label>Existing Agents</Label>
                    <div className="max-h-60 overflow-y-auto space-y-2 rounded-sm border p-2">
                        {agents.length > 0 ? agents.map(agent => (
                            <div key={agent.id} className="flex items-center justify-between rounded-sm bg-muted/50 p-2">
                                <span className="text-sm font-medium">{agent.name}</span>
                                <div className="flex gap-1">
                                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => handleOpenAgentDialog(agent)}>
                                        <Edit className="h-4 w-4" />
                                    </Button>
                                    <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive" onClick={() => setAgentToDelete(agent)}>
                                        <Trash2 className="h-4 w-4" />
                                    </Button>
                                </div>
                            </div>
                        )) : <p className="text-sm text-muted-foreground text-center py-4">No agents added yet.</p>}
                    </div>
                </div>
            </div>
            <DialogFooter>
                <Button variant="secondary" onClick={() => setIsAgentDialogOpen(false)}>Close</Button>
            </DialogFooter>
        </DialogContent>
    </Dialog>

    <AlertDialog open={!!agentToDelete} onOpenChange={() => setAgentToDelete(null)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Are you sure?</AlertDialogTitle>
          <AlertDialogDescription>
            This action cannot be undone. You can only delete agents that are not assigned to any existing bores.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={() => setAgentToDelete(null)}>Cancel</AlertDialogCancel>
          <AlertDialogAction onClick={confirmDeleteAgent} className="bg-destructive hover:bg-destructive/90">Delete</AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>

    <Dialog open={isBalanceReportDialogOpen} onOpenChange={setIsBalanceReportDialogOpen}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Download Agent Balance Report</DialogTitle>
          <DialogDescription>
            Select an agent to download a PDF report of their bore balances.
          </DialogDescription>
        </DialogHeader>
        <div className="grid gap-4 py-4">
            <div className="space-y-2">
                <Label htmlFor="agent-report-select">Agent</Label>
                <Select value={selectedAgentForReport} onValueChange={setSelectedAgentForReport}>
                    <SelectTrigger id="agent-report-select">
                        <SelectValue placeholder="Select an agent" />
                    </SelectTrigger>
                    <SelectContent>
                        {agents.map((agent) => (
                            <SelectItem key={agent.id} value={agent.id}>
                                {agent.name}
                            </SelectItem>
                        ))}
                    </SelectContent>
                </Select>
            </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => { setIsBalanceReportDialogOpen(false); setSelectedAgentForReport(''); }}>Cancel</Button>
          <Button onClick={handleDownloadAgentBalanceReport} disabled={!selectedAgentForReport}>Download Report</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    </>
  );
}
