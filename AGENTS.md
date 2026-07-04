# Vercel Deployment Notes

## Critical: Always use `--force` for deploys
Vercel caches the build output aggressively. Without `--force`, it restores old `api/index.js`.
```bash
npx vercel deploy --prod --force --yes
```

## SSO Protection
The project has SSO deployment protection enabled (`all_except_custom_domains`). If the deployment shows a Vercel login page, disable it:
```bash
npx vercel project protection disable aquatrack --sso
```

## Serverless Function Entry Point
`api/index.js` is the single serverless function. It re-exports the Express app:
```js
module.exports = require('../server/index');
```

## All routes/models live in `server/`
Vercel deploys all files from the project root, so relative requires (`../server/...`) work.

## No `app.listen()` in production
`server/index.js` wraps `app.listen()` in `if (require.main === module)`, so it only runs locally.

## Hobby Plan Limits
12 serverless functions max — keep everything in `api/index.js`.
