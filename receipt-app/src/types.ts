export type TemplateId = 1 | 2 | 3;

export interface IssuerInfo {
  name: string; // 会社名・屋号
  address: string;
  tel: string;
  registrationNumber: string; // インボイス登録番号（任意）
}

export type TaxRate = 10 | 8 | 0;

export interface ReceiptData {
  recipient: string; // 宛名
  amount: number; // 金額（税込）
  description: string; // 但し書き
  issueDate: string; // YYYY-MM-DD
  template: TemplateId;
  issuer: IssuerInfo;
  showRegistrationNumber: boolean;
  taxRate: TaxRate; // テンプレート3（インボイス対応）で使用する税率区分
}

export const emptyIssuer: IssuerInfo = {
  name: "",
  address: "",
  tel: "",
  registrationNumber: "",
};
