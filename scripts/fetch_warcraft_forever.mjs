import { writeFile } from 'node:fs/promises';
import { Items, manifest } from 'https://warcraftforever.com/data/latest.mjs';

const [output = 'warcraft-forever-items.json', ...requested] = process.argv.slice(2);
const ids = [...new Set((requested.length ? requested : ['2321', '6470', '6471']).map(Number))];
if (ids.length > 50 || ids.some(id => !Number.isInteger(id) || id < 1 || id > 2147483647)) {
  throw new Error('Fournir au maximum 50 identifiants d’objets positifs.');
}

const published = await manifest();
const channel = published.channels[published.defaultChannel];
const dataset = channel?.datasets?.items;
if (!dataset) throw new Error('Le catalogue ne publie aucun jeu de données d’objets.');

const items = {};
for (const id of ids) {
  const response = await Items.get(id, { locale: 'frFR', dataset });
  if (response.dataset !== dataset || response.resource !== 'items') {
    throw new Error(`Réponse inattendue pour l’objet ${id}.`);
  }
  items[id] = response;
}
await writeFile(output, JSON.stringify({ dataset, build: channel.build, items }, null, 2) + '\n');
