
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { size, newQuantity } = body;

    const currentStock = await prisma.pipeStockItem.findFirst({
        where: { size: size, managerId: params.managerId }
    });

    if (!currentStock) {
        return NextResponse.json({ error: 'Stock for this pipe size not found' }, { status: 404 });
    }

    const difference = currentStock.quantity - newQuantity;
    
    if (difference < 0) {
      return NextResponse.json({ error: "Cannot increase stock via adjustment. Use 'Withdraw from Godown'." }, { status: 400 });
    }

    if (difference > 0) {
       await prisma.$transaction([
            prisma.pipeStockItem.update({
                where: { id: currentStock.id },
                data: { quantity: newQuantity }
            }),
            prisma.pipeLog.create({
                data: {
                    date: new Date(),
                    type: 'Usage',
                    quantity: difference,
                    diameter: size,
                    relatedBore: 'Stock Adjustment',
                    managerId: params.managerId
                }
            })
        ]);
    }
    
    return NextResponse.json({ message: 'Stock adjusted successfully' });

  } catch (error) {
    console.error("Error adjusting pipe stock:", error);
    return NextResponse.json({ error: 'Error adjusting pipe stock' }, { status: 500 });
  }
}
