
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function DELETE(request: Request, { params }: { params: { managerId: string, logId: string } }) {
    try {
        const logToDelete = await prisma.pipeLog.findUnique({
            where: { id: params.logId }
        });

        if (!logToDelete) {
            return NextResponse.json({ error: 'Log not found' }, { status: 404 });
        }
        
        if(logToDelete.type !== 'Purchase' || !logToDelete.relatedBore?.includes('Withdrawal')) {
            return NextResponse.json({ error: 'Only withdrawal logs can be deleted this way.' }, { status: 400 });
        }

        await prisma.$transaction(async (tx) => {
            // Refund to godown
            const godownStock = await tx.pipeStockItem.findFirst({
                where: { size: logToDelete.diameter, managerId: null }
            });

            if (godownStock) {
                await tx.pipeStockItem.update({
                    where: { id: godownStock.id },
                    data: { quantity: { increment: logToDelete.quantity } }
                });
            } else {
                 await tx.pipeStockItem.create({
                    data: {
                        size: logToDelete.diameter,
                        quantity: logToDelete.quantity,
                        managerId: null
                    }
                });
            }
            
            // Deduct from manager
             const managerStock = await tx.pipeStockItem.findFirst({
                where: { size: logToDelete.diameter, managerId: params.managerId }
            });

            if(managerStock) {
                 await tx.pipeStockItem.update({
                    where: { id: managerStock.id },
                    data: { quantity: { decrement: logToDelete.quantity } }
                });
            }

            // Delete the log
            await tx.pipeLog.delete({ where: { id: params.logId } });
        });

        return NextResponse.json({ message: 'Pipe log deleted and stock refunded' });
    } catch (error) {
        console.error(`Error deleting pipe log ${params.logId}:`, error);
        return NextResponse.json({ error: 'Error deleting pipe log' }, { status: 500 });
    }
}
