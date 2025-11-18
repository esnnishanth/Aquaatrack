
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { expenseId: string } }) {
  try {
    await prisma.normalExpense.delete({
      where: { id: params.expenseId },
    });
    return NextResponse.json({ message: 'Normal expense deleted successfully' });
  } catch (error) {
    console.error(`Error deleting normal expense ${params.expenseId}:`, error);
    return NextResponse.json({ error: 'Error deleting normal expense' }, { status: 500 });
  }
}
