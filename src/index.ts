import type { Handler, Response } from "scaleway-functions";
import {
  SignJWT,
  importPKCS8,
  type JWTHeaderParameters,
  type JWTPayload,
} from "jose";

export const handler: Handler<Response> = async (_ev, _cx, _cb) => {
  const privateKeyWithNewlines = process.env.MUSICKIT_PRIVATE_KEY?.replace(
    "BEGIN PRIVATE KEY-----",
    "BEGIN PRIVATE KEY-----\n"
  )?.replace("-----END", "\n-----END");

  const header: JWTHeaderParameters = {
    alg: "ES256",
    kid: process.env.MUSICKIT_PRIVATE_KEY_ID,
    typ: "JWT",
  };

  const claim: JWTPayload = {
    iss: process.env.APPLE_TEAM_ID,
    origin: ["https://setlist-sherlock.dylmye.me"], // replace/remove this if you're using this somewhere else
  };

  const secret = await importPKCS8(privateKeyWithNewlines!, "ES256");

  const token = await new SignJWT(claim)
    .setProtectedHeader(header)
    .setIssuedAt()
    .setExpirationTime("180 days")
    .sign(secret);

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ token }),
  };
};
