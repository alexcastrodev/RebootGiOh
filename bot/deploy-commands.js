import { REST, Routes, SlashCommandBuilder } from 'discord.js'

const commands = [
  new SlashCommandBuilder()
    .setName('register')
    .setDescription('Register a node with a reachable host')
    .addStringOption(o =>
      o.setName('host')
        .setDescription('Public URL or IP:port of the node (e.g. http://1.2.3.4:8080)')
        .setRequired(true)
    )
    .addStringOption(o =>
      o.setName('name')
        .setDescription('Name for this node (e.g. main, backup) — unique per user')
        .setRequired(true)
    ),

  new SlashCommandBuilder()
    .setName('invoke')
    .setDescription('Draw a card from your deck node')
    .addStringOption(o =>
      o.setName('node')
        .setDescription('Node name you registered (e.g. main)')
        .setRequired(true)
    )
    .addStringOption(o =>
      o.setName('card')
        .setDescription('Card identifier to fetch (e.g. exodia)')
        .setRequired(true)
    ),
].map(c => c.toJSON())

const rest = new REST().setToken(process.env.DISCORD_TOKEN)
const { DISCORD_APP_ID, DISCORD_GUILD_ID } = process.env

const route = DISCORD_GUILD_ID
  ? Routes.applicationGuildCommands(DISCORD_APP_ID, DISCORD_GUILD_ID)
  : Routes.applicationCommands(DISCORD_APP_ID)

await rest.put(route, { body: commands })
console.log(`Deployed ${commands.length} commands.`)
