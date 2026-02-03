import { eq } from 'drizzle-orm';
import { db } from './index';
import { users, publicKeys, User, PublicKey } from './schema';
import { createHash } from 'crypto';

/**
 * Hash phone number for privacy
 */
function hashPhone(phone: string): string {
  return createHash('sha256').update(phone).digest('hex');
}

/**
 * Find user by ID
 */
export async function getUserById(id: string): Promise<User | null> {
  const result = await db
    .select()
    .from(users)
    .where(eq(users.id, id))
    .limit(1);

  return result[0] || null;
}

/**
 * Find user by phone number
 */
export async function getUserByPhone(phone: string): Promise<User | null> {
  const result = await db
    .select()
    .from(users)
    .where(eq(users.phone, phone))
    .limit(1);

  return result[0] || null;
}

/**
 * Find or create user by phone number
 * Returns user with isNewUser flag
 */
export async function findOrCreateUser(
  phone: string
): Promise<User & { isNewUser: boolean }> {
  // Check if user exists
  const existing = await getUserByPhone(phone);

  if (existing) {
    return { ...existing, isNewUser: false };
  }

  // Create new user
  const phoneHash = hashPhone(phone);
  const result = await db
    .insert(users)
    .values({
      phone,
      phoneHash,
    })
    .returning();

  return { ...result[0], isNewUser: true };
}

/**
 * Update user profile
 */
export async function updateUser(
  id: string,
  data: { name?: string; avatar?: string }
): Promise<User> {
  const result = await db
    .update(users)
    .set({
      ...data,
      updatedAt: new Date(),
    })
    .where(eq(users.id, id))
    .returning();

  return result[0];
}

/**
 * Get user's public keys
 */
export async function getPublicKey(userId: string): Promise<PublicKey | null> {
  const result = await db
    .select()
    .from(publicKeys)
    .where(eq(publicKeys.userId, userId))
    .limit(1);

  return result[0] || null;
}

/**
 * Update or create user's public keys
 */
export async function updatePublicKey(
  userId: string,
  keys: { identityKey: string; signedPreKey: string; preKeys: string[] }
): Promise<PublicKey> {
  // Check if keys exist
  const existing = await getPublicKey(userId);

  if (existing) {
    // Update existing keys
    const result = await db
      .update(publicKeys)
      .set({
        ...keys,
        updatedAt: new Date(),
      })
      .where(eq(publicKeys.userId, userId))
      .returning();

    return result[0];
  } else {
    // Create new keys
    const result = await db
      .insert(publicKeys)
      .values({
        userId,
        ...keys,
      })
      .returning();

    return result[0];
  }
}

/**
 * Consume one pre-key (for key exchange)
 * Returns and removes one pre-key from the user's key bundle
 */
export async function consumePreKey(userId: string): Promise<string | null> {
  const keyRecord = await getPublicKey(userId);

  if (!keyRecord || keyRecord.preKeys.length === 0) {
    return null;
  }

  // Get first pre-key
  const preKey = keyRecord.preKeys[0];
  const remainingKeys = keyRecord.preKeys.slice(1);

  // Update keys
  await db
    .update(publicKeys)
    .set({
      preKeys: remainingKeys,
      updatedAt: new Date(),
    })
    .where(eq(publicKeys.userId, userId));

  return preKey;
}
