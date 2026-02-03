import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { sendOTP, verifyOTP } from '../services/otp';
import { createToken, verifyToken } from '../services/jwt';
import { findOrCreateUser, getUserByPhone } from '../db/users';

// Validation schemas
const sendOTPSchema = z.object({
  phone: z.string().regex(/^\+84[0-9]{9,10}$/, 'Invalid Vietnamese phone number'),
});

const verifyOTPSchema = z.object({
  phone: z.string(),
  code: z.string().length(6),
});

export async function authRoutes(fastify: FastifyInstance) {
  // Send OTP to phone number
  fastify.post('/send-otp', async (request, reply) => {
    try {
      const { phone } = sendOTPSchema.parse(request.body);

      await sendOTP(phone);

      return { success: true, message: 'OTP sent' };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({ error: 'Invalid phone number format' });
      }
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Failed to send OTP' });
    }
  });

  // Verify OTP and login/register
  fastify.post('/verify-otp', async (request, reply) => {
    try {
      const { phone, code } = verifyOTPSchema.parse(request.body);

      const isValid = await verifyOTP(phone, code);
      if (!isValid) {
        return reply.status(401).send({ error: 'Invalid or expired OTP' });
      }

      // Find or create user
      const user = await findOrCreateUser(phone);

      // Generate JWT
      const token = await createToken({ userId: user.id, phone });

      return {
        success: true,
        token,
        user: {
          id: user.id,
          phone: user.phone,
          name: user.name,
          avatar: user.avatar,
          isNewUser: user.isNewUser,
        },
      };
    } catch (error) {
      if (error instanceof z.ZodError) {
        return reply.status(400).send({ error: 'Invalid request data' });
      }
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Verification failed' });
    }
  });

  // Refresh token
  fastify.post('/refresh', async (request, reply) => {
    try {
      const authHeader = request.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        return reply.status(401).send({ error: 'No token provided' });
      }

      const token = authHeader.slice(7);
      const payload = await verifyToken(token);

      if (!payload) {
        return reply.status(401).send({ error: 'Invalid token' });
      }

      const newToken = await createToken({
        userId: payload.userId,
        phone: payload.phone
      });

      return { success: true, token: newToken };
    } catch (error) {
      fastify.log.error(error);
      return reply.status(500).send({ error: 'Token refresh failed' });
    }
  });
}
