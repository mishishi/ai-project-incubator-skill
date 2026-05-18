import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// TODO: replace {project-name} with actual project name
export default defineConfig({
  base: '/{project-name}/',
  plugins: [react(), tailwindcss()],
})