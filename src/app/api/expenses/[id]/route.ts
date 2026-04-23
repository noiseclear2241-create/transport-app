import { auth } from "@/auth";
import { prisma } from "@/lib/prisma";
import { NextRequest } from "next/server";

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const session = await auth();
  if (!session) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const body = await request.json();
  const { status, adminNote } = body;

  if (!["APPROVED", "REJECTED", "PENDING"].includes(status)) {
    return Response.json({ error: "無効なステータスです" }, { status: 400 });
  }

  const expense = await prisma.expense.update({
    where: { id },
    data: { status, adminNote: adminNote || null },
  });

  return Response.json(expense);
}
