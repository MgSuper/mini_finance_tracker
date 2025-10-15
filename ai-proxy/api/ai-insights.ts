import type { VercelRequest, VercelResponse } from '@vercel/node';
import OpenAI from 'openai';
import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

let adminApp: App | null = null;

function getAdminApp() {
    if (!getApps().length) {
        const sa = process.env.FIREBASE_SERVICE_ACCOUNT;
        if (!sa) throw new Error('Missing FIREBASE_SERVICE_ACCOUNT');
        const json = JSON.parse(sa);
        adminApp = initializeApp({ credential: cert(json) });
    }
    return adminApp!;
}

async function verifyFirebaseIdToken(authHeader?: string) {
    const token = authHeader?.match(/^Bearer (.+)$/)?.[1];
    if (!token) throw new Error('Missing Authorization header');
    const app = getAdminApp();
    const decoded = await getAuth(app).verifyIdToken(token, true);
    return decoded.uid as string;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
    try {
        if (req.method === 'OPTIONS') {
            res.setHeader('Access-Control-Allow-Origin', process.env.ALLOW_ORIGIN ?? '*');
            res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
            res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
            return res.status(204).send('');
        }
        if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

        res.setHeader('Access-Control-Allow-Origin', process.env.ALLOW_ORIGIN ?? '*');

        const uid = await verifyFirebaseIdToken(req.headers.authorization);

        const { metrics, model = 'gpt-4o-mini' } = req.body ?? {};
        if (!metrics || typeof metrics !== 'object') {
            return res.status(400).json({ error: "Invalid 'metrics' payload" });
        }

        const prompt = `You are a budgeting assistant. Summarize the user's monthly finances in 2–3 short, plain sentences.
Prefer concrete numbers and comparisons month-over-month. Avoid advice/promises.
JSON:
${JSON.stringify(metrics)}`;

        const client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY! });
        const completion = await client.chat.completions.create({
            model,
            temperature: 0.3,
            messages: [
                { role: 'system', content: 'You are a concise financial summarizer.' },
                { role: 'user', content: prompt },
            ],
        });

        const text = completion.choices[0]?.message?.content?.trim() ?? '';
        return res.status(200).json({ uid, text });
    } catch (e: any) {
        console.error('INSIGHTS_PROXY_ERROR', e?.message, e?.stack);
        return res.status(401).json({ error: e?.message ?? 'Unauthorized' });
    }
}
