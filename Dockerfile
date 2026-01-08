# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Installer outils pour compiler dépendances natives (Angular/Nx SSR)
RUN apk add --no-cache python3 make g++ bash git

# Copy package files
COPY package*.json ./

# Installer toutes les dépendances
RUN npm ci

# Copy source code
COPY . .

# Build de l'application Angular + SSR
RUN npm run build:prod

# Stage 2: Production
FROM node:20-alpine AS production

WORKDIR /app

# Copy package files
COPY package*.json ./

# Installer uniquement les dépendances de production
RUN npm ci --only=production && npm cache clean --force

# Copier l'application buildée depuis le builder
COPY --from=builder /app/dist ./dist

# Copier le fichier d'environnement template
COPY .env.exemple ./.env.exemple

# Installer wget pour health checks
RUN apk add --no-cache wget

# Créer un utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S angular -u 1001

USER angular

EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4000/api/health || exit 1

# Lancer le SSR
CMD ["npm", "run", "serve:ssr:anything-ipsum"]
