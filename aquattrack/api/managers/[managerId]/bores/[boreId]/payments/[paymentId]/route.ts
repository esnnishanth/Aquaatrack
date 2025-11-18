
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { paymentId: string } }) {
  try {
    await prisma.payment.delete({
      where: { id: params.paymentId },
    });
    return NextResponse.json({ message: 'Payment deleted successfully' });
  } catch (error) {
    console.error(`Error deleting payment ${params.paymentId}:`, error);
    return NextResponse.json({ error: 'Error deleting payment' }, { status: 500 });
  }
}
