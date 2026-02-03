import { Redis } from '@upstash/redis';

// Initialize Redis client
// Uses Upstash Redis (serverless, free tier available)
export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL || 'http://localhost:6379',
  token: process.env.UPSTASH_REDIS_REST_TOKEN || '',
});

// Helper functions for common Redis operations

/**
 * Set a value with optional expiration
 */
export async function setWithExpiry(
  key: string,
  value: string,
  expirySeconds: number
): Promise<void> {
  await redis.set(key, value);
  await redis.expire(key, expirySeconds);
}

/**
 * Get and delete a value (useful for one-time tokens)
 */
export async function getAndDelete(key: string): Promise<string | null> {
  const value = await redis.get<string>(key);
  if (value) {
    await redis.del(key);
  }
  return value;
}

/**
 * Check if key exists
 */
export async function exists(key: string): Promise<boolean> {
  const result = await redis.exists(key);
  return result === 1;
}

/**
 * Store user's online status
 */
export async function setUserOnline(userId: string): Promise<void> {
  await redis.set(`online:${userId}`, Date.now().toString());
  await redis.expire(`online:${userId}`, 300); // 5 minutes TTL
}

/**
 * Check if user is online
 */
export async function isUserOnline(userId: string): Promise<boolean> {
  return await exists(`online:${userId}`);
}

/**
 * Get last seen timestamp
 */
export async function getLastSeen(userId: string): Promise<number | null> {
  const timestamp = await redis.get<string>(`online:${userId}`);
  return timestamp ? parseInt(timestamp) : null;
}
