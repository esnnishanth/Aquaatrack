
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { description, amount, date } = body;
    const newExpense = await prisma.normalExpense.create({
      data: {
        description,
        amount,
        date: new Date(date),
        managerId: params.managerId,
      },
    });
    return NextResponse.json(newExpense);
  } catch (error) {
    console.error("Error creating normal expense:", error);
    return NextResponse.json({ error: "Error creating normal expense" }, { status: 500 });
  }
}
