type Status = "PENDING" | "APPROVED" | "REJECTED";

const config: Record<Status, { label: string; className: string }> = {
  PENDING: { label: "申請中", className: "bg-yellow-100 text-yellow-800" },
  APPROVED: { label: "承認済", className: "bg-green-100 text-green-800" },
  REJECTED: { label: "却下", className: "bg-red-100 text-red-800" },
};

export default function StatusBadge({ status }: { status: Status }) {
  const { label, className } = config[status] ?? config.PENDING;
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${className}`}>
      {label}
    </span>
  );
}
