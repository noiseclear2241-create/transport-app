import { useEffect, useState } from "react";
import { Capacitor } from "@capacitor/core";
import {
  fetchCreditPackages,
  purchaseCreditPackage,
  restorePurchases,
  type CreditPackageOption,
} from "../lib/purchases";
import { addCredits } from "../lib/credits";

export default function Paywall({
  onClose,
  onPurchased,
}: {
  onClose: () => void;
  onPurchased: () => void;
}) {
  const [packages, setPackages] = useState<CreditPackageOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [purchasingId, setPurchasingId] = useState<string | null>(null);

  useEffect(() => {
    fetchCreditPackages()
      .then(setPackages)
      .finally(() => setLoading(false));
  }, []);

  const handlePurchase = async (option: CreditPackageOption) => {
    setPurchasingId(option.pkg.identifier);
    const result = await purchaseCreditPackage(option);
    setPurchasingId(null);
    if (result.success) {
      addCredits(result.creditsGranted);
      onPurchased();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-sm rounded-lg bg-white p-6 shadow-xl">
        <h2 className="text-lg font-bold text-gray-900">2枚目以降は有料です</h2>
        <p className="mt-2 text-sm text-gray-600">
          1枚目は無料でご利用いただけました。2枚目以降の領収書作成には、下記いずれかのクレジットパックをご購入ください。
        </p>

        {!Capacitor.isNativePlatform() && (
          <p className="mt-3 rounded-md bg-amber-50 p-3 text-xs text-amber-800">
            開発用ブラウザプレビューでは購入できません。実機（iOS/Android）で
            ビルドし、ストアの決済情報を設定した状態でご確認ください。
          </p>
        )}

        <div className="mt-4 space-y-2">
          {loading && <p className="text-sm text-gray-500">読み込み中...</p>}
          {!loading && packages.length === 0 && Capacitor.isNativePlatform() && (
            <p className="text-sm text-gray-500">
              購入可能なプランが見つかりません。ストア側の商品設定をご確認ください。
            </p>
          )}
          {packages.map((option) => (
            <button
              key={option.pkg.identifier}
              onClick={() => handlePurchase(option)}
              disabled={purchasingId !== null}
              className="flex w-full items-center justify-between rounded-md border border-gray-300 px-4 py-3 text-left hover:border-indigo-500 disabled:opacity-50"
            >
              <span>
                <span className="block font-medium text-gray-900">{option.title}</span>
                <span className="block text-xs text-gray-500">{option.credits}枚分</span>
              </span>
              <span className="font-semibold text-indigo-700">
                {purchasingId === option.pkg.identifier ? "購入中..." : option.priceString}
              </span>
            </button>
          ))}
        </div>

        <div className="mt-5 flex justify-between text-sm">
          <button
            onClick={() => restorePurchases().then(onPurchased)}
            className="text-indigo-600 hover:underline"
          >
            購入を復元
          </button>
          <button onClick={onClose} className="text-gray-500 hover:underline">
            閉じる
          </button>
        </div>
      </div>
    </div>
  );
}
