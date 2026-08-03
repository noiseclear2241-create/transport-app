export function formatYen(amount: number): string {
  return `¥${amount.toLocaleString("ja-JP")}`;
}

export function formatDateJp(isoDate: string): string {
  if (!isoDate) return "";
  const [y, m, d] = isoDate.split("-").map(Number);
  if (!y || !m || !d) return isoDate;
  return `${y}年${m}月${d}日`;
}

/** Splits a tax-included amount into its excl-tax base and the tax portion. */
export function splitTaxIncluded(
  amountIncludingTax: number,
  ratePercent: number
): { excludingTax: number; tax: number } {
  if (ratePercent <= 0) return { excludingTax: amountIncludingTax, tax: 0 };
  const excludingTax = Math.round(amountIncludingTax / (1 + ratePercent / 100));
  return { excludingTax, tax: amountIncludingTax - excludingTax };
}
