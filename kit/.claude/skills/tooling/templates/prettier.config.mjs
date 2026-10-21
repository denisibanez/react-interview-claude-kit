/** @type {import('prettier').Config} */
export default {
  semi: true,
  singleQuote: true,
  trailingComma: 'all',
  printWidth: 100,
  // keep only if the repo uses Tailwind (sorts classes in the official order)
  plugins: ['prettier-plugin-tailwindcss'],
};
