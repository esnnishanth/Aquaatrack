
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { paymentId: string } }) {
    try {
        await prisma.labourPayment.delete({
            where: { id: params.paymentId }
        });
        return NextResponse.json({ message: 'Labour payment deleted successfully' });
    } catch (error) {
        console.error(`Error deleting labour payment ${params.paymentId}:`, error);
        return NextResponse.json({ error: 'Error deleting labour payment' }, { status: 500 });
    }
}
