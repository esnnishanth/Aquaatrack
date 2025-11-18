
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { liters, cost, date } = body;

    const result = await prisma.$transaction(async (tx) => {
        // Record the purchase as a normal expense
        const expense = await tx.normalExpense.create({
            data: {
                description: `Diesel Purchase: ${liters}L`,
                amount: cost,
                date: new Date(date),
                managerId: params.managerId,
            }
        });

        // Add to the diesel purchase table for stock tracking
        const purchase = await tx.dieselPurchase.create({
            data: {
                liters,
                cost,
                date: new Date(date),
                managerId: params.managerId,
            }
        });

        return { expense, purchase };
    });

    return NextResponse.json(result);
  } catch (error) {
    console.error("Error creating diesel purchase expense:", error);
    return NextResponse.json({ error: "Error creating diesel purchase expense" }, { status: 500 });
  }
}
