const CREDITS_KEY = "receipt-app:credits";
const FREE_USED_KEY = "receipt-app:freeUsed";

export function hasUsedFreeReceipt(): boolean {
  return localStorage.getItem(FREE_USED_KEY) === "1";
}

export function markFreeReceiptUsed(): void {
  localStorage.setItem(FREE_USED_KEY, "1");
}

export function getCredits(): number {
  return Number(localStorage.getItem(CREDITS_KEY) ?? "0");
}

export function addCredits(amount: number): number {
  const next = getCredits() + amount;
  localStorage.setItem(CREDITS_KEY, String(next));
  return next;
}

export function consumeCredit(): number {
  const next = Math.max(0, getCredits() - 1);
  localStorage.setItem(CREDITS_KEY, String(next));
  return next;
}

/** Whether the next PDF generation is allowed without hitting the paywall. */
export function canGenerateFreely(): boolean {
  return !hasUsedFreeReceipt() || getCredits() > 0;
}
