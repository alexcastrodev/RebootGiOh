import { Client, GatewayIntentBits, Events } from 'discord.js'

const AGENT_URL = process.env.AGENT_URL || 'https://reboot-deck.kurz.fyi'

const client = new Client({ intents: [GatewayIntentBits.Guilds] })

client.once(Events.ClientReady, c => {
  console.log(`Ready as ${c.user.tag}`)
})

client.on(Events.InteractionCreate, async interaction => {
  if (!interaction.isChatInputCommand()) return

  const discordUserId = interaction.user.id

  if (interaction.commandName === 'register') {
    await interaction.deferReply({ flags: 64 })
    const host = interaction.options.getString('host')

    try {
      const res = await fetch(`${AGENT_URL}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ host, discord_user_id: discordUserId }),
      })
      const data = await res.json()

      if (!res.ok) {
        await interaction.editReply(`Error: ${data.error}`)
        return
      }

      await interaction.editReply(`Node registered.\n**Host:** ${data.host}`)
    } catch (e) {
      await interaction.editReply(`Failed to reach agent: ${e.message}`)
    }
  }

  if (interaction.commandName === 'invoke') {
    await interaction.deferReply()
    const cardId = interaction.options.getString('card')

    try {
      const res = await fetch(`${AGENT_URL}/invoke/${discordUserId}/${cardId}`)

      if (res.status === 404) {
        await interaction.editReply(`Card **${cardId}** not found.`)
        return
      }

      if (!res.ok) {
        await interaction.editReply(`Error: server returned ${res.status}`)
        return
      }

      const data = await res.json()

      await interaction.editReply({ content: `**${cardId}**`, files: [data.card_url] })
    } catch (e) {
      await interaction.editReply(`Failed to reach agent: ${e.message}`)
    }
  }
})

client.login(process.env.DISCORD_TOKEN)
