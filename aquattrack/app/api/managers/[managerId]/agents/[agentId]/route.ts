
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PUT(request: Request, { params }: { params: { agentId: string } }) {
  try {
    const body = await request.json();
    const { name } = body;
    const updatedAgent = await prisma.agent.update({
      where: { id: params.agentId },
      data: { name },
    });
    return NextResponse.json(updatedAgent);
  } catch (error) {
    console.error(`Error updating agent ${params.agentId}:`, error);
    return NextResponse.json({ error: 'Error updating agent' }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: { agentId: string } }) {
  try {
    await prisma.agent.delete({
      where: { id: params.agentId },
    });
    return NextResponse.json({ message: 'Agent deleted successfully' });
  } catch (error) {
    console.error(`Error deleting agent ${params.agentId}:`, error);
    return NextResponse.json({ error: 'Error deleting agent' }, { status: 500 });
  }
}
