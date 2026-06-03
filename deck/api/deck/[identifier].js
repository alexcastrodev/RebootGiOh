export default function handler(req, res) {
    const { identifier } = req.query;
    const path = `/${identifier}.jpg`;

    if (!path) {
        return res.status(404).json({ error: 'Not found' });
    }

    res.json({ card_url: path });
}
