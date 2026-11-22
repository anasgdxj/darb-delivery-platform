import { BadRequestException, HttpException, HttpStatus, Injectable, Logger, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiDraftIntent, AiDraftSource, AiDraftStatus, Locale } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

type AudioFile = { buffer: Buffer; mimetype: string; size: number };
type DraftInput = { cityId: string; vendorId?: string; idempotencyKey?: string };
type Extraction = {
  intent: 'STORE_ORDER' | 'PEER_DELIVERY' | 'UNCLEAR';
  items: Array<{ name: string; quantity: number; unit: string | null; confidence: number | null }>;
  address: Record<string, string | null>;
  deliveryDescription: string | null;
  confidence: number;
  missingFields: string[];
};
const MAX_AUDIO_BYTES = 8 * 1024 * 1024;
const AUDIO_TYPES = new Set(['audio/mpeg','audio/mp4','audio/wav','audio/webm','audio/ogg','audio/x-m4a','audio/aac']);

@Injectable()
export class AiOrderAssistantService {
  private readonly logger = new Logger(AiOrderAssistantService.name);
  constructor(private readonly prisma: PrismaService, private readonly config: ConfigService) {}

  async createTextDraft(userId: string, input: DraftInput & { text: string }) {
    const text = input.text.trim();
    if (text.length < 5 || text.length > 3000) throw new BadRequestException('النص يجب أن يكون بين 5 و3000 محرف');
    const draft = await this.beginDraft(userId, input, AiDraftSource.TEXT, text);
    if (!draft.created) return this.getDraft(userId, draft.id);
    return this.processDraft(userId, draft.id, text);
  }

  async createVoiceDraft(userId: string, input: DraftInput, file?: AudioFile) {
    if (!file?.buffer?.length) throw new BadRequestException('لم يصل أي تسجيل صوتي');
    if (file.size > MAX_AUDIO_BYTES) throw new BadRequestException('حجم التسجيل يتجاوز 8 ميغابايت');
    if (!AUDIO_TYPES.has(file.mimetype)) throw new BadRequestException('صيغة التسجيل الصوتي غير مدعومة');
    const draft = await this.beginDraft(userId, input, AiDraftSource.AUDIO);
    if (!draft.created) return this.getDraft(userId, draft.id);
    try {
      const transcript = await this.transcribe(file);
      if (!transcript.trim()) throw new BadRequestException('لم نتمكن من فهم التسجيل، حاول التحدث بوضوح');
      await this.prisma.aiOrderDraft.update({ where: { id: draft.id }, data: { transcript } });
      return this.processDraft(userId, draft.id, transcript);
    } catch (error) {
      await this.markFailed(draft.id, error);
      throw error;
    }
  }

  async getDraft(userId: string, draftId: string) {
    const draft = await this.prisma.aiOrderDraft.findFirst({
      where: { id: draftId, userId },
      include: { items: { include: { product: { include: { translations: true } } } }, address: true },
    });
    if (!draft) throw new NotFoundException('مسودة الطلب غير موجودة');
    return draft;
  }

  private async beginDraft(userId: string, input: DraftInput, source: AiDraftSource, originalText?: string) {
    const city = await this.prisma.city.findFirst({ where: { id: input.cityId, isActive: true }, select: { id: true } });
    if (!city) throw new BadRequestException('المدينة غير متاحة حالياً');
    if (input.vendorId) {
      const vendor = await this.prisma.vendor.findFirst({
        where: { id: input.vendorId, status: 'APPROVED', cities: { some: { cityId: input.cityId } } },
        select: { id: true },
      });
      if (!vendor) throw new BadRequestException('المتجر غير متاح في المدينة المحددة');
    }
    if (input.idempotencyKey) {
      const existing = await this.prisma.aiOrderDraft.findFirst({
        where: { userId, idempotencyKey: input.idempotencyKey }, select: { id: true, status: true },
      });
      if (existing) return { ...existing, created: false };
    }
    const recentDrafts = await this.prisma.aiOrderDraft.count({
      where: { userId, createdAt: { gte: new Date(Date.now() - 60 * 60 * 1000) } },
    });
    if (recentDrafts >= 10) throw new HttpException('وصلت إلى الحد المؤقت لمساعد الطلبات، حاول بعد قليل', HttpStatus.TOO_MANY_REQUESTS);
    try {
      const created = await this.prisma.aiOrderDraft.create({
        data: {
          userId, cityId: input.cityId, vendorId: input.vendorId, idempotencyKey: input.idempotencyKey,
          source, originalText, status: AiDraftStatus.PROCESSING,
          expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
        },
        select: { id: true, status: true },
      });
      return { ...created, created: true };
    } catch (error) {
      if (input.idempotencyKey) {
        const existing = await this.prisma.aiOrderDraft.findFirst({
          where: { userId, idempotencyKey: input.idempotencyKey }, select: { id: true, status: true },
        });
        if (existing) return { ...existing, created: false };
      }
      throw error;
    }
  }

