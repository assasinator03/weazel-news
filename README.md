# Weazel News — version Cloudflare + Supabase (100 % gratuit)

Site : Cloudflare Workers (pages + API) · Données, photos, connexion Discord : Supabase.

## 0. Ce qu'il te faut
Un compte GitHub, un compte Cloudflare, un compte Supabase, un compte Discord. Aucun ne demande de carte bancaire pour l'offre gratuite.

## 1. Supabase
1. supabase.com → New project : nom `weazel-news`, un mot de passe de base (note-le), région Europe, offre Free.
2. Menu **SQL Editor** → New query → colle tout le fichier `schema.sql` → **Run**. (Il crée les tables, la sécurité et le compte patron `G.morel` / `12345`.)
3. Menu **Storage** → New bucket : nom exact `galerie`, active **Public bucket** → Create.
4. **Project Settings → API Keys** : note l'**URL du projet**, la clé publique (`anon` ou `publishable`) et la clé secrète (`service_role` ou `secret`). La clé secrète ne doit jamais être publiée ni mise sur GitHub. (Si un problème survient avec les nouvelles clés, utilise les « Legacy API keys ».)

## 2. Discord
1. discord.com/developers/applications → **New Application** → « Weazel News ».
2. Menu **OAuth2** : copie le **Client ID** ; clique **Reset Secret** et copie le **Client Secret**.
3. Dans Supabase : **Authentication → Providers → Discord** : copie la **Callback URL** (`https://<ref>.supabase.co/auth/v1/callback`).
4. Retour sur Discord → OAuth2 → **Redirects** → colle cette URL → Save.
5. Retour dans Supabase (Providers → Discord) : active **Discord Enabled**, colle Client ID et Client Secret → Save.

## 3. Cloudflare
**Méthode A — avec GitHub (recommandée)**
1. GitHub : crée un dépôt privé et envoie-y tous les fichiers du dossier (Add file → Upload files), en gardant `src/`, `public/`, `wrangler.jsonc`, `package.json`.
2. dash.cloudflare.com → **Workers & Pages → Create → Import a repository** → choisis le dépôt. Nom du projet : `weazel-news` (comme dans `wrangler.jsonc`). Commande de build : vide. Commande de déploiement : `npx wrangler deploy`. → Deploy.
3. Ouvre le Worker → **Settings → Variables and Secrets** → ajoute :
   - `SUPABASE_URL` = l'URL du projet
   - `SUPABASE_ANON_KEY` = la clé publique
   - `SUPABASE_SERVICE_KEY` = la clé secrète (type **Secret**)
4. Relance un déploiement (Deployments → Retry/Redeploy). Ton adresse : `https://weazel-news.<ton-compte>.workers.dev`.

**Méthode B — sans GitHub (Node.js installé)**
```
npm install
npx wrangler login
npx wrangler deploy
npx wrangler secret put SUPABASE_URL
npx wrangler secret put SUPABASE_ANON_KEY
npx wrangler secret put SUPABASE_SERVICE_KEY
```

## 4. Relier Supabase au site
Supabase → **Authentication → URL Configuration** :
- **Site URL** = ton adresse Cloudflare
- **Redirect URLs** : ajoute `https://weazel-news.<ton-compte>.workers.dev/**` (et ton domaine perso si tu en as un).

## 5. Test
1. Ouvre le site → Espace journalistes → `G.morel` / `12345` → choisis ton mot de passe.
2. Onglet Équipe : crée un journaliste, note le code temporaire affiché.
3. Rédaction : publie un article avec une photo.
4. Déconnecte-toi, clique « Connexion Discord » : tu reviens connecté et peux liker/commenter.
5. Onglet Discord (patron) : colle un webhook de salon pour annoncer chaque article.

## 6. Domaine perso (optionnel)
Cloudflare → Worker → Settings → **Domains & Routes → Add → Custom domain** (domaine géré par Cloudflare). Puis mets à jour la Site URL et les Redirect URLs dans Supabase.

## 7. Limites gratuites et entretien
- Supabase Free met le projet en pause après ~1 semaine sans activité : une tâche Cloudflare quotidienne (déjà incluse) interroge la base pour l'éviter. Données conservées en cas de pause ; bouton « Resume project » pour réveiller.
- Pas de sauvegarde automatique en Free : exporte régulièrement tes tables (Table Editor → Export).
- Photos : 1 Go de stockage ; vidéos 25 Mo max chacune.
- Cloudflare : 100 000 requêtes API par jour ; les fichiers du site sont illimités.

## 8. Dépannage
- « Erreur serveur » : vérifie les 3 variables, puis que `schema.sql` a bien été exécuté.
- Discord « redirect_uri invalide » : l'URL de rappel Discord doit être exactement celle de Supabase ; la Site URL/Redirect URL Supabase doit contenir l'adresse du site.
- Envoi de photo refusé : le bucket doit s'appeler `galerie` et être public.
- Projet en pause : Supabase → Resume project.
