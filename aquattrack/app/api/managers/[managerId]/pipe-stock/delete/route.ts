
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function POST(request: Request, { params }: { params: { managerId: string } }) {
  try {
    const body = await request.json();
    const { size } = body;

    const stockItem = await prisma.pipeStockItem.findFirst({
        where: { size: size, managerId: params.managerId }
    });
    
    if (!stockItem) {
      return NextResponse.json({ error: 'Stock item not found for this manager.' }, { status: 404 });
    }

    if(stockItem.quantity > 0) {
        await prisma.pipeLog.create({
            data: {
                date: new Date(),
                type: 'Usage',
                quantity: stockItem.quantity,
                diameter: size,
                relatedBore: 'Stock Deletion',
                managerId: params.managerId
            }
        });
    }

    await prisma.pipeStockItem.delete({
        where: { id: stockItem.id }
    });
    
    return NextResponse.json({ message: 'Stock item deleted and logged.' });

  } catch (error) {
    console.error("Error deleting pipe stock item:", error);
    return NextResponse.json({ error: 'Error deleting pipe stock item' }, { status: 500 });
  }
}