  private async processDraft(userId: string, draftId: string, sourceText: string) {
    try {
      const draftInfo = await this.prisma.aiOrderDraft.findUniqueOrThrow({
        where: { id: draftId }, select: { cityId: true, vendorId: true },
      });
      const parsed = await this.parseOrder(sourceText);
      const preparedItems = await Promise.all(parsed.items.slice(0, 30).map(async item => {
        const candidates = await this.findProductCandidates(draftInfo.cityId, draftInfo.vendorId, item.name);
        const exact = candidates.filter(candidate => this.normalize(candidate.name) === this.normalize(item.name));
        const matched = exact.length === 1 ? exact[0] : null;
        return {
          rawName: item.name.slice(0, 240),
          normalizedName: this.normalize(item.name).slice(0, 240),
          quantity: Math.max(1, Math.min(50, Math.trunc(item.quantity || 1))),
          unit: item.unit?.slice(0, 40) ?? null,
          confidence: this.clampConfidence(item.confidence),
          productId: matched?.id ?? null,
          candidates: candidates.map(candidate => ({
            productId: candidate.id, name: candidate.name, price: candidate.price,
            currency: candidate.currency, vendorId: candidate.vendorId, vendorName: candidate.vendorName,
          })),
        };
      }));
      const matchedVendorIds = new Set(preparedItems.filter(item => item.productId).map(item => item.candidates.find(candidate => candidate.productId === item.productId)?.vendorId).filter(Boolean));
      if (!draftInfo.vendorId && matchedVendorIds.size > 1) {
        preparedItems.forEach(item => { item.productId = null; });
      }
      const warnings = [...new Set([
        ...(!draftInfo.vendorId && matchedVendorIds.size > 1 ? ['المنتجات المقترحة من متاجر مختلفة؛ اختر متجراً واحداً لإكمال الطلب'] : []),
        ...parsed.missingFields,
        ...(parsed.intent === 'STORE_ORDER' && !preparedItems.length ? ['لم يتم تحديد منتجات'] : []),
        ...(parsed.intent === 'PEER_DELIVERY' && !parsed.deliveryDescription ? ['وصف الغرض المراد توصيله غير واضح'] : []),
        ...preparedItems.flatMap(item => item.productId ? [] : ['تحقق من المنتج: ' + item.rawName]),
        ...(parsed.address.rawText ? [] : ['العنوان يحتاج إلى توضيح']),
      ])];
      await this.prisma.$transaction(async tx => {
        if (preparedItems.length) await tx.aiOrderDraftItem.createMany({ data: preparedItems.map(item => ({ ...item, draftId })) });
        await tx.aiAddressDraft.upsert({
          where: { draftId },
          create: { draftId, ...parsed.address, geocodeStatus: 'PENDING' },
          update: { ...parsed.address, geocodeStatus: 'PENDING' },
        });
        await tx.aiOrderDraft.update({
          where: { id: draftId },
          data: {
            status: warnings.length ? AiDraftStatus.NEEDS_REVIEW : AiDraftStatus.READY,
            intent: parsed.intent as AiDraftIntent, transcript: sourceText,
            confidence: this.clampConfidence(parsed.confidence), warnings,
            extraction: { deliveryDescription: parsed.deliveryDescription }, errorCode: null,
          },
        });
      });
      return this.getDraft(userId, draftId);
    } catch (error) {
      await this.markFailed(draftId, error);
      throw error;
    }
  }

