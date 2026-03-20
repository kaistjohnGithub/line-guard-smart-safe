# Smart Safe Guardian React Skeleton

This folder now has a structured webapp entry that uses the provided single-file React template as the design starting point.

## Files

- `smart-safe-guardian-react.html`: original template kept as reference
- `index.html`: new webapp entry for the project skeleton
- `src/data/mock-data.js`: mock domain data and integration mapping
- `src/app.js`: React app shell and section placeholders
- `src/styles.css`: shared styles for the new skeleton
- `backend/`: backend API and VLM service skeleton

## Current goal

This is the first structure pass only. It shows how the webapp can connect to:

- camera monitoring
- AI analysis scripts in `../vila-safety-poc`
- backend API endpoints in `./backend`
- SOP and rule management
- alerts and event workflows

## Next step options

1. Move sections from `smart-safe-guardian-react.html` into reusable components
2. Replace placeholder backend responses with real calls to the Python PoC
3. Replace mock data with real camera / incident / analysis payloads
