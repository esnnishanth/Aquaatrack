
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { usageId: string } }) {
  try {
    await prisma.dieselUsage.delete({
      where: { id: params.usageId },
    });
    return NextResponse.json({ message: 'Diesel usage deleted successfully' });
  } catch (error) {
    console.error(`Error deleting diesel usage ${params.usageId}:`, error);
    return NextResponse.json({ error: 'Error deleting diesel usage' }, { status: 500 });
  }
}