  private async transcribe(file: AudioFile): Promise<string> {
    const key = this.config.get<string>('OPENAI_API_KEY');
    if (!key) throw new ServiceUnavailableException('خدمة المساعد الصوتي غير مهيأة حالياً');
    const form = new FormData();
    form.append('model', this.config.get<string>('OPENAI_TRANSCRIPTION_MODEL') ?? 'whisper-1');
    form.append('language', 'ar');
    form.append('prompt', 'تسجيل باللهجة السورية عن طلب توصيل أو منتجات وعنوان محلي في سوريا.');
    const extension = ({ 'audio/mpeg': 'mp3', 'audio/mp4': 'mp4', 'audio/wav': 'wav', 'audio/webm': 'webm', 'audio/ogg': 'ogg', 'audio/x-m4a': 'm4a', 'audio/aac': 'aac' } as Record<string, string>)[file.mimetype] ?? 'audio';
    form.append('file', new Blob([new Uint8Array(file.buffer)], { type: file.mimetype }), 'customer-audio.' + extension);
    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST', headers: { Authorization: 'Bearer ' + key }, body: form, signal: AbortSignal.timeout(45000),
    });
    if (!response.ok) {
      this.logger.warn('Speech transcription provider returned HTTP ' + response.status);
      throw new ServiceUnavailableException('تعذر تحويل التسجيل إلى نص حالياً');
    }
    const payload = await response.json() as { text?: string };
    if (typeof payload.text !== 'string') throw new ServiceUnavailableException('نتيجة تحويل الصوت غير صالحة');
    return payload.text.trim();
  }

  private async parseOrder(text: string): Promise<Extraction> {
    const key = this.config.get<string>('OPENAI_API_KEY');
    if (!key) throw new ServiceUnavailableException('خدمة مساعد الطلبات غير مهيأة حالياً');
    const system = [
      'أنت محلل طلبات توصيل يفهم اللهجة السورية والمحكية العربية.',
      'استخرج فقط ما قاله المستخدم صراحة. لا تخترع أسماء أو كميات أو عناوين أو أرقام هواتف.',
      'ميّز بين STORE_ORDER (شراء منتجات من متجر) و PEER_DELIVERY (إرسال غرض شخصي من مكان إلى آخر) و UNCLEAR.',
      'للطلب الشخصي، ضع وصف الغرض في deliveryDescription ولا تحوله إلى منتج متجر.',
      'العنوان السوري قد يحتوي محافظة أو مدينة أو حي أو شارع أو بناء أو علامة دلالة مثل جامع أو مدرسة أو فرن.',
      'إذا لم يذكر المستخدم جزءاً من العنوان فأعد null. لا تستنتج إحداثيات.',
      'أعد JSON صالحاً فقط بهذه المفاتيح: intent, items, address, deliveryDescription, confidence, missingFields.',
      'كل item يحتوي name, quantity, unit, confidence. address يحتوي rawText, normalizedText, neighborhood, street, building, landmark, recipientName, recipientPhone, deliveryNotes.',
      'confidence رقم بين 0 و1. missingFields مصفوفة نصوص عربية.',
    ].join(' ');
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + key, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: this.config.get<string>('OPENAI_ORDER_MODEL') ?? 'gpt-4o-mini',
        temperature: 0, response_format: { type: 'json_object' },
        messages: [{ role: 'system', content: system }, { role: 'user', content: text }],
      }),
      signal: AbortSignal.timeout(30000),
    });
    if (!response.ok) {
      this.logger.warn('Order parsing provider returned HTTP ' + response.status);
      throw new ServiceUnavailableException('تعذر فهم الطلب حالياً');
    }
    const payload = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const content = payload.choices?.[0]?.message?.content;
    if (!content) throw new ServiceUnavailableException('لم تصل نتيجة تحليل الطلب');
    let raw: any;
    try { raw = JSON.parse(content); } catch { throw new ServiceUnavailableException('نتيجة تحليل الطلب غير صالحة'); }
    return this.validateExtraction(raw);
  }

  private validateExtraction(raw: any): Extraction {
    const intents = new Set(['STORE_ORDER', 'PEER_DELIVERY', 'UNCLEAR']);
    const address = raw?.address && typeof raw.address === 'object' ? raw.address : {};
    const items = Array.isArray(raw?.items) ? raw.items.slice(0, 30) : [];
    return {
      intent: intents.has(raw?.intent) ? raw.intent : 'UNCLEAR',
      items: items.filter(item => typeof item?.name === 'string' && item.name.trim()).map(item => ({
        name: item.name.trim().slice(0, 240),
        quantity: Number.isFinite(Number(item.quantity)) ? Math.max(1, Math.min(50, Math.trunc(Number(item.quantity)))) : 1,
        unit: typeof item.unit === 'string' ? item.unit.trim().slice(0, 40) : null,
        confidence: this.clampConfidence(item.confidence),
      })),
      address: {
        rawText: this.cleanText(address.rawText, 1000),
        normalizedText: this.cleanText(address.normalizedText, 1000),
        neighborhood: this.cleanText(address.neighborhood, 160),
        street: this.cleanText(address.street, 200),
        building: this.cleanText(address.building, 160),
        landmark: this.cleanText(address.landmark, 240),
        recipientName: this.cleanText(address.recipientName, 120),
        recipientPhone: this.cleanText(address.recipientPhone, 40),
        deliveryNotes: this.cleanText(address.deliveryNotes, 2000),
      },
      deliveryDescription: this.cleanText(raw?.deliveryDescription, 1000),
      confidence: this.clampConfidence(raw?.confidence) ?? 0,
      missingFields: Array.isArray(raw?.missingFields)
        ? raw.missingFields.filter((value: unknown) => typeof value === 'string').slice(0, 15).map((value: string) => value.slice(0, 160))
        : [],
    };
  }

  private async findProductCandidates(cityId: string, vendorId: string | null, name: string) {
    const products = await this.prisma.product.findMany({
      where: {
        isAvailable: true,
        vendor: { status: 'APPROVED', cities: { some: { cityId } }, ...(vendorId ? { id: vendorId } : {}) },
        translations: { some: { name: { contains: name } } },
      },
      take: 5, orderBy: { createdAt: 'desc' },
      select: {
        id: true, basePrice: true, currency: true,
        translations: { where: { locale: Locale.ar }, take: 1, select: { name: true } },
        vendor: { select: { id: true, translations: { where: { locale: Locale.ar }, take: 1, select: { name: true } } } },
      },
    });
    return products.map(product => ({
      id: product.id, name: product.translations[0]?.name ?? name,
      price: Number(product.basePrice), currency: product.currency,
      vendorId: product.vendor.id, vendorName: product.vendor.translations[0]?.name ?? 'متجر',
    }));
  }

  private async markFailed(draftId: string, error: unknown) {
    try {
      await this.prisma.aiOrderDraft.update({
        where: { id: draftId },
        data: { status: AiDraftStatus.FAILED, errorCode: error instanceof BadRequestException ? 'INVALID_INPUT' : 'AI_PROVIDER_ERROR' },
      });
    } catch { this.logger.error('Could not persist AI draft failure state'); }
  }

  private normalize(value: string) {
    return value.normalize('NFKC').replace(/[ًٌٍَُِّْـ]/g, '').replace(/[أإآ]/g, 'ا')
      .replace(/ى/g, 'ي').replace(/[^\p{L}\p{N}]+/gu, ' ').trim().toLocaleLowerCase('ar');
  }
  private cleanText(value: unknown, max: number): string | null {
    return typeof value === 'string' && value.trim() ? value.trim().slice(0, max) : null;
  }
  private clampConfidence(value: unknown): number | null {
    const number = Number(value);
    return Number.isFinite(number) ? Math.max(0, Math.min(1, number)) : null;
  }
}
