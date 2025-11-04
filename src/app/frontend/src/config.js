// Configuración de la aplicación
const config = {
  // Hardcoded para producción - usa ruta relativa /api que el Ingress redirigirá al backend
  API_URL: '/api',
  NODE_ENV: 'production'
};

export default config;