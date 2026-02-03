import * as jose from 'jose';

const JWT_SECRET = process.env.JWT_SECRET || 'vilo-dev-secret-change-in-production';
const JWT_ISSUER = 'vilo';
const JWT_AUDIENCE = 'vilo-app';

// Token expiration times
const ACCESS_TOKEN_EXPIRATION = '7d';
const REFRESH_TOKEN_EXPIRATION = '30d';

interface TokenPayload {
  userId: string;
  phone: string;
}

// Create secret key from string
const getSecretKey = () => new TextEncoder().encode(JWT_SECRET);

/**
 * Create a JWT access token
 */
export async function createToken(payload: TokenPayload): Promise<string> {
  const jwt = await new jose.SignJWT({ ...payload })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setExpirationTime(ACCESS_TOKEN_EXPIRATION)
    .sign(getSecretKey());

  return jwt;
}

/**
 * Create a refresh token (longer expiration)
 */
export async function createRefreshToken(payload: TokenPayload): Promise<string> {
  const jwt = await new jose.SignJWT({ ...payload, type: 'refresh' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setExpirationTime(REFRESH_TOKEN_EXPIRATION)
    .sign(getSecretKey());

  return jwt;
}

/**
 * Verify and decode a JWT token
 * Returns payload if valid, null otherwise
 */
export async function verifyToken(token: string): Promise<TokenPayload | null> {
  try {
    const { payload } = await jose.jwtVerify(token, getSecretKey(), {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    });

    return {
      userId: payload.userId as string,
      phone: payload.phone as string,
    };
  } catch (error) {
    // Token is invalid or expired
    return null;
  }
}

/**
 * Decode token without verification (for debugging)
 * WARNING: Do not use for authentication
 */
export function decodeToken(token: string): jose.JWTPayload | null {
  try {
    return jose.decodeJwt(token);
  } catch {
    return null;
  }
}
