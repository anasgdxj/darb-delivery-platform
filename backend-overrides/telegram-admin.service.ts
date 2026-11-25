import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface TelegramUser {
  id: number;
  username?: string;
}

interface TelegramMessage {
  text?: string;
  from?: TelegramUser;
  chat?: { id: number; type?: string };
}

export interface TelegramUpdate {
  update_id?: number;
  message?: TelegramMessage;
  edited_message?: TelegramMessage;
}

interface TelegramApiResponse<T> {
  ok: boolean;
  result?: T;
  description?: string;
}

interface GitHubRelease {
  tag_name?: string;
  name?: string;
  html_url?: string;
  published_at?: string;
  body?: string;
  assets?: Array<{ name?: string; browser_download_url?: string }>;
}

@Injectable()
export class TelegramAdminService implements OnModuleInit {
  private readonly logger = new Logger(TelegramAdminService.name);
  private readonly apiBase = (process.env.DAZREVO_API_BASE_URL || 'https://darb-api-yapv.onrender.com/api/v1').replace(/\/$/, '');
  private readonly githubApi = 'https://api.github.com/repos/anasgdxj/darb-delivery-platform';

  constructor(private readonly config: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const token = this.botToken;
    const webhookUrl = this.config.get<string>('TELEGRAM_WEBHOOK_URL')?.trim();
    const secret = this.config.get<string>('TELEGRAM_WEBHOOK_SECRET')?.trim();
    if (!token || !webhookUrl || !secret || secret.length < 32) {
      this.logger.warn('Telegram operations bot is disabled: configure TELEGRAM_BOT_TOKEN, TELEGRAM_WEBHOOK_URL and a 32+ character TELEGRAM_WEBHOOK_SECRET.');
      return;
    }
    try {
      await this.telegramRequest('setWebhook', {
        url: webhookUrl,
        secret_token: secret,
        allowed_updates: ['message'],
        drop_pending_updates: false,
      });
      this.logger.log('Telegram operations webhook registered.');
    } catch (error) {
      this.logger.error('Telegram webhook registration failed.', error instanceof Error ? error.stack : undefined);
    }
  }

  get webhookSecret(): string {
    return this.config.get<string>('TELEGRAM_WEBHOOK_SECRET')?.trim() ?? '';
  }

  async handleUpdate(update: TelegramUpdate): Promise<void> {
    const message = update.message ?? update.edited_message;
    const chatId = message?.chat?.id;
    const senderId = message?.from?.id;
    const text = message?.text?.trim();
    if (!chatId || !senderId || !text || !text.startsWith('/')) return;

    const command = text.split(/\s+/, 1)[0].split('@', 1)[0].toLowerCase();
    if (command === '/id') {
      await this.sendMessage(chatId, `Telegram user ID: ${senderId}`);
      this.audit(senderId, command, 'self-id');
      return;
    }

    if (!this.isAdmin(senderId)) {
      this.audit(senderId, command, 'denied');
      return;
    }

    this.audit(senderId, command, 'accepted');
    try {
      let response: string;
      switch (command) {
        case '/start':
        case '/help':
          response = this.helpMessage();
          break;
        case '/status':
          response = await this.statusReport();
          break;
        case '/api':
          response = await this.apiReport();
          break;
        case '/version':
          response = await this.versionReport();
          break;
        case '/releases':
          response = await this.releasesReport();
          break;
        default:
          response = 'الأمر غير معروف. أرسل /help لعرض الأوامر المتاحة.';
      }
      await this.sendMessage(chatId, response);
    } catch (error) {
      this.logger.error(`Telegram command ${command} failed.`, error instanceof Error ? error.stack : undefined);
      await this.sendMessage(chatId, 'تعذر تنفيذ الأمر الآن. تم تسجيل الخطأ في سجلات الخادم.');
    }
  }

  private get botToken(): string {
    return this.config.get<string>('TELEGRAM_BOT_TOKEN')?.trim() ?? '';
  }

