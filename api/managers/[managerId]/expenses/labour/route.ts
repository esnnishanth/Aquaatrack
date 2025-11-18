
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { workerId, amount, date } = body;

    const newPayment = await prisma.labourPayment.create({
        data: {
            workerId,
            amount,
            date: new Date(date),
            managerId: params.managerId,
        }
    });
    return NextResponse.json(newPayment);
  } catch (error) {
    console.error("Error creating labour payment:", error);
    return NextResponse.json({ error: "Error creating labour payment" }, { status: 500 });
  }
}
