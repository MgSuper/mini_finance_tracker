import type { VercelRequest, VercelResponse } from '@vercel/node';
import OpenAI from 'openai';

// Lazy-init firebase-admin so cold starts are smaller
let adminApp: import('firebase-admin/app').App | null = null;

async function verifyFirebaseIdToken(authHeader?: string) {
    const token = authHeader?.match(/^Bearer (.+)$/)?.[1];
    if (!token) throw new Error('Missing Authorization header');

    const { initializeApp, getApps, applicationDefault } = await import('firebase-admin/app');
    const { getAuth } = await import('firebase-admin/auth');
    if (!getApps().length) {
        adminApp = initializeApp({ credential: applicationDefault() });
    }
    const decoded = await getAuth().verifyIdToken(token, true);
    return decoded.uid as string;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
    try {
        if (req.method === 'OPTIONS') {
            // CORS preflight
            res.setHeader('Access-Control-Allow-Origin', process.env.ALLOW_ORIGIN ?? '*');
            res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
            res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
            return res.status(204).send('');
        }
        if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

        // CORS (allow only your app origin in prod)
        res.setHeader('Access-Control-Allow-Origin', process.env.ALLOW_ORIGIN ?? '*');

        const uid = await verifyFirebaseIdToken(req.headers.authorization);

        const { metrics, model = 'gpt-4o-mini' } = req.body ?? {};
        if (!metrics || typeof metrics !== 'object') {
            return res.status(400).json({ error: "Invalid 'metrics' payload" });
        }

        const prompt = `You are a budgeting assistant. Summarize the user's monthly finances in 2-3 short, plain sentences.
Prefer concrete numbers and comparisons month-over-month. Avoid advice or promises.
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
        return res.status(401).json({ error: e?.message ?? 'Unauthorized' });
    }
}
