import type { IssuerInfo, TaxRate, TemplateId } from "../types";

export interface FormState {
  recipient: string;
  amount: string; // kept as string while editing, parsed to number on submit
  description: string;
  issueDate: string;
  template: TemplateId;
  taxRate: TaxRate;
  issuer: IssuerInfo;
}

const inputClass =
  "w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500";
const labelClass = "block text-sm font-medium text-gray-700 mb-1";

export default function ReceiptForm({
  value,
  onChange,
}: {
  value: FormState;
  onChange: (next: FormState) => void;
}) {
  const set = <K extends keyof FormState>(key: K, v: FormState[K]) =>
    onChange({ ...value, [key]: v });

  const setIssuer = <K extends keyof IssuerInfo>(key: K, v: IssuerInfo[K]) =>
    onChange({ ...value, issuer: { ...value.issuer, [key]: v } });

  return (
    <div className="space-y-5">
      <div>
        <label className={labelClass}>テンプレート</label>
        <div className="flex gap-2">
          {([1, 2, 3] as TemplateId[]).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => set("template", t)}
              className={`flex-1 rounded-md border px-3 py-2 text-sm ${
                value.template === t
                  ? "border-indigo-600 bg-indigo-50 text-indigo-700 font-semibold"
                  : "border-gray-300 text-gray-600"
              }`}
            >
              {t === 1 && "① シンプル縦型"}
              {t === 2 && "② ビジネス横型"}
              {t === 3 && "③ インボイス対応"}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass}>宛名</label>
          <input
            className={inputClass}
            placeholder="上様"
            value={value.recipient}
            onChange={(e) => set("recipient", e.target.value)}
          />
        </div>
        <div>
          <label className={labelClass}>金額（税込）</label>
          <input
            className={inputClass}
            type="number"
            inputMode="numeric"
            placeholder="8000"
            value={value.amount}
            onChange={(e) => set("amount", e.target.value)}
          />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className={labelClass}>但し書き</label>
          <input
            className={inputClass}
            placeholder="お品代として"
            value={value.description}
            onChange={(e) => set("description", e.target.value)}
          />
        </div>
        <div>
          <label className={labelClass}>発行日</label>
          <input
            className={inputClass}
            type="date"
            value={value.issueDate}
            onChange={(e) => set("issueDate", e.target.value)}
          />
        </div>
      </div>

      {value.template === 3 && (
        <div>
          <label className={labelClass}>税率区分</label>
          <select
            className={inputClass}
            value={value.taxRate}
            onChange={(e) => set("taxRate", Number(e.target.value) as TaxRate)}
          >
            <option value={10}>10%対象</option>
            <option value={8}>8%対象（軽減税率）</option>
            <option value={0}>非課税・対象外</option>
          </select>
        </div>
      )}

      <fieldset className="rounded-md border border-gray-200 p-4">
        <legend className="px-1 text-sm font-medium text-gray-700">
          発行元情報（一度入力すると次回から自動入力されます）
        </legend>
        <div className="space-y-3">
          <div>
            <label className={labelClass}>会社名・屋号</label>
            <input
              className={inputClass}
              value={value.issuer.name}
              onChange={(e) => setIssuer("name", e.target.value)}
            />
          </div>
          <div>
            <label className={labelClass}>住所</label>
            <input
              className={inputClass}
              value={value.issuer.address}
              onChange={(e) => setIssuer("address", e.target.value)}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className={labelClass}>電話番号</label>
              <input
                className={inputClass}
                value={value.issuer.tel}
                onChange={(e) => setIssuer("tel", e.target.value)}
              />
            </div>
            <div>
              <label className={labelClass}>インボイス登録番号（任意）</label>
              <input
                className={inputClass}
                placeholder="T1234567890123"
                value={value.issuer.registrationNumber}
                onChange={(e) => setIssuer("registrationNumber", e.target.value)}
              />
              <p className="mt-1 text-xs text-gray-500">
                未入力の場合、領収書に登録番号の欄は表示されません。
              </p>
            </div>
          </div>
        </div>
      </fieldset>
    </div>
  );
}
