import { useEffect, useMemo, useRef, useState } from "react";
import ReceiptForm, { type FormState } from "./components/ReceiptForm";
import PreviewFrame from "./components/PreviewFrame";
import Paywall from "./components/Paywall";
import Template1 from "./components/templates/Template1";
import Template2 from "./components/templates/Template2";
import Template3 from "./components/templates/Template3";
import { loadIssuerInfo, saveIssuerInfo } from "./lib/storage";
import { canGenerateFreely, consumeCredit, hasUsedFreeReceipt, markFreeReceiptUsed } from "./lib/credits";
import { initPurchases } from "./lib/purchases";
import { pdfFileName, renderNodeToPdfBlob, PAGE_SIZE_MM } from "./lib/pdf";
import { savePdf } from "./lib/save";
import type { ReceiptData } from "./types";

function todayIso(): string {
  return new Date().toISOString().slice(0, 10);
}

export default function App() {
  const [form, setForm] = useState<FormState>(() => ({
    recipient: "",
    amount: "",
    description: "",
    issueDate: todayIso(),
    template: 1,
    taxRate: 10,
    issuer: loadIssuerInfo(),
  }));

  const [showPaywall, setShowPaywall] = useState(false);
  const [generating, setGenerating] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const previewRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    initPurchases();
  }, []);

  useEffect(() => {
    saveIssuerInfo(form.issuer);
  }, [form.issuer]);

  const receiptData: ReceiptData = useMemo(
    () => ({
      recipient: form.recipient.trim(),
      amount: Number(form.amount) || 0,
      description: form.description.trim(),
      issueDate: form.issueDate || todayIso(),
      template: form.template,
      taxRate: form.taxRate,
      issuer: form.issuer,
      showRegistrationNumber: form.issuer.registrationNumber.trim().length > 0,
    }),
    [form]
  );

  const { w, h } = PAGE_SIZE_MM[form.template];

  const handleGenerate = async () => {
    if (!receiptData.amount) {
      setStatusMessage("金額を入力してください。");
      return;
    }
    if (!canGenerateFreely()) {
      setShowPaywall(true);
      return;
    }

    setGenerating(true);
    setStatusMessage(null);
    try {
      const node = previewRef.current;
      if (!node) return;
      const blob = await renderNodeToPdfBlob(node, form.template);
      const fileName = pdfFileName(receiptData);
      await savePdf(blob, fileName);

      if (!hasUsedFreeReceipt()) {
        markFreeReceiptUsed();
      } else {
        consumeCredit();
      }
      setStatusMessage(`${fileName} を作成しました。`);
    } catch (err) {
      console.error(err);
      setStatusMessage("PDFの作成に失敗しました。もう一度お試しください。");
    } finally {
      setGenerating(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="border-b border-gray-200 bg-white px-4 py-4">
        <h1 className="text-xl font-bold text-gray-900">領収書PDF作成</h1>
      </header>

      <main className="mx-auto grid max-w-5xl grid-cols-1 gap-8 px-4 py-6 lg:grid-cols-2">
        <section>
          <ReceiptForm value={form} onChange={setForm} />

          <button
            onClick={handleGenerate}
            disabled={generating}
            className="mt-6 w-full rounded-md bg-indigo-600 px-4 py-3 font-semibold text-white hover:bg-indigo-700 disabled:opacity-50"
          >
            {generating ? "作成中..." : "PDFを作成する"}
          </button>

          {statusMessage && <p className="mt-3 text-sm text-gray-700">{statusMessage}</p>}
        </section>

        <section>
          <h2 className="mb-3 text-sm font-medium text-gray-500">プレビュー</h2>
          <PreviewFrame widthMm={w} heightMm={h}>
            {form.template === 1 && <Template1 data={receiptData} />}
            {form.template === 2 && <Template2 data={receiptData} />}
            {form.template === 3 && <Template3 data={receiptData} />}
          </PreviewFrame>
        </section>
      </main>

      {/*
        Hidden full-size render target used only for PDF capture. The visible
        preview above is scaled down via CSS transform for on-screen display,
        but html2canvas must capture the true, untransformed physical page
        size — otherwise output resolution would vary with viewport width.
      */}
      <div style={{ position: "fixed", top: 0, left: "-99999px", pointerEvents: "none" }} aria-hidden>
        {form.template === 1 && <Template1 ref={previewRef} data={receiptData} />}
        {form.template === 2 && <Template2 ref={previewRef} data={receiptData} />}
        {form.template === 3 && <Template3 ref={previewRef} data={receiptData} />}
      </div>

      {showPaywall && (
        <Paywall
          onClose={() => setShowPaywall(false)}
          onPurchased={() => setShowPaywall(false)}
        />
      )}
    </div>
  );
}
