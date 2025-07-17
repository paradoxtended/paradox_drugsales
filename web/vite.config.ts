import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import path from 'node:path'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  return {
    plugins: [svelte()],
    base: './',
    resolve: {
      alias: {
        $lib: path.resolve('./src/lib')
      },
    },
    ...(mode === 'development' && { publicDir: '../' }),
    build: {
      outDir: 'dist',
      target: 'es2023',
    },
  };
});