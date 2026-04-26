# ─────────────────────────────────────────────────────────────
# Dockerfile — Weather App
# Serves the static app via nginx.
# Build args inject slot and version at image build time.
# ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

ARG SLOT=blue
ARG VERSION=1.0.0

# Copy app source
COPY app/ /usr/share/nginx/html/

# Inject runtime config: exposes APP_SLOT and APP_VERSION to JS
RUN echo "window.APP_SLOT='${SLOT}'; window.APP_VERSION='${VERSION}';" \
    > /usr/share/nginx/html/config.js

# Add config.js script tag to index.html
RUN sed -i 's|</head>|  <script src="config.js"></script>\n</head>|' \
    /usr/share/nginx/html/index.html

# Custom nginx config for SPA + healthz
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/healthz || exit 1
