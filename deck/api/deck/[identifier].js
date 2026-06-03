const deck = new Map([
    ['hide', 'hide.jpg'],
]);

export default function handler(req, res) {
    const { identifier } = req.query;
    const host = `${req.headers['x-forwarded-proto'] || 'https'}://${req.headers.host}`;

    const filename = deck.get(identifier);
    if (!filename) {
        return res.status(404).json({ error: 'Card not found' });
    }

    res.json({ card_url: `${host}/${filename}` });
}
