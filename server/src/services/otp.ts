import twilio from 'twilio';
import { redis } from './redis';
import { nanoid } from 'nanoid';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

// Initialize Twilio client (only if credentials exist)
const twilioClient = accountSid && authToken ? twilio(accountSid, authToken) : null;

// OTP expiration time in seconds
const OTP_EXPIRATION = 300; // 5 minutes

// Rate limiting: max OTP requests per phone
const MAX_OTP_REQUESTS = 5;
const RATE_LIMIT_WINDOW = 3600; // 1 hour

/**
 * Send OTP to phone number
 * Uses Twilio Verify in production, or generates mock OTP in development
 */
export async function sendOTP(phone: string): Promise<void> {
  // Rate limiting check
  const rateLimitKey = `otp:ratelimit:${phone}`;
  const requestCount = await redis.get(rateLimitKey);

  if (requestCount && parseInt(requestCount as string) >= MAX_OTP_REQUESTS) {
    throw new Error('Too many OTP requests. Please try again later.');
  }

  // Increment rate limit counter
  await redis.incr(rateLimitKey);
  await redis.expire(rateLimitKey, RATE_LIMIT_WINDOW);

  if (twilioClient && serviceSid) {
    // Production: Use Twilio Verify
    await twilioClient.verify.v2
      .services(serviceSid)
      .verifications.create({
        to: phone,
        channel: 'sms',
      });
  } else {
    // Development: Generate and store mock OTP
    const code = generateOTP();
    const otpKey = `otp:${phone}`;

    await redis.set(otpKey, code);
    await redis.expire(otpKey, OTP_EXPIRATION);

    // Log OTP in development
    console.log(`[DEV] OTP for ${phone}: ${code}`);
  }
}

/**
 * Verify OTP code
 * Returns true if valid, false otherwise
 */
export async function verifyOTP(phone: string, code: string): Promise<boolean> {
  if (twilioClient && serviceSid) {
    // Production: Use Twilio Verify
    try {
      const verification = await twilioClient.verify.v2
        .services(serviceSid)
        .verificationChecks.create({
          to: phone,
          code,
        });

      return verification.status === 'approved';
    } catch (error) {
      console.error('Twilio verification error:', error);
      return false;
    }
  } else {
    // Development: Check stored OTP
    const otpKey = `otp:${phone}`;
    const storedCode = await redis.get(otpKey);

    if (storedCode === code) {
      // Delete OTP after successful verification
      await redis.del(otpKey);
      return true;
    }

    return false;
  }
}

/**
 * Generate 6-digit OTP code
 */
function generateOTP(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}
