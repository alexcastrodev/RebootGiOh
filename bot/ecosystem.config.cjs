module.exports = {
  apps: [
    {
      name: 'deck-agent-bot',
      script: 'index.js',
      interpreter: 'node',
      watch: false,
      restart_delay: 5000,
      max_restarts: 10,
    },
  ],
};
