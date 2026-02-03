import { WebSocket } from '@fastify/websocket';
import { FastifyRequest } from 'fastify';
import { verifyToken } from '../services/jwt';
import { redis } from '../services/redis';
import { nanoid } from 'nanoid';

// Active connections map: userId -> WebSocket
const connections = new Map<string, WebSocket>();

interface WSMessage {
  type: 'message' | 'typing' | 'read' | 'delivered' | 'ping';
  payload: any;
}

interface ChatMessage {
  id: string;
  from: string;
  to: string;
  encryptedContent: string;
  timestamp: number;
  type: 'text' | 'image';
}

export async function wsHandler(socket: WebSocket, request: FastifyRequest) {
  let userId: string | null = null;

  // Authenticate on first message
  socket.on('message', async (rawData: Buffer) => {
    try {
      const data = JSON.parse(rawData.toString()) as WSMessage;

      // First message must be auth
      if (!userId) {
        if (data.type !== 'auth' as any) {
          socket.send(JSON.stringify({ error: 'Authentication required' }));
          socket.close();
          return;
        }

        const payload = await verifyToken(data.payload.token);
        if (!payload) {
          socket.send(JSON.stringify({ error: 'Invalid token' }));
          socket.close();
          return;
        }

        userId = payload.userId;
        connections.set(userId, socket);

        // Send queued messages
        await deliverQueuedMessages(userId, socket);

        socket.send(JSON.stringify({ type: 'authenticated', userId }));
        return;
      }

      // Handle different message types
      switch (data.type) {
        case 'message':
          await handleMessage(userId, data.payload, socket);
          break;

        case 'typing':
          await handleTyping(userId, data.payload);
          break;

        case 'read':
          await handleRead(userId, data.payload);
          break;

        case 'delivered':
          await handleDelivered(userId, data.payload);
          break;

        case 'ping':
          socket.send(JSON.stringify({ type: 'pong' }));
          break;
      }
    } catch (error) {
      console.error('WebSocket message error:', error);
      socket.send(JSON.stringify({ error: 'Invalid message format' }));
    }
  });

  socket.on('close', () => {
    if (userId) {
      connections.delete(userId);
    }
  });

  socket.on('error', (error: Error) => {
    console.error('WebSocket error:', error);
    if (userId) {
      connections.delete(userId);
    }
  });
}

async function handleMessage(fromUserId: string, payload: any, socket: WebSocket) {
  const message: ChatMessage = {
    id: nanoid(),
    from: fromUserId,
    to: payload.to,
    encryptedContent: payload.encryptedContent,
    timestamp: Date.now(),
    type: payload.type || 'text',
  };

  // Try to deliver directly
  const recipientSocket = connections.get(payload.to);

  if (recipientSocket && recipientSocket.readyState === WebSocket.OPEN) {
    // Direct delivery
    recipientSocket.send(JSON.stringify({
      type: 'message',
      payload: message,
    }));

    // Notify sender of delivery
    socket.send(JSON.stringify({
      type: 'delivered',
      payload: { messageId: message.id },
    }));
  } else {
    // Queue message in Redis (24h TTL)
    await queueMessage(payload.to, message);

    // Notify sender message is queued
    socket.send(JSON.stringify({
      type: 'queued',
      payload: { messageId: message.id },
    }));

    // TODO: Send push notification
  }

  // Confirm message sent
  socket.send(JSON.stringify({
    type: 'sent',
    payload: { messageId: message.id, timestamp: message.timestamp },
  }));
}

async function handleTyping(fromUserId: string, payload: { to: string }) {
  const recipientSocket = connections.get(payload.to);

  if (recipientSocket && recipientSocket.readyState === WebSocket.OPEN) {
    recipientSocket.send(JSON.stringify({
      type: 'typing',
      payload: { from: fromUserId },
    }));
  }
}

async function handleRead(fromUserId: string, payload: { to: string; messageIds: string[] }) {
  const recipientSocket = connections.get(payload.to);

  if (recipientSocket && recipientSocket.readyState === WebSocket.OPEN) {
    recipientSocket.send(JSON.stringify({
      type: 'read',
      payload: { from: fromUserId, messageIds: payload.messageIds },
    }));
  }
}

async function handleDelivered(fromUserId: string, payload: { to: string; messageId: string }) {
  const recipientSocket = connections.get(payload.to);

  if (recipientSocket && recipientSocket.readyState === WebSocket.OPEN) {
    recipientSocket.send(JSON.stringify({
      type: 'delivered',
      payload: { from: fromUserId, messageId: payload.messageId },
    }));
  }
}

async function queueMessage(userId: string, message: ChatMessage) {
  const key = `messages:${userId}`;
  await redis.lpush(key, JSON.stringify(message));
  await redis.expire(key, 86400); // 24h TTL
}

async function deliverQueuedMessages(userId: string, socket: WebSocket) {
  const key = `messages:${userId}`;
  const messages = await redis.lrange(key, 0, -1);

  if (messages.length > 0) {
    for (const msgStr of messages.reverse()) {
      const message = JSON.parse(msgStr);
      socket.send(JSON.stringify({
        type: 'message',
        payload: message,
      }));
    }

    // Clear queue after delivery
    await redis.del(key);
  }
}
