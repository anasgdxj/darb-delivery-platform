import { normalizeSyrianPhone } from './syrian-phone';

describe('normalizeSyrianPhone', () => {
  it('يقبل الصيغة المحلية مع مسافات', () => {
    expect(normalizeSyrianPhone('0944 123 456')).toBe('+963944123456');
  });

  it('يقبل الصيغة 00963', () => {
    expect(normalizeSyrianPhone('00963 944123456')).toBe('+963944123456');
  });

  it('يقبل الصيغة الدولية مع شرطات', () => {
    expect(normalizeSyrianPhone('+963-944-123-456')).toBe('+963944123456');
  });

  it('يرفض الأرقام الأرضية', () => {
    expect(normalizeSyrianPhone('0112345678')).toBeNull();
  });

  it('يرفض أرقام الدول الأخرى', () => {
    expect(normalizeSyrianPhone('+966501234567')).toBeNull();
  });
});

