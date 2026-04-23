import { prisma } from "@/lib/prisma";
import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const month = searchParams.get("month");
  const name = searchParams.get("name");
  const workSite = searchParams.get("workSite");

  const where: Record<string, unknown> = {};

  if (month) {
    const [year, m] = month.split("-").map(Number);
    const start = new Date(year, m - 1, 1);
    const end = new Date(year, m, 1);
    where.date = { gte: start, lt: end };
  }

  if (name) {
    where.employeeName = { contains: name };
  }

  if (workSite) {
    where.workSite = { contains: workSite };
  }

  try {
    const expenses = await prisma.expense.findMany({
      where,
      orderBy: { date: "desc" },
    });
    return Response.json(expenses);
  } catch (e) {
    const err = e as Error & { code?: string; message?: string };
    console.error("GET /api/expenses error:", err.code, err.message);
    return Response.json({ error: err.message, code: err.code }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const { employeeName, workSite, date, from, to, transport, amount, purpose } = body;

  if (!employeeName || !workSite || !date || !from || !to || !transport || !amount) {
    return Response.json({ error: "必須項目が不足しています" }, { status: 400 });
  }

  const expense = await prisma.expense.create({
    data: {
      employeeName,
      workSite,
      date: new Date(date),
      from,
      to,
      transport,
      amount: Number(amount),
      purpose: purpose || null,
    },
  });

  return Response.json(expense, { status: 201 });
}
