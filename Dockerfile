# Simple example Dockerfile for testing
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static content
COPY index.html /usr/share/nginx/html/
COPY health.html /usr/share/nginx/html/health

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]