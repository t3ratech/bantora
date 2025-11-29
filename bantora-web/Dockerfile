# Stage 1: Serve with Nginx
FROM nginx:alpine

# Copy Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build artifacts from host
COPY bantora_app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
