
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import type { ManagerData } from '@/lib/types';


export async function GET(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const manager = await prisma.manager.findUnique({
      where: { id: params.managerId },
      include: {
        workers: { include: { payments: true } },
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

    if (!manager) {
      return NextResponse.json({ error: 'Manager not found' }, { status: 404 });
    }

    const transformedManager = {
      id: manager.id,
      name: manager.name,
      email: manager.email,
      password: manager.password,
      data: {
        workers: manager.workers.map(w => ({
          ...w,
          amountPaid: w.payments.reduce((sum, p) => sum + p.amount, 0),
        })),
        bores: manager.bores,
        normalExpenses: manager.normalExpenses,
        labourPayments: manager.labourPayments,
        pipeLogs: manager.pipeLogs,
        dieselPurchases: manager.dieselPurchases,
        dieselUsage: manager.dieselUsage,
        agents: manager.agents,
        pipeStock: manager.pipeStock,
      } as ManagerData
    };
    
    return NextResponse.json(transformedManager);
  } catch (error) {
    console.error(`Error fetching manager ${params.managerId}:`, error);
    return NextResponse.json({ error: `Error fetching manager` }, { status: 500 });
  }
}


export async function PUT(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { name, email, password } = body;
    const data: { name: string; email: string; password?: string } = { name, email };
    if (password) {
      data.password = password;
    }
    const updatedManager = await prisma.manager.update({
      where: { id: params.managerId },
      data,
    });
    return NextResponse.json(updatedManager);
  } catch (error) {
    console.error(`Error updating manager ${params.managerId}:`, error);
    return NextResponse.json({ error: 'Error updating manager' }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: { managerId: string } }) {
  try {
    await prisma.manager.delete({
      where: { id: params.managerId },
    });
    return NextResponse.json({ message: 'Manager deleted successfully' });
  } catch (error) {
    console.error(`Error deleting manager ${params.managerId}:`, error);
    return NextResponse.json({ error: 'Error deleting manager' }, { status: 500 });
  }
}
