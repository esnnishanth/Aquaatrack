
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
    try {
        const body = await request.json();
        const { date, boreNumber, totalFeet, pricePerFeet, pipesUsed, agentName, totalBill, initialPayment, pipeLogs } = body;

        const result = await prisma.$transaction(async (tx) => {
            const newBore = await tx.bore.create({
                data: {
                    date: new Date(date),
                    boreNumber,
                    totalFeet,
                    pricePerFeet,
                    agentName,
                    totalBill,
                    managerId: params.managerId,
                    pipesUsed: {
                        create: pipesUsed,
                    },
                },
            });

            if (initialPayment > 0) {
                await tx.payment.create({
                    data: {
                        date: new Date(date),
                        amount: initialPayment,
                        boreId: newBore.id,
                    },
                });
            }

            for (const log of pipeLogs) {
                await tx.pipeLog.create({
                    data: {
                        date: new Date(),
                        type: 'Usage',
                        quantity: log.quantity,
                        diameter: log.diameter,
                        relatedBore: newBore.boreNumber,
                        managerId: params.managerId,
                    },
                });

                const managerStock = await tx.pipeStockItem.findFirst({
                    where: { size: log.diameter, managerId: params.managerId }
                });

                if (managerStock) {
                    await tx.pipeStockItem.update({
                        where: { id: managerStock.id },
                        data: { quantity: managerStock.quantity - log.quantity }
                    });
                }
            }
            return newBore;
        });

        return NextResponse.json(result);
    } catch (error) {
        console.error("Error creating bore:", error);
        return NextResponse.json({ error: "Error creating bore" }, { status: 500 });
    }
}
