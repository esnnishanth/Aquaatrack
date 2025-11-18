
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { ManagerData } from '@/lib/types';

export async function GET() {
  try {
    const managers = await prisma.manager.findMany({
      include: {
        workers: true,
        bores: { include: { payments: true, pipesUsed: true } },
        normalExpenses: true,
        labourPayments: true,
        pipeLogs: true,
        dieselPurchases: true,
        dieselUsage: true,
        agents: true,
        pipeStock: true,
      },
    });

    const transformedManagers = managers.map(manager => {
      const data: ManagerData = {
        workers: manager.workers,
        bores: manager.bores,
        normalExpenses: manager.normalExpenses,
        labourPayments: manager.labourPayments,
        pipeLogs: manager.pipeLogs,
        dieselPurchases: manager.dieselPurchases,
        dieselUsage: manager.dieselUsage,
        agents: manager.agents,
      };
      
      const pipeStock = manager.pipeStock.reduce((acc, item) => {
        acc[item.size] = (acc[item.size] || 0) + item.quantity;
        return acc;
      }, {} as Record<number, number>);

      // Combine manager data for the final object
      return {
        id: manager.id,
        name: manager.name,
        email: manager.email,
        password: manager.password,
        data: data,
      };
    });

    return NextResponse.json(transformedManagers);
  } catch (error) {
    console.error("Error fetching managers:", error);
    return NextResponse.json({ error: "Error fetching managers" }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { name, email, password } = body;
    const newManager = await prisma.manager.create({
      data: {
        name,
        email,
        password,
      },
    });
    return NextResponse.json(newManager);
  } catch (error) {
    console.error("Error creating manager:", error);
    return NextResponse.json({ error: "Error creating manager" }, { status: 500 });
  }
}
