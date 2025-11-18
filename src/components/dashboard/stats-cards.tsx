
"use client"

import * as React from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Wallet, TrendingUp, Container, Calendar as CalendarIcon } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { format } from "date-fns"
import type { Bore, NormalExpense, LabourPayment } from "@/lib/types"
import { useMemo, useState, useEffect } from "react"
import { Skeleton } from "@/components/ui/skeleton"

export default function StatsCards({ bores, normalExpenses, labourPayments = [] }: { bores: Bore[]; normalExpenses: NormalExpense[]; labourPayments?: LabourPayment[] }) {
  const [isMounted, setIsMounted] = useState(false);
  const [date, setDate] = React.useState<Date>(new Date())

  useEffect(() => {
    setIsMounted(true);
  }, []);

  const { balance, monthlyBoreFeet, monthlyPipeLength } = useMemo(() => {
    const currentMonthBores = bores.filter(
      (bore) =>
        new Date(bore.date).getMonth() === date.getMonth() &&
        new Date(bore.date).getFullYear() === date.getFullYear()
    );

    const totalIncome = bores.flatMap(bore => bore.payments || []).reduce((acc, payment) => acc + payment.amount, 0);
    const totalNormalExpenses = (normalExpenses || []).reduce((acc, expense) => acc + expense.amount, 0);
    const totalLabourExpenses = (labourPayments || []).reduce((acc, payment) => acc + payment.amount, 0);
    const totalExpenses = totalNormalExpenses + totalLabourExpenses;
    const _balance = totalIncome - totalExpenses;

    const _monthlyBoreFeet = currentMonthBores.reduce((acc, bore) => acc + bore.totalFeet, 0);
    const _monthlyPipeLength = currentMonthBores.reduce((acc, bore) => {
      const pipesLength = (bore.pipesUsed || []).reduce((pipeAcc, pipe) => pipeAcc + pipe.length, 0);
      return acc + pipesLength;
    }, 0);

    return { balance: _balance, monthlyBoreFeet: _monthlyBoreFeet, monthlyPipeLength: _monthlyPipeLength };
  }, [bores, normalExpenses, labourPayments, date]);


  if (!isMounted) {
    return (
      <>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Balance</CardTitle>
            <Wallet className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-6 w-3/4 mb-1" />
            <Skeleton className="h-4 w-1/2" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Bore Feet</CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-6 w-3/4 mb-1" />
            <Skeleton className="h-4 w-1/2" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Pipe Length</CardTitle>
            <Container className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-6 w-3/4 mb-1" />
            <Skeleton className="h-4 w-1/2" />
          </CardContent>
        </Card>
      </>
    );
  }

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Balance</CardTitle>
          <Wallet className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold">₹{balance.toLocaleString('en-IN')}</div>
          <p className="text-xs text-muted-foreground">Available after all expenses</p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Bore Feet</CardTitle>
          <div className="flex items-center gap-2">
            <Popover>
              <PopoverTrigger asChild>
                <Button variant={"outline"} size="sm" className="h-7 gap-1 text-xs">
                  <CalendarIcon className="h-3.5 w-3.5" />
                  <span>{format(date, "MMM yyyy")}</span>
                </Button>
              </PopoverTrigger>
              <PopoverContent className="w-auto p-0">
                <Calendar
                  mode="single"
                  selected={date}
                  onSelect={(day) => day && setDate(day)}
                  initialFocus
                  captionLayout="dropdown-buttons"
                  fromYear={2020}
                  toYear={2030}
                />
              </PopoverContent>
            </Popover>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold">{monthlyBoreFeet.toLocaleString('en-IN')} ft</div>
          <p className="text-xs text-muted-foreground">Month of {format(date, "MMMM")}</p>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium">Total Pipe Length</CardTitle>
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground">{format(date, "MMMM")}</span>
            <Container className="h-4 w-4 text-muted-foreground" />
          </div>
        </CardHeader>
        <CardContent>
          <div className="text-lg font-bold">{monthlyPipeLength.toLocaleString('en-IN')} ft</div>
          <p className="text-xs text-muted-foreground">Corresponds to {Math.round(monthlyPipeLength / 20)} pipes</p>
        </CardContent>
      </Card>
    </>
  )
}
