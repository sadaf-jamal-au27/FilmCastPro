## Stage 1: Build the Vite React app
FROM node:20 AS build

# Set working directory
WORKDIR /app

# Copy dependency manifests (better layer caching)
COPY package*.json ./

# Install dependencies (use ci when lockfile is present)
RUN npm ci || npm install

# Copy the rest of the source code
COPY . .

# Build production files (outputs to /app/dist)
RUN npm run build

## Stage 2: Serve with Nginx
FROM nginx:stable-alpine

# Clean default html content
RUN rm -rf /usr/share/nginx/html/*

# Copy build output from Stage 1 to Nginx html folder
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
 