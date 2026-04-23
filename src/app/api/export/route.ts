import { auth } from "@/auth";
import { prisma } from "@/lib/prisma";
import { NextRequest } from "next/server";
import * as XLSX from "xlsx";

export async function GET(request: NextRequest) {
  const session = await auth();
  if (!session) {
    return Response.json({ error: "Unauthorized" }, { status: 401 });
  }

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

  const expenses = await prisma.expense.findMany({
    where,
    orderBy: { date: "asc" },
  });

  const statusLabel: Record<string, string> = {
    PENDING: "申請中",
    APPROVED: "承認済",
    REJECTED: "却下",
  };

  const rows = expenses.map((e) => ({
    申請日: e.createdAt.toLocaleDateString("ja-JP"),
    利用日: e.date.toLocaleDateString("ja-JP"),
    氏名: e.employeeName,
    稼働現場: e.workSite,
    出発地: e.from,
    目的地: e.to,
    交通手段: e.transport,
    "金額（円）": e.amount,
    目的備考: e.purpose ?? "",
    ステータス: statusLabel[e.status],
    管理者コメント: e.adminNote ?? "",
  }));

  const ws = XLSX.utils.json_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, "交通費");

  const buf = XLSX.write(wb, { type: "buffer", bookType: "xlsx" });

  const filename = month ? `交通費_${month}.xlsx` : "交通費.xlsx";

  return new Response(buf, {
    headers: {
      "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "Content-Disposition": `attachment; filename*=UTF-8''${encodeURIComponent(filename)}`,
    },
  });
}
