import { forwardRef } from "react";
import type { TemplateProps } from "./shared";
import { TemplateRoot, StampBox, ink, subInk, line } from "./shared";
import { formatYen, formatDateJp } from "../../lib/format";

/** シンプル縦型（A4縦） */
const Template1 = forwardRef<HTMLDivElement, TemplateProps>(({ data }, ref) => {
  const recipientLabel = data.recipient || "上様";
  const showSama = recipientLabel !== "上様";

  return (
    <TemplateRoot ref={ref} widthMm={210} heightMm={297}>
      <div style={{ padding: "18mm 20mm" }}>
        <h1
          style={{
            textAlign: "center",
            fontSize: "28px",
            letterSpacing: "12px",
            margin: "0 0 16mm",
            color: ink,
          }}
        >
          領収書
        </h1>

        <div style={{ textAlign: "right", fontSize: "13px", color: subInk, marginBottom: "8mm" }}>
          発行日：{formatDateJp(data.issueDate)}
        </div>

        <div
          style={{
            fontSize: "20px",
            borderBottom: `2px solid ${line}`,
            paddingBottom: "4mm",
            marginBottom: "12mm",
          }}
        >
          {recipientLabel}
          {showSama ? " 様" : ""}
        </div>

        <div
          style={{
            border: `1px solid ${line}`,
            padding: "8mm 10mm",
            marginBottom: "10mm",
            display: "flex",
            alignItems: "baseline",
            justifyContent: "center",
            gap: "4mm",
          }}
        >
          <span style={{ fontSize: "16px", color: subInk }}>金額</span>
          <span style={{ fontSize: "34px", fontWeight: 700, letterSpacing: "1px" }}>
            {formatYen(data.amount)}
          </span>
          <span style={{ fontSize: "16px", color: subInk }}>（税込）</span>
        </div>

        <div style={{ fontSize: "14px", marginBottom: "20mm" }}>
          但し　{data.description || "お品代として"}
        </div>

        <div style={{ fontSize: "13px", color: subInk, marginBottom: "40mm" }}>
          上記正に領収いたしました。
        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "flex-start", gap: "6mm" }}>
          <div style={{ textAlign: "right", fontSize: "13px", lineHeight: 1.8, color: ink }}>
            {data.issuer.name && <div style={{ fontSize: "15px", fontWeight: 700 }}>{data.issuer.name}</div>}
            {data.issuer.address && <div>{data.issuer.address}</div>}
            {data.issuer.tel && <div>TEL：{data.issuer.tel}</div>}
            {data.showRegistrationNumber && data.issuer.registrationNumber && (
              <div>登録番号：{data.issuer.registrationNumber}</div>
            )}
          </div>
          <StampBox size={20} />
        </div>
      </div>
    </TemplateRoot>
  );
});
Template1.displayName = "Template1";

export default Template1;
