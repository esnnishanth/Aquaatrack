
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { boreId: string } }) {
  try {
    const body = await request.json();
    const { amount, date } = body;
    const newPayment = await prisma.payment.create({
      data: {
        amount,
        date: new Date(date),
        boreId: params.boreId,
      },
    });
    return NextResponse.json(newPayment);
  } catch (error) {
    console.error("Error creating payment:", error);
    return NextResponse.json({ error: "Error creating payment" }, { status: 500 });
  }
}
