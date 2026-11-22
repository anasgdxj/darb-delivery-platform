import { BadRequestException, NotFoundException } from '@nestjs/common';
import { AiOrderAssistantService } from './ai-order-assistant.service';

describe('AiOrderAssistantService', () => {
  const prisma: any = {
    city: { findFirst: jest.fn() },
    vendor: { findFirst: jest.fn() },
    aiOrderDraft: { findFirst: jest.fn(), findUniqueOrThrow: jest.fn(), findMany: jest.fn() },
    product: { findMany: jest.fn() },
  };
  const config: any = { get: jest.fn() };
  let service: AiOrderAssistantService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new AiOrderAssistantService(prisma, config);
  });

  it('normalizes common Arabic letter variants and diacritics for exact matching', () => {
    const normalize = (service as any).normalize.bind(service);
    expect(normalize('أَحْمَد')).toBe(normalize('احمد'));
    expect(normalize('هــذا')).toBe(normalize('هذا'));
  });

  it('does not invent product lines when the model returns malformed items', () => {
    const result = (service as any).validateExtraction({
      intent: 'STORE_ORDER',
      items: [{ name: '   ' }, { name: 'موز', quantity: 900 }],
      address: {},
      confidence: 4,
    });
    expect(result.items).toHaveLength(1);
    expect(result.items[0].name).toBe('موز');
    expect(result.items[0].quantity).toBe(50);
    expect(result.confidence).toBe(1);
    expect(result.address.rawText).toBeNull();
  });

  it('rejects unsupported voice formats before creating a database draft', async () => {
    await expect(service.createVoiceDraft('customer-1', { cityId: 'city-1' }, {
      buffer: Buffer.from('audio'), mimetype: 'application/octet-stream', size: 5,
    })).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.city.findFirst).not.toHaveBeenCalled();
  });

  it('does not expose another customer draft', async () => {
    prisma.aiOrderDraft.findFirst.mockResolvedValue(null);
    await expect(service.getDraft('customer-1', 'draft-1')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.aiOrderDraft.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'draft-1', userId: 'customer-1' },
    }));
  });
});
