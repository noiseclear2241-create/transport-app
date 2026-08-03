import { forwardRef } from "react";
import type { TemplateProps } from "./shared";
import { TemplateRoot, StampBox, ink, subInk, line } from "./shared";
import { formatYen, formatDateJp, splitTaxIncluded } from "../../lib/format";

/**
 * インボイス対応（適格請求書等保存方式）。
 * 登録番号が無い場合はその行ごと出力しない — 「未登録でも欄が消せない」という
 * 既存アプリへの不満に対応するための分岐。
 */
const Template3 = forwardRef<HTMLDivElement, TemplateProps>(({ data }, ref) => {
  const recipientLabel = data.recipient || "上様";
  const showSama = recipientLabel !== "上様";
  const { excludingTax, tax } = splitTaxIncluded(data.amount, data.taxRate);
  const hasRegistration = data.showRegistrationNumber && !!data.issuer.registrationNumber;

  return (
    <TemplateRoot ref={ref} widthMm={210} heightMm={297}>
      <div style={{ padding: "16mm 18mm" }}>
        <h1 style={{ textAlign: "center", fontSize: "26px", letterSpacing: "10px", margin: "0 0 10mm", color: ink }}>
          領収書
        </h1>

        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "10mm" }}>
          <div style={{ fontSize: "19px", borderBottom: `2px solid ${line}`, paddingBottom: "3mm" }}>
            {recipientLabel}
            {showSama ? " 様" : ""}
          </div>
          <div style={{ fontSize: "13px", color: subInk }}>発行日：{formatDateJp(data.issueDate)}</div>
        </div>

        <div
          style={{
            border: `1px solid ${line}`,
            padding: "6mm 8mm",
            marginBottom: "8mm",
            display: "flex",
            alignItems: "baseline",
            justifyContent: "center",
            gap: "4mm",
          }}
        >
          <span style={{ fontSize: "15px", color: subInk }}>合計金額</span>
          <span style={{ fontSize: "30px", fontWeight: 700 }}>{formatYen(data.amount)}</span>
          <span style={{ fontSize: "15px", color: subInk }}>（税込）</span>
        </div>

        <div style={{ fontSize: "13px", marginBottom: "8mm" }}>但し　{data.description || "お品代として"}</div>

        {/* インボイス記載要件：税率区分・税率ごとの合計額 */}
        <table
          style={{
            width: "100%",
            borderCollapse: "collapse",
            fontSize: "13px",
            marginBottom: "10mm",
          }}
        >
          <thead>
            <tr>
              <th style={cellHeaderStyle}>税率区分</th>
              <th style={cellHeaderStyle}>税抜金額</th>
              <th style={cellHeaderStyle}>消費税額</th>
              <th style={cellHeaderStyle}>税込金額</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td style={cellStyle}>
                {data.taxRate === 0 ? "対象外" : `${data.taxRate}%対象`}
              </td>
              <td style={cellStyle}>{formatYen(excludingTax)}</td>
              <td style={cellStyle}>{formatYen(tax)}</td>
              <td style={cellStyle}>{formatYen(data.amount)}</td>
            </tr>
          </tbody>
        </table>

        <div style={{ fontSize: "12px", color: subInk, marginBottom: "24mm" }}>
          上記正に領収いたしました。
        </div>

        <div style={{ display: "flex", justifyContent: "flex-end", alignItems: "flex-start", gap: "6mm" }}>
          <div style={{ textAlign: "right", fontSize: "13px", lineHeight: 1.8, color: ink }}>
            {data.issuer.name && <div style={{ fontSize: "15px", fontWeight: 700 }}>{data.issuer.name}</div>}
            {data.issuer.address && <div>{data.issuer.address}</div>}
            {data.issuer.tel && <div>TEL：{data.issuer.tel}</div>}
            {hasRegistration && <div>登録番号：{data.issuer.registrationNumber}</div>}
          </div>
          <StampBox size={20} imageSrc={data.issuer.stampImage} />
        </div>
      </div>
    </TemplateRoot>
  );
});
Template3.displayName = "Template3";

const cellHeaderStyle: React.CSSProperties = {
  border: `1px solid ${line}`,
  padding: "3mm 2mm",
  background: "#f0f0f0",
  fontWeight: 700,
};

const cellStyle: React.CSSProperties = {
  border: `1px solid ${line}`,
  padding: "3mm 2mm",
  textAlign: "center",
};

export default Template3;
