import 'beercss';
import 'material-dynamic-colors';
// Self-hosted so the site makes no third-party requests, matching what the app
// claims about itself. Bundled by Vite, never fetched from a font CDN.
import '@fontsource-variable/archivo';
import './style.css';
import { initShowcase } from './components/showcase.js';

function bootstrap() {
  // Initialize interactive showcase and marquee event delegators
  initShowcase();

  // Set Material 3 vibrant purple theme
  setTimeout(() => {
    if (window.ui) {
      window.ui('theme', '#7C4DFF');
    }
  }, 100);
}

if (document.readyState === 'complete' || document.readyState === 'interactive') {
  bootstrap();
} else {
  document.addEventListener('DOMContentLoaded', bootstrap);
}
