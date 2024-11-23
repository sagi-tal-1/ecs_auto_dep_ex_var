FROM nginx:latest

# Remove the default nginx configuration
RUN rm /etc/nginx/conf.d/default.conf

# Copy our custom configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf
