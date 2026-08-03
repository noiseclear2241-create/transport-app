import { forwardRef } from "react";
import type { ReceiptData } from "../../types";

/**
 * html2canvas cannot parse modern CSS color functions (oklch/lab), which is
 * what Tailwind v4's default palette compiles to. The printable receipt
 * templates below therefore use plain inline styles with hex colors only —
 * Tailwind classes are fine everywhere else in the app, just not in here.
 */
export const ink = "#1a1a1a";
export const subInk = "#555555";
export const line = "#333333";
export const faintLine = "#cccccc";

export const StampBox = ({ size = 22, imageSrc }: { size?: number; imageSrc?: string }) => {
  if (imageSrc) {
    return (
      <img
        src={imageSrc}
        alt="印影"
        style={{
          width: `${size}mm`,
          height: `${size}mm`,
          objectFit: "contain",
          flexShrink: 0,
        }}
      />
    );
  }
  return (
    <div
      style={{
        width: `${size}mm`,
        height: `${size}mm`,
        border: `1px dashed ${faintLine}`,
        borderRadius: "50%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: faintLine,
        fontSize: "10px",
        flexShrink: 0,
      }}
    >
      印
    </div>
  );
};

export interface TemplateProps {
  data: ReceiptData;
}

export const TemplateRoot = forwardRef<
  HTMLDivElement,
  { widthMm: number; heightMm: number; children: React.ReactNode }
>(({ widthMm, heightMm, children }, ref) => (
  <div
    ref={ref}
    style={{
      width: `${widthMm}mm`,
      height: `${heightMm}mm`,
      background: "#ffffff",
      color: ink,
      boxSizing: "border-box",
      fontFamily:
        '"Hiragino Sans", "Hiragino Kaku Gothic ProN", "Noto Sans JP", "Yu Gothic", sans-serif',
      position: "relative",
      overflow: "hidden",
    }}
  >
    {children}
  </div>
));
TemplateRoot.displayName = "TemplateRoot";
