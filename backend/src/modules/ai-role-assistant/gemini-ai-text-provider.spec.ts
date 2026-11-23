import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GeminiAiTextProvider } from './gemini-ai-text-provider';

describe('GeminiAiTextProvider', () => {
  const config = { get: jest.fn() } as unknown as ConfigService;
  const originalFetch = global.fetch;
  let provider: GeminiAiTextProvider;

  beforeEach(() => {
    jest.clearAllMocks();
    provider = new GeminiAiTextProvider(config);
    config.get = jest.fn((key: string) => {
      if (key === 'GEMINI_API_KEY') return 'test-gemini-key';
      if (key === 'GEMINI_MODEL') return 'gemini-2.5-flash';
      return undefined;
    }) as unknown as ConfigService['get'];
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('sends the request through the official Gemini API with the key in a header', async () => {
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'إجابة تجريبية' }] } }] }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    const answer = await provider.generate({
      systemPrompt: 'مساعد دَرْب',
      context: { activeOrders: 2 },
      message: 'كم طلباً لدي؟',
    });

    expect(answer).toBe('إجابة تجريبية');
    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, options] = fetchMock.mock.calls[0];
    expect(url).toContain('/v1beta/models/gemini-2.5-flash:generateContent');
    expect(options.headers['x-goog-api-key']).toBe('test-gemini-key');
    const requestBody = JSON.parse(options.body);
    const systemInstruction = requestBody.systemInstruction.parts[0].text as string;
    const userMessage = requestBody.contents[0].parts[0].text as string;
    expect(systemInstruction).toContain('"activeOrders":2');
    expect(userMessage).toBe('كم طلباً لدي؟');
    expect(requestBody.generationConfig.temperature).toBe(0.2);
  });

  it('defaults to gemini-2.5-flash when GEMINI_MODEL is empty or unset', async () => {
    config.get = jest.fn((key: string) => {
      if (key === 'GEMINI_API_KEY') return 'test-gemini-key';
      if (key === 'GEMINI_MODEL') return '  ';
      return undefined;
    }) as unknown as ConfigService['get'];
    const fetchMock = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: 'حسناً' }] } }] }),
    });
    global.fetch = fetchMock as unknown as typeof fetch;

    await provider.generate({
      systemPrompt: 'مساعد',
      context: {},
      message: 'مرحبا',
    });

    const [url] = fetchMock.mock.calls[0];
    expect(url).toContain('/v1beta/models/gemini-2.5-flash:generateContent');
  });

  it('fails closed when the API key is missing', async () => {
    config.get = jest.fn(() => undefined) as unknown as ConfigService['get'];
    await expect(provider.generate({
      systemPrompt: 'مساعد',
      context: {},
      message: 'مرحبا',
    })).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('does not expose provider errors to the client', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 429,
      json: async () => ({ error: { message: 'private provider details' } }),
    }) as unknown as typeof fetch;

    await expect(provider.generate({
      systemPrompt: 'مساعد',
      context: {},
      message: 'مرحبا',
    })).rejects.toThrow('مساعد دَرْب غير متاح حالياً');
  });
});
