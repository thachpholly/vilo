import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { authenticate } from '../middleware/auth';
import { updateUser, getUserById, getUserByPhone, getPublicKey, updatePublicKey } from '../db/users';

// Validation schemas
const updateProfileSchema = z.object({
  name: z.string().min(1).max(50).optional(),
  avatar: z.string().url().optional(),
});

const publicKeySchema = z.object({
  identityKey: z.string(),
  signedPreKey: z.string(),
  preKeys: z.array(z.string()).min(1).max(100),
});

export async function userRoutes(fastify: FastifyInstance) {
  // Get current user profile
  fastify.get('/me', { preHandler: authenticate }, async (request, reply) => {
    try {
      const user = await getUserById(request.userId!);

      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      return {
        id: user.id,
        phone: user.phone,
        name: user.name,
        avatar: user.avatar,
        createdAt: user.createdAt,
      };
    } catch (error) {
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to get profile' });
    }
  });

  // Update current user profile
  fastify.patch('/me', { preHandler: authenticate }, async (request, reply) => {
    try {
      const data = updateProfileSchema.parse(request.body);

      const user = await updateUser(request.userId!, data);

      return {
        success: true,
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          avatar: user.avatar,
        },
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({ error: 'Invalid profile data' });
      }
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to update profile' });
    }
  });

  // Upload public keys for E2EE
  fastify.post('/keys', { preHandler: authenticate }, async (request, reply) => {
    try {
      const keys = publicKeySchema.parse(request.body);

      await updatePublicKey(request.userId!, keys);

      return { success: true };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({ error: 'Invalid key data' });
      }
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to upload keys' });
    }
  });

  // Get user's public keys by phone
  fastify.get('/keys/:phone', { preHandler: authenticate }, async (request, reply) => {
    try {
      const { phone } = request.params as { phone: string };

      const user = await getUserByPhone(phone);
      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      const keys = await getPublicKey(user.id);
      if (!keys) {
        return reply.status(404).send({ error: 'Keys not found' });
      }

      return {
        userId: user.id,
        identityKey: keys.identityKey,
        signedPreKey: keys.signedPreKey,
        preKey: keys.preKeys[0], // Return one prekey
      };
    } catch (error) {
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to get keys' });
    }
  });

  // Find user by phone
  fastify.get('/find/:phone', { preHandler: authenticate }, async (request, reply) => {
    try {
      const { phone } = request.params as { phone: string };

      const user = await getUserByPhone(phone);
      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      return {
        id: user.id,
        phone: user.phone,
        name: user.name,
        avatar: user.avatar,
      };
    } catch (error) {
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to find user' });
    }
  });
}
