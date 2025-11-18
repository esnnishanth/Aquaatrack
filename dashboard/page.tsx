
'use client';

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import StatsCards from "@/components/dashboard/stats-cards";
import BoreTab from "@/components/dashboard/bore-tab";
import IncomeTab from "@/components/dashboard/income-tab";
import ExpenseTab from "@/components/dashboard/expense-tab";
import PipeInventoryTab from "@/components/dashboard/pipe-inventory-tab";
import DieselTab from "@/components/dashboard/diesel-tab";
import ReportDownloader from "@/components/dashboard/report-downloader";
import { Fuel, Hammer, Droplet, Wallet, Wrench, Briefcase } from "lucide-react";
import { useManager } from '@/contexts/manager-context';
import LabourTab from "@/components/dashboard/labour-tab";

export default function DashboardPage() {
  const { manager, forceUpdate } = useManager();

  // The provider ensures manager is not null here, so we can assert with !
  const managerData = manager!;

  return (
    <div className="p-2 sm:p-4 space-y-4">
      <div>
        <h1 className="text-xl font-bold font-headline">Manager Dashboard</h1>
        <p className="text-muted-foreground text-xs">Overview of your borewell business operations.</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatsCards 
          bores={managerData.data.bores} 
          normalExpenses={managerData.data.normalExpenses}
          labourPayments={managerData.data.labourPayments || []}
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
            workers={managerData.data.workers || []}
            managerName={managerData.name}
            labourPayments={managerData.data.labourPayments || []}
            managerId={managerData.id}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="bore" className="mt-4">
          <BoreTab
            role="manager" 
            bores={managerData.data.bores} 
            pipeLogs={managerData.data.pipeLogs}
            agents={managerData.data.agents || []}
            managerId={managerData.id}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="income" className="mt-4">
          <IncomeTab role="manager" bores={managerData.data.bores} managerId={managerData.id} onDataUpdate={forceUpdate} />
        </TabsContent>
        <TabsContent value="expense" className="mt-4">
          <ExpenseTab 
            role="manager"
            workers={managerData.data.workers || []}
            normalExpenses={managerData.data.normalExpenses}
            labourPayments={managerData.data.labourPayments || []}
            managerId={managerData.id}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
        <TabsContent value="pipe" className="mt-4">
          <PipeInventoryTab
            role="manager"
            pipeLogs={managerData.data.pipeLogs} 
            managerId={managerData.id}
            onDataUpdate={forceUpdate}
            />
        </TabsContent>
        <TabsContent value="diesel" className="mt-4">
          <DieselTab
            role="manager" 
            dieselPurchases={managerData.data.dieselPurchases} 
            dieselUsage={managerData.data.dieselUsage}
            managerId={managerData.id}
            onDataUpdate={forceUpdate}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
