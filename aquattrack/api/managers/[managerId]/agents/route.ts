
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { name } = body;
    const newAgent = await prisma.agent.create({
      data: {
        name,
        managerId: params.managerId,
      },
    });
    return NextResponse.json(newAgent);
  } catch (error) {
    console.error("Error creating agent:", error);
    return NextResponse.json({ error: "Error creating agent" }, { status: 500 });
  }
}
