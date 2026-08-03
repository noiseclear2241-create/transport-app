import { Capacitor } from "@capacitor/core";
import { Purchases, LOG_LEVEL, type PurchasesPackage } from "@revenuecat/purchases-capacitor";

/**
 * RevenueCat API keys are public identifiers (safe to ship in the app binary),
 * but they must come from YOUR RevenueCat project. Fill these in via env vars
 * at build time — see receipt-app/docs/store-setup.md.
 */
const REVENUECAT_API_KEY = {
  ios: import.meta.env.VITE_REVENUECAT_IOS_KEY ?? "",
  android: import.meta.env.VITE_REVENUECAT_ANDROID_KEY ?? "",
};

/**
 * Each purchasable RevenueCat package must be tagged (in the RevenueCat
 * dashboard, under "Offerings") so we know how many receipt credits it grants.
 * We read that count from the package's metadata key "credits" configured
 * server-side, falling back to parsing the identifier as "credits_5" etc.
 */
function creditsForPackage(pkg: PurchasesPackage): number {
  const match = /credits_(\d+)/.exec(pkg.identifier);
  return match ? Number(match[1]) : 1;
}

let configured = false;

export async function initPurchases(): Promise<void> {
  if (configured || !Capacitor.isNativePlatform()) return;
  const apiKey =
    Capacitor.getPlatform() === "ios"
      ? REVENUECAT_API_KEY.ios
      : REVENUECAT_API_KEY.android;
  if (!apiKey) {
    console.warn("RevenueCat API key is not set; purchases are disabled.");
    return;
  }
  await Purchases.setLogLevel({ level: LOG_LEVEL.WARN });
  await Purchases.configure({ apiKey });
  configured = true;
}

export interface CreditPackageOption {
  pkg: PurchasesPackage;
  credits: number;
  priceString: string;
  title: string;
}

export async function fetchCreditPackages(): Promise<CreditPackageOption[]> {
  if (!Capacitor.isNativePlatform()) return [];
  const offerings = await Purchases.getOfferings();
  const current = offerings.current;
  if (!current) return [];
  return current.availablePackages.map((pkg) => ({
    pkg,
    credits: creditsForPackage(pkg),
    priceString: pkg.product.priceString,
    title: pkg.product.title || pkg.identifier,
  }));
}

export async function purchaseCreditPackage(
  option: CreditPackageOption
): Promise<{ success: boolean; creditsGranted: number }> {
  try {
    await Purchases.purchasePackage({ aPackage: option.pkg });
    return { success: true, creditsGranted: option.credits };
  } catch (err: unknown) {
    const userCancelled =
      typeof err === "object" &&
      err !== null &&
      "userCancelled" in err &&
      (err as { userCancelled?: boolean }).userCancelled;
    if (!userCancelled) console.error("Purchase failed", err);
    return { success: false, creditsGranted: 0 };
  }
}

export async function restorePurchases(): Promise<void> {
  if (!Capacitor.isNativePlatform()) return;
  await Purchases.restorePurchases();
}
