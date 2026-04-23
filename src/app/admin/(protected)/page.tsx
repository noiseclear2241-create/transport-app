"use client";

import { useEffect, useState, useCallback } from "react";
import StatusBadge from "@/components/StatusBadge";

type Status = "PENDING" | "APPROVED" | "REJECTED";

interface Expense {
  id: string;
  employeeName: string;
  workSite: string;
  date: string;
  from: string;
  to: string;
  transport: string;
  amount: number;
  purpose: string | null;
  status: Status;
  adminNote: string | null;
  createdAt: string;
}

interface ActionModal {
  expense: Expense;
  nextStatus: "APPROVED" | "REJECTED";
}

export default function AdminDashboardPage() {
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ month: "", name: "", workSite: "" });
  const [modal, setModal] = useState<ActionModal | null>(null);
  const [adminNote, setAdminNote] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  const fetchExpenses = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams();
    if (filters.month) params.set("month", filters.month);
    if (filters.name) params.set("name", filters.name);
    if (filters.workSite) params.set("workSite", filters.workSite);

    const res = await fetch(`/api/expenses?${params.toString()}`);
    const data = await res.json();
    setExpenses(data);
    setLoading(false);
  }, [filters]);

  useEffect(() => {
    fetchExpenses();
  }, [fetchExpenses]);

  const handleAction = async () => {
    if (!modal) return;
    setActionLoading(true);

    await fetch(`/api/expenses/${modal.expense.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status: modal.nextStatus, adminNote }),
    });

    setModal(null);
    setAdminNote("");
    setActionLoading(false);
    fetchExpenses();
  };

  const handleExport = () => {
    const params = new URLSearchParams();
    if (filters.month) params.set("month", filters.month);
    if (filters.name) params.set("name", filters.name);
    if (filters.workSite) params.set("workSite", filters.workSite);
    window.location.href = `/api/export?${params.toString()}`;
  };

  const total = expenses.reduce((sum, e) => sum + e.amount, 0);
  const approved = expenses.filter((e) => e.status === "APPROVED").reduce((sum, e) => sum + e.amount, 0);

  const formatDate = (dateStr: string) =>
    new Date(dateStr).toLocaleDateString("ja-JP", { year: "numeric", month: "2-digit", day: "2-digit" });

  const formatAmount = (n: number) => n.toLocaleString("ja-JP") + "円";

  return (
    <div className="space-y-6">
      {/* フィルター */}
      <div className="bg-white rounded-xl border border-gray-200 p-5">
        <h2 className="text-sm font-semibold text-gray-700 mb-4">絞り込み</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <label className="block text-xs text-gray-500 mb-1">月</label>
            <input
              type="month"
              value={filters.month}
              onChange={(e) => setFilters({ ...filters, month: e.target.value })}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">氏名</label>
            <input
              type="text"
              placeholder="山田"
              value={filters.name}
              onChange={(e) => setFilters({ ...filters, name: e.target.value })}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-xs text-gray-500 mb-1">稼働現場</label>
            <input
              type="text"
              placeholder="〇〇株式会社"
              value={filters.workSite}
              onChange={(e) => setFilters({ ...filters, workSite: e.target.value })}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
      </div>

      {/* 集計 */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-xs text-gray-500">申請件数</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{expenses.length}件</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-xs text-gray-500">合計金額（全件）</p>
          <p className="text-2xl font-bold text-gray-900 mt-1">{formatAmount(total)}</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <p className="text-xs text-gray-500">承認済合計</p>
          <p className="text-2xl font-bold text-green-600 mt-1">{formatAmount(approved)}</p>
        </div>
      </div>

      {/* テーブル */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="text-sm font-semibold text-gray-700">申請一覧</h2>
          <button
            onClick={handleExport}
            className="flex items-center gap-1.5 text-sm bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg transition-colors"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            Excelエクスポート
          </button>
        </div>

        {loading ? (
          <div className="py-16 text-center text-sm text-gray-400">読み込み中...</div>
        ) : expenses.length === 0 ? (
          <div className="py-16 text-center text-sm text-gray-400">申請データがありません</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100 bg-gray-50 text-xs text-gray-500">
                  <th className="text-left px-4 py-3 font-medium">利用日</th>
                  <th className="text-left px-4 py-3 font-medium">氏名</th>
                  <th className="text-left px-4 py-3 font-medium">稼働現場</th>
                  <th className="text-left px-4 py-3 font-medium">経路</th>
                  <th className="text-left px-4 py-3 font-medium">手段</th>
                  <th className="text-right px-4 py-3 font-medium">金額</th>
                  <th className="text-left px-4 py-3 font-medium">目的</th>
                  <th className="text-left px-4 py-3 font-medium">状態</th>
                  <th className="text-left px-4 py-3 font-medium">操作</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {expenses.map((expense) => (
                  <tr key={expense.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3 whitespace-nowrap text-gray-600">{formatDate(expense.date)}</td>
                    <td className="px-4 py-3 whitespace-nowrap font-medium text-gray-900">{expense.employeeName}</td>
                    <td className="px-4 py-3 text-gray-600">{expense.workSite}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-gray-600">{expense.from} → {expense.to}</td>
                    <td className="px-4 py-3 whitespace-nowrap text-gray-600">{expense.transport}</td>
                    <td className="px-4 py-3 text-right whitespace-nowrap font-medium text-gray-900">
                      {formatAmount(expense.amount)}
                    </td>
                    <td className="px-4 py-3 text-gray-500 max-w-[160px] truncate">{expense.purpose ?? "-"}</td>
                    <td className="px-4 py-3">
                      <StatusBadge status={expense.status} />
                      {expense.adminNote && (
                        <p className="text-xs text-gray-400 mt-1 max-w-[100px] truncate" title={expense.adminNote}>
                          {expense.adminNote}
                        </p>
                      )}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      {expense.status === "PENDING" && (
                        <div className="flex gap-2">
                          <button
                            onClick={() => { setModal({ expense, nextStatus: "APPROVED" }); setAdminNote(""); }}
                            className="text-xs bg-green-100 hover:bg-green-200 text-green-700 px-2.5 py-1 rounded-md transition-colors"
                          >
                            承認
                          </button>
                          <button
                            onClick={() => { setModal({ expense, nextStatus: "REJECTED" }); setAdminNote(""); }}
                            className="text-xs bg-red-100 hover:bg-red-200 text-red-700 px-2.5 py-1 rounded-md transition-colors"
                          >
                            却下
                          </button>
                        </div>
                      )}
                      {expense.status !== "PENDING" && (
                        <button
                          onClick={() => { setModal({ expense, nextStatus: "APPROVED" }); setAdminNote(""); }}
                          className="text-xs text-gray-400 hover:text-gray-600 underline"
                        >
                          変更
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* 承認/却下モーダル */}
      {modal && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
            <h3 className="text-base font-semibold text-gray-900 mb-1">
              {modal.nextStatus === "APPROVED" ? "承認しますか？" : "却下しますか？"}
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              {modal.expense.employeeName} / {modal.expense.from}→{modal.expense.to} / {modal.expense.amount.toLocaleString()}円
            </p>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">コメント（任意）</label>
              <textarea
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                rows={3}
                placeholder="申請者へのコメント"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setModal(null)}
                className="flex-1 border border-gray-300 text-gray-700 text-sm font-medium py-2 rounded-lg hover:bg-gray-50 transition-colors"
              >
                キャンセル
              </button>
              <button
                onClick={handleAction}
                disabled={actionLoading}
                className={`flex-1 text-white text-sm font-medium py-2 rounded-lg transition-colors disabled:opacity-50 ${
                  modal.nextStatus === "APPROVED"
                    ? "bg-green-600 hover:bg-green-700"
                    : "bg-red-600 hover:bg-red-700"
                }`}
              >
                {actionLoading ? "処理中..." : modal.nextStatus === "APPROVED" ? "承認する" : "却下する"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
