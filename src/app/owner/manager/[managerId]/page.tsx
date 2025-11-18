
'use client';

import { notFound, useParams } from "next/navigation";
import { useState, useEffect } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import StatsCards from "@/components/dashboard/stats-cards";
import LabourTab from "@/components/dashboard/labour-tab";
import BoreTab from "@/components/dashboard/bore-tab";
import IncomeTab from "@/components/dashboard/income-tab";
import ExpenseTab from "@/components/dashboard/expense-tab";
import PipeInventoryTab from "@/components/dashboard/pipe-inventory-tab";
import DieselTab from "@/components/dashboard/diesel-tab";
import ReportDownloader from "@/components/dashboard/report-downloader";
import { Briefcase, Fuel, Hammer, Droplet, Wallet, Wrench } from "lucide-react";
import type { Manager, Bore, Worker, PipeLog, DieselPurchase, NormalExpense, DieselUsage, LabourPayment, Agent } from "@/lib/types";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import React from "react";
import { Skeleton } from "@/components/ui/skeleton";

export default function ManagerDetailsPage() {
  const params = useParams();
  const managerId = params.managerId as string;
  const [managerData, setManagerData] = useState<Manager | null>(null);

  const [isLoading, setIsLoading] = useState(true);

  // We need a way to trigger re-fetches in child components when data changes.
  // A simple counter that we increment is an easy way to do this.
  const [updateTrigger, setUpdateTrigger] = useState(0);
  const forceUpdate = () => setUpdateTrigger(c => c + 1);

  useEffect(() => {
    if (managerId) {
      const fetchManagerData = async () => {
        setIsLoading(true);
        try {
          const res = await fetch(`/api/managers/${managerId}`);
          if (!res.ok) {
            throw new Error("Failed to fetch manager data");
          }
          const data = await res.json();
          setManagerData(data);
        } catch (error) {
          console.error(error);
          setManagerData(null); // Set to null on error
        } finally {
          setIsLoading(false);
        }
      };
      fetchManagerData();
    }
  }, [managerId, updateTrigger]);


  if (isLoading) {
    return (
        <div className="p-4 space-y-4">
            <Skeleton className="h-8 w-1/2" />
            <Skeleton className="h-6 w-1/3" />
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Skeleton className="h-24 w-full" />
                <Skeleton className="h-24 w-full" />
                <Skeleton className="h-24 w-full" />
                <Skeleton className="h-24 w-full" />
            </div>
            <Skeleton className="h-10 w-full" />
            <Skeleton className="h-96 w-full" />
        </div>
    )
  }

  if (!managerData) {
    notFound();
  }
  
  return (
    <div className="p-2 sm:p-4 space-y-4">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2">
        <div>
          <h1 className="text-xl font-bold font-headline">{managerData.name}'s Dashboard</h1>
          <p className="text-xs text-muted-foreground">Overview of {managerData.name}'s operations.</p>
        </div>
        <Button variant="outline" asChild size="sm" className="w-full sm:w-auto">
            <Link href="/owner/dashboard">
                <ArrowLeft className="mr-2 h-4 w-4"/>
                Back to Managers
            </Link>
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatsCards 
          bores={managerData.data.bores}
          normalExpenses={managerData.data.normalExpenses}
          labourPayments={managerData.data.labourPayments}
        />
        <ReportDownloader managerName={managerData.name} data={managerData.data} />
      </div>

      <Tabs defaultValue="labour" className="w-full">
        <TabsList className="grid w-full grid-cols-2 sm:grid-cols-3 md:grid-cols-6 h-auto">
          <TabsTrigger value="labour"><Briefcase className="w-4 h-4 mr-2"/>Labour</TabsTrigger>
          <TabsTrigger value="bore"><Droplet className="w-4 h-4 mr-2"/>Bore</TabsTrigger>
          <TabsTrigger value="income"><Wallet className="w-4 h-4 mr-2"/>Income</TabsTrigger>
          <TabsTrigger value="expense"><Wrench className="w-4 h-4 mr-2"/>Expense</TabsTrigger>
          <TabsTrigger value="pipe"><Hammer className="w-4 h-4 mr-2"/>Pipe</TabsTrigger>
          <TabsTrigger value="diesel"><Fuel className="w-4 h-4 mr-2"/>Diesel</TabsTrigger>
        </TabsList>
        <TabsContent value="labour" className="mt-4">
          <LabourTab 
            workers={managerData.data.workers} 
            managerName={managerData.name}
            labourPayments={managerData.data.labourPayments}
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="bore" className="mt-4">
          <BoreTab
            role="owner"
            bores={managerData.data.bores} 
            pipeLogs={managerData.data.pipeLogs}
            agents={managerData.data.agents || []}
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="income" className="mt-4">
          <IncomeTab
            role="owner"
            bores={managerData.data.bores} 
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="expense" className="mt-4">
          <ExpenseTab
            role="owner"
            workers={managerData.data.workers} 
            normalExpenses={managerData.data.normalExpenses}
            labourPayments={managerData.data.labourPayments || []}
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="pipe" className="mt-4">
          <PipeInventoryTab
            role="owner"
            pipeLogs={managerData.data.pipeLogs} 
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="diesel" className="mt-4">
          <DieselTab 
            role="owner"
            dieselPurchases={managerData.data.dieselPurchases} 
            dieselUsage={managerData.data.dieselUsage}
            managerId={managerId}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
