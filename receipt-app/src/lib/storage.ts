import { emptyIssuer, type IssuerInfo } from "../types";

const ISSUER_KEY = "receipt-app:issuer";
const COUNT_KEY = "receipt-app:generatedCount";

export function loadIssuerInfo(): IssuerInfo {
  const raw = localStorage.getItem(ISSUER_KEY);
  if (!raw) return { ...emptyIssuer };
  try {
    return { ...emptyIssuer, ...JSON.parse(raw) };
  } catch {
    return { ...emptyIssuer };
  }
}

export function saveIssuerInfo(issuer: IssuerInfo): void {
  localStorage.setItem(ISSUER_KEY, JSON.stringify(issuer));
}

export function getGeneratedCount(): number {
  return Number(localStorage.getItem(COUNT_KEY) ?? "0");
}

export function incrementGeneratedCount(): number {
  const next = getGeneratedCount() + 1;
  localStorage.setItem(COUNT_KEY, String(next));
  return next;
}
