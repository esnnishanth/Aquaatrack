
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function PUT(request: Request, { params }: { params: { workerId: string } }) {
  try {
    const body = await request.json();
    const { name, place, monthlySalary, monthsWorked } = body;
    const updatedWorker = await prisma.worker.update({
      where: { id: params.workerId },
      data: {
        name,
        place,
        monthlySalary,
        monthsWorked,
      },
    });
    return NextResponse.json(updatedWorker);
  } catch (error) {
    console.error(`Error updating worker ${params.workerId}:`, error);
    return NextResponse.json({ error: 'Error updating worker' }, { status: 500 });
  }
}

export async function DELETE(request: Request, { params }: { params: { workerId: string } }) {
  try {
    // Need to also delete related labour payments before deleting the worker
    await prisma.$transaction([
      prisma.labourPayment.deleteMany({
        where: { workerId: params.workerId },
      }),
      prisma.worker.delete({
        where: { id: params.workerId },
      }),
    ]);
    return NextResponse.json({ message: 'Worker deleted successfully' });
  } catch (error) {
    console.error(`Error deleting worker ${params.workerId}:`, error);
    return NextResponse.json({ error: 'Error deleting worker' }, { status: 500 });
  }
}
