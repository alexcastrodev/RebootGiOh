import { Client, GatewayIntentBits, Events } from 'discord.js'

const AGENT_URL = process.env.AGENT_URL || 'https://reboot-deck.kurz.fyi'

const client = new Client({ intents: [GatewayIntentBits.Guilds] })

client.once(Events.ClientReady, c => {
  console.log(`Ready as ${c.user.tag}`)
})

client.on(Events.InteractionCreate, async interaction => {
  if (interaction.isAutocomplete()) {
    if (interaction.commandName === 'invoke') {
      const query = interaction.options.getFocused()
      const discordUserId = interaction.user.id
      try {
        const res = await fetch(`${AGENT_URL}/search/${discordUserId}?q=${encodeURIComponent(query)}`)
        const data = res.ok ? await res.json() : { cards: [] }
        await interaction.respond((data.cards || []).slice(0, 25))
      } catch {
        await interaction.respond([])
      }
    }
    return
  }

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

  if (interaction.commandName === 'revoke') {
    await interaction.deferReply({ flags: 64 })

    try {
      const res = await fetch(`${AGENT_URL}/revoke`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ discord_user_id: discordUserId }),
      })
      const data = await res.json()

      if (!res.ok) {
        await interaction.editReply(`Error: ${data.error}`)
        return
      }

      await interaction.editReply('Server removed successfully.')
    } catch (e) {
      await interaction.editReply(`Failed to reach agent: ${e.message}`)
    }
  }

  if (interaction.commandName === 'trap') {
    await interaction.deferReply()

    try {
      const url = `${AGENT_URL}/trap`
      const res = await fetch(url)
      if (!res.ok) throw new Error(`Agent returned ${res.status}`)
      const buffer = Buffer.from(await res.arrayBuffer())
      await interaction.editReply({ files: [{ attachment: buffer, name: 'trap.jpg' }] })
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
