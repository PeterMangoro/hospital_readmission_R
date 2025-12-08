# Quick Start: Blog Post for Nuxt

## ✅ What's Been Created

1. **BLOG_POST.Rmd** - Your blog post source file
2. **convert_to_nuxt.R** - Conversion script
3. **content/blog/hospital-readmissions.md** - Nuxt Content markdown file
4. **public/images/blog/** - All blog images
5. **blog_assets/** - Local reference copies

## 🚀 Quick Steps to Use in Nuxt

### 1. Copy Files to Your Nuxt Project

```bash
# From your projects directory
cp -r content/ /path/to/your/nuxt/project/
cp -r public/images/blog/ /path/to/your/nuxt/project/public/images/
```

### 2. Install Nuxt Content (if not already installed)

```bash
cd /path/to/your/nuxt/project
npm install @nuxt/content
```

### 3. Configure nuxt.config.js

```js
export default {
  modules: [
    '@nuxt/content'
  ]
}
```

### 4. Create Blog Page

Create `pages/blog/[slug].vue`:

```vue
<template>
  <article class="prose prose-lg max-w-4xl mx-auto p-8">
    <h1>{{ post.title }}</h1>
    <p class="text-gray-600">{{ post.description }}</p>
    <nuxt-content :document="post" />
  </template>
</template>

<script>
export default {
  async asyncData({ $content, params }) {
    const post = await $content('blog', params.slug).fetch()
    return { post }
  }
}
</script>
```

### 5. View Your Blog Post

Visit: `http://localhost:3000/blog/hospital-readmissions`

## 🔄 Regenerating the Blog Post

After editing `BLOG_POST.Rmd`:

```r
source("convert_to_nuxt.R")
```

Then copy the updated files to your Nuxt project again.

## 📝 Customizing

- Edit `BLOG_POST.Rmd` for content changes
- Edit `convert_to_nuxt.R` to change the markdown template
- Edit `content/blog/hospital-readmissions.md` directly (but it will be overwritten on regeneration)

## 📁 File Locations

- **Source**: `BLOG_POST.Rmd`
- **Generated Markdown**: `content/blog/hospital-readmissions.md`
- **Images**: `public/images/blog/*.png`
- **Data**: `public/images/blog/model_comparison.json`

## 🎨 Styling Tips

Add Tailwind Typography for better prose styling:

```bash
npm install @tailwindcss/typography
```

Then in your Nuxt config:

```js
tailwindcss: {
  config: {
    plugins: [require('@tailwindcss/typography')]
  }
}
```

And use the `prose` class in your template (already included above).

---

**That's it!** Your blog post is ready for Nuxt Content. 🎉

