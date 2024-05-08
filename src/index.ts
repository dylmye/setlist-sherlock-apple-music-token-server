import { APIGatewayEvent, APIGatewayProxyCallbackV2, Handler } from "aws-lambda";
import jwt from "jsonwebtoken";

export const handler: Handler<APIGatewayEvent> = (event, context, callback: APIGatewayProxyCallbackV2) => {
    const nowstamp = Date.now();

    const privateKeyWithNewlines = process.env.MUSICKIT_PRIVATE_KEY?.replace("BEGIN PRIVATE KEY-----", "BEGIN PRIVATE KEY-----\n")?.replace("-----END", "\n-----END");

    const header: jwt.JwtHeader = {
        alg: "ES256",
        kid: process.env.MUSICKIT_PRIVATE_KEY_ID
    }

    const claim: jwt.JwtPayload = {
        iss: process.env.APPLE_TEAM_ID,
        iat: nowstamp,
        exp: nowstamp + 15777000, // 6 months time
        origin: ["https://setlist-sherlock.dylmye.me"] // replace/remove this if you're using this somewhere else
    }

    const token = jwt.sign(claim, privateKeyWithNewlines!, {
        header,
        algorithm: "ES256"
    })

    callback(null, {
        statusCode: 200,
        body: JSON.stringify({ token })
    });
};