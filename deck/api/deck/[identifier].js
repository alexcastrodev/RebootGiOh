export default function handler(req, res) {
    const { identifier } = req.query;
    const host = `${req.headers['x-forwarded-proto'] || 'https'}://${req.headers.host}`;

    res.json({ card_url: `${host}/${identifier}.jpg` });
}
