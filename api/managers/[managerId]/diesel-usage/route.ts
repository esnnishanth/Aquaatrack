
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { litersUsed, purpose } = body;
    const newUsage = await prisma.dieselUsage.create({
      data: {
        litersUsed,
        purpose,
        date: new Date(),
        managerId: params.managerId,
      },
    });
    return NextResponse.json(newUsage);
  } catch (error) {
    console.error("Error logging diesel usage:", error);
    return NextResponse.json({ error: "Error logging diesel usage" }, { status: 500 });
  }
}
