import { forwardRef } from "react";
import type { TemplateProps } from "./shared";
import { TemplateRoot, StampBox, ink, subInk, line, faintLine } from "./shared";
import { formatYen, formatDateJp } from "../../lib/format";

/**
 * ビジネス横型（B5横置き・全面印刷対応）。
 * 「縦型レイアウトを横印刷すると用紙の1/3しか使われない」という既存アプリへの
 * 不満に対応するため、左右2カラムで用紙の横幅をフルに使うレイアウトにしている。
 */
const Template2 = forwardRef<HTMLDivElement, TemplateProps>(({ data }, ref) => {
  const recipientLabel = data.recipient || "上様";
  const showSama = recipientLabel !== "上様";

  return (
    <TemplateRoot ref={ref} widthMm={257} heightMm={182}>
      <div style={{ height: "100%", display: "flex", flexDirection: "column", padding: "12mm 16mm" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "baseline" }}>
          <h1 style={{ fontSize: "26px", letterSpacing: "10px", margin: 0, color: ink }}>領収書</h1>
          <div style={{ fontSize: "12px", color: subInk }}>発行日：{formatDateJp(data.issueDate)}</div>
        </div>

        <div
          style={{
            flex: 1,
            display: "flex",
            gap: "14mm",
            marginTop: "8mm",
          }}
        >
          {/* 左カラム：宛名・金額・但し書き */}
          <div style={{ flex: 1.3, display: "flex", flexDirection: "column" }}>
            <div
              style={{
                fontSize: "18px",
                borderBottom: `2px solid ${line}`,
                paddingBottom: "3mm",
                marginBottom: "8mm",
              }}
            >
              {recipientLabel}
              {showSama ? " 様" : ""}
            </div>

            <div
              style={{
                border: `1px solid ${line}`,
                padding: "6mm 8mm",
                marginBottom: "8mm",
                display: "flex",
                alignItems: "baseline",
                gap: "4mm",
              }}
            >
              <span style={{ fontSize: "14px", color: subInk }}>金額</span>
              <span style={{ fontSize: "30px", fontWeight: 700 }}>{formatYen(data.amount)}</span>
              <span style={{ fontSize: "14px", color: subInk }}>（税込）</span>
            </div>

            <div style={{ fontSize: "13px" }}>但し　{data.description || "お品代として"}</div>
            <div style={{ fontSize: "12px", color: subInk, marginTop: "auto" }}>
              上記正に領収いたしました。
            </div>
          </div>

          {/* 右カラム：発行元情報・印影 */}
          <div
            style={{
              flex: 1,
              borderLeft: `1px solid ${faintLine}`,
              paddingLeft: "12mm",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
            }}
          >
            <div style={{ fontSize: "12px", lineHeight: 1.9, color: ink }}>
              {data.issuer.name && <div style={{ fontSize: "15px", fontWeight: 700 }}>{data.issuer.name}</div>}
              {data.issuer.address && <div>{data.issuer.address}</div>}
              {data.issuer.tel && <div>TEL：{data.issuer.tel}</div>}
              {data.showRegistrationNumber && data.issuer.registrationNumber && (
                <div>登録番号：{data.issuer.registrationNumber}</div>
              )}
            </div>
            <div style={{ display: "flex", justifyContent: "flex-end" }}>
              <StampBox size={20} imageSrc={data.issuer.stampImage} />
            </div>
          </div>
        </div>
      </div>
    </TemplateRoot>
  );
});
Template2.displayName = "Template2";

export default Template2;
