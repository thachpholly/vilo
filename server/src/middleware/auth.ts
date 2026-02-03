import { FastifyRequest, FastifyReply } from 'fastify';
import { verifyToken } from '../services/jwt';

// Extend FastifyRequest to include userId
declare module 'fastify' {
  interface FastifyRequest {
    userId?: string;
    phone?: string;
  }
}

export async function authenticate(
  request: FastifyRequest,
  reply: FastifyReply
): Promise<void> {
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

    request.userId = payload.userId;
    request.phone = payload.phone;
  } catch (error) {
    return reply.status(401).send({ error: 'Authentication failed' });
  }
}
