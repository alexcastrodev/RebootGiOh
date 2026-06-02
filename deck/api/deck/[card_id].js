const CARDS = {
  hide: { card_url: "https://deck-agent.vercel.app/hide.jpg" },
};

export default function handler(req, res) {
  const { card_id } = req.query;
  const card = CARDS[card_id];

  if (!card) {
    return res.status(404).json({ error: `card '${card_id}' not found` });
  }

  res.status(200).json(card);
}
