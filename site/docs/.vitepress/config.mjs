import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'DeepSeek Harness Blog',
  description: 'Markdown blog powered by DeepSeek Harness',
  cleanUrls: true,
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' }
    ],
    sidebar: []
  }
})
