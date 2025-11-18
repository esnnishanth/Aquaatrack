'use client';

import React, { useState } from 'react';
import { format, isSameMonth } from 'date-fns';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CalendarIcon, Download } from 'lucide-react';
import { cn } from '@/lib/utils';
import type { ManagerData } from '@/lib/types';

interface ReportDownloaderProps {
  managerName: string;
  data: ManagerData;
}

export default function ReportDownloader({ managerName, data }: ReportDownloaderProps) {
  const [date, setDate] = useState<Date>(new Date());

  const handleDownload = () => {
    const selectedMonth = date;
    const doc = new jsPDF();
    const primaryColor = [142, 25, 61]; // Burgundy color

    // --- Filter data for the selected month ---
    const monthlyBorePayments = data.bores
      .flatMap(bore =>
        (bore.payments || [])
          .filter(p => isSameMonth(new Date(p.date), selectedMonth))
          .map(p => ({
            date: format(new Date(p.date), 'yyyy-MM-dd'),
            boreNumber: bore.boreNumber,
            amount: p.amount,
          }))
      );
    
    const monthlyNormalExpenses = data.normalExpenses.filter(e => isSameMonth(new Date(e.date), selectedMonth));
    const monthlyPipeLogs = data.pipeLogs.filter(l => isSameMonth(new Date(l.date), selectedMonth));
    const monthlyDieselUsage = data.dieselUsage.filter(u => isSameMonth(new Date(u.date), selectedMonth));
    const monthlyLabourPayments = (data.labourPayments || []).filter(p => isSameMonth(new Date(p.date), selectedMonth));

    // --- Calculate Summary ---
    const totalIncome = monthlyBorePayments.reduce((acc, p) => acc + p.amount, 0);
    const totalNormalExpenses = monthlyNormalExpenses.reduce((acc, e) => acc + e.amount, 0);
    const totalLabourExpenses = monthlyLabourPayments.reduce((acc, p) => acc + p.amount, 0);
    const totalExpenses = totalNormalExpenses + totalLabourExpenses; // Normal expenses now include pipe/diesel purchases
    const profitLoss = totalIncome - totalExpenses;

    // --- Build PDF Content ---
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
    doc.text(`AquaTrack Report`, 14, 22);

    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100);
    doc.text(`For: ${managerName}`, 14, 30);
    doc.text(`Month: ${format(selectedMonth, 'MMMM yyyy')}`, 14, 36);


    autoTable(doc, {
      startY: 45,
      head: [['Metric', 'Amount (INR)']],
      body: [
        ['Total Income', `₹${totalIncome.toLocaleString('en-IN')}`],
        ['Total Expenses', `₹${totalExpenses.toLocaleString('en-IN')}`],
        ['Profit / Loss', {
            content: `₹${profitLoss.toLocaleString('en-IN')}`,
            styles: {
                textColor: profitLoss >= 0 ? [0, 100, 0] : [255, 0, 0] // Green for profit, red for loss
            }
        }],
      ],
      theme: 'striped',
      headStyles: { fillColor: primaryColor },
      bodyStyles: { fontStyle: 'bold' },
      styles: { cellPadding: 2, fontSize: 10 },
    });

    const allExpenses = [
        ...monthlyNormalExpenses.map(e => ({ date: format(new Date(e.date), 'yyyy-MM-dd'), category: 'Normal Expense', description: e.description, amount: e.amount })),
        ...monthlyLabourPayments.map(p => {
          const workerName = (data.workers || []).find(w => w.id === p.workerId)?.name || 'Unknown Worker';
          return { date: format(new Date(p.date), 'yyyy-MM-dd'), category: 'Labour Payment', description: `Payment to ${workerName}`, amount: p.amount };
        }),
    ].sort((a,b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    
    let lastY = (doc as any).lastAutoTable.finalY || 35;
    
    const addPageHeader = (title: string, data: any) => {
        doc.setFontSize(14);
        doc.setFont('helvetica', 'bold');
        doc.setTextColor(40);
        doc.text(title, 14, data.cursor.y - 5);
    }

    if (monthlyBorePayments.length > 0) {
      autoTable(doc, {
        startY: lastY + 10,
        head: [['Date', 'Bore Number', 'Amount Received (INR)']],
        body: monthlyBorePayments.map(p => [p.date, p.boreNumber, `₹${p.amount.toLocaleString('en-IN')}`]),
        didDrawPage: (data) => addPageHeader('Income Details', data),
        headStyles: { fillColor: primaryColor },
        styles: { cellPadding: 2, fontSize: 9 },
      });
      lastY = (doc as any).lastAutoTable.finalY;
    }

    if (allExpenses.length > 0) {
        autoTable(doc, {
            startY: lastY + 10,
            head: [['Date', 'Category', 'Description', 'Amount (INR)']],
            body: allExpenses.map(e => [e.date, e.category, e.description, `₹${e.amount.toLocaleString('en-IN')}`]),
            didDrawPage: (data) => addPageHeader('Expense Details', data),
            headStyles: { fillColor: primaryColor },
            styles: { cellPadding: 2, fontSize: 9 },
        });
        lastY = (doc as any).lastAutoTable.finalY;
    }

     if (monthlyPipeLogs.length > 0) {
        autoTable(doc, {
            startY: lastY + 10,
            head: [['Date', 'Type', 'Quantity', 'Diameter', 'Related Info']],
            body: monthlyPipeLogs.map(l => [format(new Date(l.date), 'yyyy-MM-dd'), l.type, l.quantity, `${l.diameter}"`, l.relatedBore || 'N/A']),
            didDrawPage: (data) => addPageHeader('Pipe Inventory Log', data),
            headStyles: { fillColor: primaryColor },
            styles: { cellPadding: 2, fontSize: 9 },
        });
        lastY = (doc as any).lastAutoTable.finalY;
    }
    
     if (monthlyDieselUsage.length > 0) {
        autoTable(doc, {
            startY: lastY + 10,
            head: [['Date', 'Liters Used', 'Purpose']],
            body: monthlyDieselUsage.map(u => [format(new Date(u.date), 'yyyy-MM-dd'), u.litersUsed, u.purpose]),
            didDrawPage: (data) => addPageHeader('Diesel Usage Log', data),
            headStyles: { fillColor: primaryColor },
            styles: { cellPadding: 2, fontSize: 9 },
        });
        lastY = (doc as any).lastAutoTable.finalY;
    }

    // Add footer with page numbers
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


    // --- Trigger Download ---
    doc.save(`report_${managerName.replace(' ', '_')}_${format(selectedMonth, 'yyyy_MM')}.pdf`);
  };

  return (
    <Card>
      <CardHeader className="p-3">
        <CardTitle className="font-headline text-base flex items-center gap-2"><Download/>Monthly Report</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col sm:flex-row items-center gap-2 bg-muted p-2 rounded-lg">
        <Popover>
          <PopoverTrigger asChild>
            <Button
              variant={"outline"}
              className={cn(
                "w-full sm:w-[220px] justify-start text-left font-normal bg-background",
                !date && "text-muted-foreground"
              )}
            >
              <CalendarIcon className="mr-2 h-4 w-4" />
              {date ? format(date, "MMMM yyyy") : <span>Pick a month</span>}
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-auto p-0">
            <Calendar
              mode="single"
              selected={date}
              onSelect={(day) => day && setDate(day)}
              initialFocus
              captionLayout="dropdown-buttons"
              fromYear={2020}
              toYear={2030}
            />
          </PopoverContent>
        </Popover>
        <Button onClick={handleDownload} className="w-full sm:w-auto text-xs" size="sm">
          <Download className="mr-2 h-4 w-4" />
          Download
        </Button>
      </CardContent>
    </Card>
  );
}
