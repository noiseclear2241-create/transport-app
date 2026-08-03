import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import type { ReceiptData } from "../types";

/** Physical page size (mm) per template. Template 2 is landscape B5. */
export const PAGE_SIZE_MM: Record<ReceiptData["template"], { w: number; h: number }> = {
  1: { w: 210, h: 297 }, // A4 portrait
  2: { w: 257, h: 182 }, // B5 landscape
  3: { w: 210, h: 297 }, // A4 portrait
};

export function pdfFileName(data: ReceiptData): string {
  const safe = (s: string) => s.replace(/[\\/:*?"<>|]/g, "");
  return `領収書_${safe(data.recipient || "宛名未設定")}_${data.issueDate}.pdf`;
}

/**
 * Renders the given DOM node (the on-screen receipt template) to a canvas at
 * high resolution, then embeds it as a full-bleed image into a correctly
 * sized PDF page. Rendering via the WebView's own text layout means Japanese
 * fonts always come out correct without embedding a CJK font into the PDF.
 */
export async function renderNodeToPdfBlob(
  node: HTMLElement,
  template: ReceiptData["template"]
): Promise<Blob> {
  const canvas = await html2canvas(node, {
    scale: 3,
    useCORS: true,
    backgroundColor: "#ffffff",
  });

  const { w, h } = PAGE_SIZE_MM[template];
  const orientation = w > h ? "landscape" : "portrait";
  const pdf = new jsPDF({ unit: "mm", format: [w, h], orientation });

  const imgData = canvas.toDataURL("image/jpeg", 0.95);
  pdf.addImage(imgData, "JPEG", 0, 0, w, h);

  return pdf.output("blob");
}
