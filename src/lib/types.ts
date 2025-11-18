
export interface Worker {
  id: string;
  name: string;
  place: string;
  monthlySalary: number;
  monthsWorked: number;
  amountPaid: number;
}

export interface Payment {
  id: string;
  date: Date;
  amount: number;
}

export interface PipeEntry {
  size: number;
  length: number;
  pricePerPipeFoot: number;
}

export interface Bore {
  id:string;
  date: Date;
  boreNumber: string;
  totalFeet: number;
  pricePerFeet: number;
  pipesUsed: PipeEntry[];
  agentName: string;
  totalBill: number;
  payments: Payment[];
}

export interface NormalExpense {
  id:string;
  description: string;
  amount: number;
  date: Date;
  category?: string;
}

export interface LabourPayment {
  id: string;
  workerId: string;
  amount: number;
  date: Date;
}

export interface PipePurchase {
  id: string;
  pipesLoaded: number;
  cost: number;
  date: Date;
}

export interface DieselPurchase {
  id: string;
  liters: number;
  cost: number;
  date: Date;
}

export interface DieselUsage {
  id: string;
  litersUsed: number;
  purpose: string;
  date: Date;
}

export type Expense = NormalExpense | LabourPayment | PipePurchase | DieselPurchase;

export interface PipeLog {
  id: string;
  date: Date;
  type: 'Purchase' | 'Usage';
  quantity: number;
  diameter: number; // in inches, now required
  relatedBore?: string;
}

export interface PipeStockItem {
  id: string;
  size: number; // in inches
  quantity: number;
}

export interface Agent {
  id: string;
  name: string;
}

export interface ManagerData {
  workers: Worker[];
  bores: Bore[];
  normalExpenses: NormalExpense[];
  labourPayments: LabourPayment[];
  pipeLogs: PipeLog[];
  dieselPurchases: DieselPurchase[];
  dieselUsage: DieselUsage[];
  agents: Agent[];
  pipeStock: PipeStockItem[];
}

export interface Manager {
  id: string;
  name: string;
  email: string;
  password?: string;
  data: ManagerData;
}
