# Blog Post Workflow for Nuxt Content

This guide explains how to convert your R Markdown blog post to Nuxt Content format.

## Overview

The workflow consists of:
1. **BLOG_POST.Rmd** - Your blog post written in R Markdown
2. **convert_to_nuxt.R** - Conversion script that prepares everything for Nuxt
3. **Generated outputs** - Markdown file and assets ready for Nuxt Content

## Quick Start

### Step 1: Install Required Packages

```r
install.packages(c("rmarkdown", "knitr", "jsonlite", "ggplot2", "dplyr", "pROC", "caret"))
```

### Step 2: Run the Conversion Script

```r
source("convert_to_nuxt.R")
```

This will:
- Render the blog post to HTML (generates all plots)
- Copy plots to `blog_assets/images/` and `public/images/blog/`
- Export model comparison data to JSON
- Generate a Nuxt Content markdown file at `content/blog/hospital-readmissions.md`

### Step 3: Copy to Your Nuxt Project

1. **Copy the content directory:**
   ```bash
   cp -r content/ /path/to/your/nuxt/project/
   ```

2. **Copy the public images:**
   ```bash
   cp -r public/images/blog/ /path/to/your/nuxt/project/public/images/
   ```

3. **Update links in the markdown file** if your Nuxt setup uses different paths

## Directory Structure

After running the conversion script, you'll have:

```
projects/
├── BLOG_POST.Rmd              # Source blog post
├── convert_to_nuxt.R          # Conversion script
├── blog_assets/                # Local assets (for reference)
│   ├── images/                 # Blog images
│   └── data/                   # JSON data files
├── content/                    # Nuxt Content directory
│   └── blog/
│       └── hospital-readmissions.md
└── public/                     # Public assets for Nuxt
    └── images/
        └── blog/               # Images referenced in markdown
```

## Nuxt Content Setup

### 1. Install Nuxt Content Module

In your Nuxt project:

```bash
npm install @nuxt/content
```

### 2. Configure nuxt.config.js

```js
export default {
  modules: [
    '@nuxt/content'
  ],
  content: {
    // Your content configuration
  }
}
```

### 3. Create Blog Page

Create `pages/blog/[slug].vue`:

```vue
<template>
  <article class="prose prose-lg max-w-4xl mx-auto">
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

### 4. Create Blog Index Page

Create `pages/blog/index.vue`:

```vue
<template>
  <div>
    <h1>Blog Posts</h1>
    <div v-for="post in posts" :key="post.slug">
      <NuxtLink :to="`/blog/${post.slug}`">
        <h2>{{ post.title }}</h2>
      </NuxtLink>
      <p>{{ post.description }}</p>
    </div>
  </div>
</template>

<script>
export default {
  async asyncData({ $content }) {
    const posts = await $content('blog')
      .sortBy('date', 'desc')
      .fetch()
    return { posts }
  }
}
</script>
```

## Customizing the Blog Post

### Edit the Source

Edit `BLOG_POST.Rmd` to change:
- Content and narrative
- Code chunks and analysis
- Visualizations

### Regenerate

After editing, run the conversion script again:

```r
source("convert_to_nuxt.R")
```

This will update:
- All plots (if code changed)
- The markdown file
- JSON data files

### Manual Edits

You can also edit `content/blog/hospital-readmissions.md` directly, but remember:
- If you regenerate, manual edits will be overwritten
- Keep the frontmatter format consistent
- Image paths should match your Nuxt setup

## Frontmatter Options

The generated markdown includes frontmatter like:

```yaml
---
title: "Your Blog Post Title"
description: "Brief description for SEO and previews"
date: 2025-01-15
image: "/images/blog/readmission_dist.png"
category: "Machine Learning"
tags: ["R", "Machine Learning", "Healthcare"]
---
```

You can customize this in the `convert_to_nuxt.R` script or edit it directly in the markdown file.

## Image Optimization

For better performance, consider:

1. **Optimize images** before copying:
   ```r
   # In convert_to_nuxt.R, add image optimization
   library(magick)
   img <- image_read("source.png")
   img <- image_resize(img, "1200x")
   image_write(img, "optimized.png", quality = 85)
   ```

2. **Use WebP format** for better compression

3. **Lazy load images** in your Nuxt components

## Troubleshooting

### Images Not Showing

- Check that images are in `public/images/blog/`
- Verify image paths in markdown match your Nuxt public directory
- Ensure Nuxt is serving static files correctly

### Markdown Not Rendering

- Check that Nuxt Content module is installed and configured
- Verify the markdown file is in the correct `content/` directory
- Check for syntax errors in the markdown file

### Plots Not Generating

- Ensure all required R packages are installed
- Check that source data files exist (`data_clean.csv`, `plots/*.csv`)
- Verify R Markdown can render successfully

## Next Steps

1. **Customize the blog post** to match your writing style
2. **Add more sections** if needed (code snippets, detailed analysis)
3. **Style the Nuxt pages** with Tailwind CSS or custom CSS
4. **Add SEO meta tags** in your Nuxt page components
5. **Set up RSS feed** for your blog
6. **Add comments system** (e.g., Disqus, Giscus)

## Resources

- [Nuxt Content Documentation](https://content.nuxtjs.org/)
- [R Markdown Guide](https://rmarkdown.rstudio.com/)
- [Nuxt.js Documentation](https://nuxt.com/)

---

**Last Updated**: January 2025

