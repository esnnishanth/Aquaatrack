
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
    try {
        const body = await request.json();
        const { size, quantity } = body;

        const result = await prisma.$transaction(async (tx) => {
            // Check godown stock
            const godownStock = await tx.pipeStockItem.findFirst({
                where: { size: size, managerId: null }
            });

            if (!godownStock || godownStock.quantity < quantity) {
                throw new Error('Insufficient stock in godown.');
            }

            // Decrement godown stock
            await tx.pipeStockItem.update({
                where: { id: godownStock.id },
                data: { quantity: { decrement: quantity } }
            });

            // Increment manager stock
            const managerStock = await tx.pipeStockItem.findFirst({
                where: { size: size, managerId: params.managerId }
            });

            if (managerStock) {
                await tx.pipeStockItem.update({
                    where: { id: managerStock.id },
                    data: { quantity: { increment: quantity } }
                });
            } else {
                await tx.pipeStockItem.create({
                    data: {
                        size: size,
                        quantity: quantity,
                        managerId: params.managerId
                    }
                });
            }

            // Create a pipe log
            const logEntry = await tx.pipeLog.create({
                data: {
                    date: new Date(),
                    type: 'Purchase',
                    quantity: quantity,
                    diameter: size,
                    relatedBore: 'Withdrawal from Godown',
                    managerId: params.managerId,
                }
            });

            return logEntry;
        });

        return NextResponse.json(result);
    } catch (error: any) {
        console.error("Error withdrawing pipes:", error);
        return NextResponse.json({ error: error.message || "Error withdrawing pipes" }, { status: 500 });
    }
}
