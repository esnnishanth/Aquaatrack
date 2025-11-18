
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

export async function GET() {
  try {
    const stock = await prisma.pipeStockItem.findMany({
      where: { managerId: null },
      orderBy: { size: 'asc' },
    });
    return NextResponse.json(stock);
  } catch (error) {
    console.error('Error fetching godown pipe stock:', error);
    return NextResponse.json({ error: 'Error fetching godown pipe stock' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { size, quantity } = body;

    const existingStock = await prisma.pipeStockItem.findFirst({
        where: { size: size, managerId: null }
    });

    if (existingStock) {
        const updatedStock = await prisma.pipeStockItem.update({
            where: { id: existingStock.id },
            data: { quantity: { increment: quantity } }
        });
        return NextResponse.json(updatedStock);
    } else {
        const newStock = await prisma.pipeStockItem.create({
            data: {
                size: size,
                quantity: quantity,
                managerId: null
            }
        });
        return NextResponse.json(newStock);
    }
  } catch (error) {
    console.error('Error creating/updating godown pipe stock:', error);
    return NextResponse.json({ error: `Error creating/updating godown pipe stock: ${error}` }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  try {
    const body = await request.json();
    const { id, quantity } = body;

    if (!id) {
        return NextResponse.json({ error: 'Stock item ID is required' }, { status: 400 });
    }

    const updatedStock = await prisma.pipeStockItem.update({
        where: { id: id },
        data: { quantity: quantity }
    });
    return NextResponse.json(updatedStock);
  } catch (error) {
    console.error('Error updating godown pipe stock:', error);
    return NextResponse.json({ error: 'Error updating godown pipe stock' }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
    try {
        const body = await request.json();
        const { id } = body;

        if (!id) {
            return NextResponse.json({ error: 'Stock item ID is required' }, { status: 400 });
        }

        await prisma.pipeStockItem.delete({
            where: { id: id }
        });
        return NextResponse.json({ message: 'Stock item deleted successfully' });
    } catch (error) {
        console.error('Error deleting godown pipe stock:', error);
        return NextResponse.json({ error: 'Error deleting godown pipe stock item' }, { status: 500 });
    }
}
