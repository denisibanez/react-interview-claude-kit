/** Fast pre-commit: only staged files. Typecheck/tests belong to pre-push/CI. */
export default {
  '*.{ts,tsx,js,jsx,mjs,cjs}': ['eslint --fix --max-warnings=0', 'prettier --write'],
  '*.{css,scss,json,md,mdx,yml,yaml}': ['prettier --write'],
};
