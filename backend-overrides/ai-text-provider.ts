export type AiTextRequest = {
  systemPrompt: string;
  context: Record<string, unknown>;
  message: string;
};

/**
 * Provider boundary for all role-assistant text generation.
 * Concrete providers are selected through Nest dependency injection.
 */
export abstract class AiTextProvider {
  abstract generate(request: AiTextRequest): Promise<string>;
}
