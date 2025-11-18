
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { managerId: string, boreId: string } }) {
    try {
        const bore = await prisma.bore.findUnique({
            where: { id: params.boreId },
            include: { pipesUsed: true },
        });

        if (!bore) {
            return NextResponse.json({ error: 'Bore not found' }, { status: 404 });
        }

        const pipeUsageLogs = await prisma.pipeLog.findMany({
            where: { relatedBore: bore.boreNumber, managerId: params.managerId }
        });

        await prisma.$transaction(async (tx) => {
            // Delete payments, pipe entries, and the bore itself
            await tx.payment.deleteMany({ where: { boreId: params.boreId } });
            await tx.pipeEntry.deleteMany({ where: { boreId: params.boreId } });
            await tx.bore.delete({ where: { id: params.boreId } });
            
            // Refund pipe stock
            for (const log of pipeUsageLogs) {
                 const managerStock = await tx.pipeStockItem.findFirst({
                    where: { size: log.diameter, managerId: params.managerId }
                });
                if(managerStock) {
                    await tx.pipeStockItem.update({
                        where: { id: managerStock.id },
                        data: { quantity: { increment: log.quantity } }
                    });
                }
            }

            // Delete the usage logs
            await tx.pipeLog.deleteMany({
                where: { relatedBore: bore.boreNumber, managerId: params.managerId }
            });
        });

        return NextResponse.json({ message: 'Bore deleted successfully' });
    } catch (error) {
        console.error(`Error deleting bore ${params.boreId}:`, error);
        return NextResponse.json({ error: 'Error deleting bore' }, { status: 500 });
    }
}
