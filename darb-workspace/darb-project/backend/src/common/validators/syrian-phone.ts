const SYRIAN_MOBILE_REGEX = /^\+9639\d{8}$/;

/**
 * يحوّل أي صيغة لرقم سوري محمول إلى E.164 (+9639XXXXXXXX).
 * يعيد null إذا كان الرقم غير صالح.
 */
export function normalizeSyrianPhone(input: string): string | null {
  let p = input.trim().replace(/[^\d+]/g, '');

  if (p.startsWith('00963')) p = '+' + p.slice(2);
  else if (p.startsWith('963')) p = '+' + p;
  else if (p.startsWith('09')) p = '+963' + p.slice(1);
  else if (/^9\d{8}$/.test(p)) p = '+963' + p;

  return SYRIAN_MOBILE_REGEX.test(p) ? p : null;
}

