import { pgTable, text, timestamp, varchar, jsonb, uuid, boolean } from 'drizzle-orm/pg-core';

// Users table - minimal data, no message storage
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  phone: varchar('phone', { length: 20 }).notNull().unique(),
  phoneHash: varchar('phone_hash', { length: 64 }).notNull(), // SHA-256 hash for privacy
  name: varchar('name', { length: 50 }),
  avatar: text('avatar'), // URL to avatar image
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Public keys for E2EE
export const publicKeys = pgTable('public_keys', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id).notNull().unique(),
  identityKey: text('identity_key').notNull(), // Long-term identity key
  signedPreKey: text('signed_pre_key').notNull(), // Signed pre-key
  preKeys: jsonb('pre_keys').$type<string[]>().notNull(), // One-time pre-keys
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Device tokens for push notifications
export const deviceTokens = pgTable('device_tokens', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id).notNull(),
  token: text('token').notNull(),
  platform: varchar('platform', { length: 10 }).notNull(), // 'ios' or 'android'
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Blocked users (for privacy/safety)
export const blockedUsers = pgTable('blocked_users', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id).notNull(),
  blockedUserId: uuid('blocked_user_id').references(() => users.id).notNull(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Type exports for use in application
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

export type PublicKey = typeof publicKeys.$inferSelect;
export type NewPublicKey = typeof publicKeys.$inferInsert;

export type DeviceToken = typeof deviceTokens.$inferSelect;
export type NewDeviceToken = typeof deviceTokens.$inferInsert;

export type BlockedUser = typeof blockedUsers.$inferSelect;
export type NewBlockedUser = typeof blockedUsers.$inferInsert;
