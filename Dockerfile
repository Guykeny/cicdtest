FROM node:20-alpine AS deps

# Dossier de travail dans le container
WORKDIR /app

# On copie SEULEMENT les fichiers de dépendances
# (astuce : si package.json ne change pas, Docker réutilise le cache)
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm ci

FROM node:20-alpine AS builder

WORKDIR /app

# Récupérer les node_modules de l'étape précédente
COPY --from=deps /app/node_modules ./node_modules

# Copier tout le code source
COPY . .

# Compiler Next.js pour la production
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app

# Bonne pratique : ne pas tourner en root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copier uniquement ce qui est nécessaire pour tourner
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Utiliser l'utilisateur non-root
USER nextjs

# Le port exposé par Next.js
EXPOSE 3000

# Variable d'environnement pour la prod
ENV NODE_ENV=production
ENV PORT=3000

# Commande de démarrage
CMD ["node", "server.js"]