  private isAdmin(userId: number): boolean {
    const ids = (this.config.get<string>('TELEGRAM_ADMIN_IDS') ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter((value) => /^\d+$/.test(value));
    return ids.includes(String(userId));
  }

  private helpMessage(): string {
    return [
      '🤖 DAZREVO — مركز مراقبة العمليات',
      '',
      '/status — حالة API وقاعدة البيانات وRedis',
      '/api — فحص نقاط الصحة بالتفصيل',
      '/version — أحدث إصدار منشور',
      '/releases — آخر خمسة إصدارات',
      '/help — عرض هذه القائمة',
      '',
      'هذه المرحلة للقراءة والمراقبة فقط. لا توجد أوامر تغيّر البيانات أو تنشر إصداراً.',
    ].join('\n');
  }

  private async statusReport(): Promise<string> {
    const [liveness, readiness] = await Promise.all([
      this.checkEndpoint('/healthz'),
      this.checkEndpoint('/readyz'),
    ]);
    return [
      '🛰 DAZREVO — الحالة العامة',
      `API: ${liveness.ok ? '🟢 متاح' : '🔴 غير متاح'} (HTTP ${liveness.status})`,
      `قاعدة البيانات وRedis: ${readiness.ok ? '🟢 جاهزان' : '🔴 مشكلة أو غير جاهزين'} (HTTP ${readiness.status})`,
      `وقت الفحص: ${new Date().toISOString()}`,
    ].join('\n');
  }

  private async apiReport(): Promise<string> {
    const [liveness, readiness] = await Promise.all([
      this.checkEndpoint('/healthz'),
      this.checkEndpoint('/readyz'),
    ]);
    return [
      '🔎 فحص DAZREVO API',
      `GET /healthz → HTTP ${liveness.status}: ${liveness.ok ? 'OK' : 'FAILED'}`,
      `GET /readyz → HTTP ${readiness.status}: ${readiness.ok ? 'OK' : 'FAILED'}`,
      `تفاصيل الجاهزية: ${readiness.detail}`,
    ].join('\n');
  }

  private async checkEndpoint(path: string): Promise<{ ok: boolean; status: number; detail: string }> {
    try {
      const response = await fetch(`${this.apiBase}${path}`, {
        method: 'GET',
        headers: { accept: 'application/json' },
        signal: AbortSignal.timeout(12000),
      });
      const body = await response.text();
      return { ok: response.ok, status: response.status, detail: body.slice(0, 500) || response.statusText };
    } catch (error) {
      return { ok: false, status: 0, detail: error instanceof Error ? error.message : 'Network error' };
    }
  }

  private async versionReport(): Promise<string> {
    const release = await this.githubRequest<GitHubRelease>('/releases/latest');
    const apk = release.assets?.find((asset) => asset.name === 'app-release.apk');
    return [
      '📦 أحدث إصدار DAZREVO',
      `الإصدار: ${release.name || release.tag_name || 'غير محدد'}`,
      `الوسم: ${release.tag_name || 'غير محدد'}`,
      `تاريخ النشر: ${release.published_at || 'غير متاح'}`,
      apk?.browser_download_url ? `APK: ${apk.browser_download_url}` : 'APK: لم يُعثر على أصل app-release.apk',
      release.html_url ? `التفاصيل: ${release.html_url}` : '',
    ].filter(Boolean).join('\n');
  }

  private async releasesReport(): Promise<string> {
    const releases = await this.githubRequest<GitHubRelease[]>('/releases?per_page=5');
    if (!Array.isArray(releases) || releases.length === 0) return 'لا توجد إصدارات منشورة في GitHub حالياً.';
    return [
      '🗂 آخر إصدارات DAZREVO',
      ...releases.map((release, index) =>
        `${index + 1}. ${release.name || release.tag_name || 'إصدار'} — ${release.published_at || 'تاريخ غير متاح'}\n${release.html_url || ''}`.trim(),
      ),
    ].join('\n\n');
  }

  private async githubRequest<T>(path: string): Promise<T> {
    const response = await fetch(`${this.githubApi}${path}`, {
      headers: { accept: 'application/vnd.github+json', 'x-github-api-version': '2022-11-28' },
      signal: AbortSignal.timeout(12000),
    });
    if (!response.ok) throw new Error(`GitHub API returned HTTP ${response.status}`);
    return response.json() as Promise<T>;
  }

  private async sendMessage(chatId: number, text: string): Promise<void> {
    if (!this.botToken) throw new Error('Telegram bot token is not configured.');
    await this.telegramRequest('sendMessage', {
      chat_id: chatId,
      text: text.slice(0, 3900),
      disable_web_page_preview: true,
    });
  }

  private async telegramRequest<T = unknown>(method: string, payload: Record<string, unknown>): Promise<T> {
    const response = await fetch(`https://api.telegram.org/bot${this.botToken}/${method}`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(15000),
    });
    const result = await response.json() as TelegramApiResponse<T>;
    if (!response.ok || !result.ok) {
      throw new Error(`Telegram API ${method} failed: ${result.description || response.statusText}`);
    }
    return result.result as T;
  }

  private audit(userId: number, command: string, outcome: string): void {
    this.logger.log(JSON.stringify({
      event: 'telegram_admin_command',
      telegramUserId: userId,
      command,
      outcome,
      timestamp: new Date().toISOString(),
    }));
  }
}
