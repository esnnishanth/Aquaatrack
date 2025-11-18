
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { name, place, monthlySalary, monthsWorked } = body;
    const newWorker = await prisma.worker.create({
      data: {
        name,
        place,
        monthlySalary,
        monthsWorked,
        managerId: params.managerId,
      },
    });
    return NextResponse.json(newWorker);
  } catch (error) {
    console.error("Error creating worker:", error);
    return NextResponse.json({ error: "Error creating worker" }, { status: 500 });
  }
}
