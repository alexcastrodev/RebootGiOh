import { deck } from './_deck.js';

export default function handler(req, res) {
    const { search } = req.query;
    const host = `${req.headers['x-forwarded-proto'] || 'https'}://${req.headers.host}`;
    const term = search ? search.toLowerCase() : null;

    const cards = [];
    for (const [identifier, filename] of deck) {
        if (term && !identifier.includes(term)) continue;
        cards.push({ identifier });
    }

    res.json({ cards });
}
