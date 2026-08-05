import { defineConfig } from 'vite';
import fs from 'fs';
import path from 'path';

function htmlIncludePlugin() {
  return {
    name: 'html-include',
    handleHotUpdate({ file, server }) {
      if (file.endsWith('.html') && file.includes('/src/components/')) {
        server.ws.send({ type: 'full-reload', path: '*' });
      }
    },
    transformIndexHtml: {
      order: 'pre',
      handler(html, ctx) {
        return html.replace(/<include\s+src="([^"]+)"\s*\/>/g, (match, src) => {
          const filePath = path.resolve(ctx.filename ? path.dirname(ctx.filename) : process.cwd(), src);
          if (fs.existsSync(filePath)) {
            return fs.readFileSync(filePath, 'utf-8');
          }
          return match;
        });
      }
    }
  };
}

export default defineConfig({
  plugins: [htmlIncludePlugin()],
  // Served from a GitHub Pages project subpath (retransmit.github.io/Atrium/),
  // so built asset URLs have to carry that prefix. Without it the root-relative
  // /assets/... paths in index.html resolve against the domain root and 404.
  // Anything built in JS should use import.meta.env.BASE_URL, not a literal.
  base: '/Atrium/',
  server: {
    allowedHosts: [
      'atrium.betelgeuse.fun'
    ]
  }
});
