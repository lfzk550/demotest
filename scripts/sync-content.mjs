import fs from 'node:fs'
import path from 'node:path'

const src = path.resolve('content')
const dst = path.resolve('site/docs/posts')

fs.mkdirSync(dst, { recursive: true })

for (const name of fs.readdirSync(dst)) {
  if (name.endsWith('.md')) fs.rmSync(path.join(dst, name))
}

const files = fs.existsSync(src) ? fs.readdirSync(src).filter(x => x.endsWith('.md')) : []

for (const file of files) {
  fs.copyFileSync(path.join(src, file), path.join(dst, file))
}

const links = files.map(file => `- [${file.replace(/\.md$/, '')}](/posts/${file.replace(/\.md$/, '')})`).join('\n')
fs.writeFileSync(path.join(dst, 'index.md'), `# Articles\n\n${links || '暂无文章。'}\n`)
