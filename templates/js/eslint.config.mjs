import baseConfig from '@gravity-ui/eslint-config';
import clientConfig from '@gravity-ui/eslint-config/client';
import importOrderConfig from '@gravity-ui/eslint-config/import-order';
import prettierConfig from '@gravity-ui/eslint-config/prettier';
import {defineConfig} from 'eslint/config';

export default defineConfig([
    ...baseConfig,
    ...clientConfig,
    ...prettierConfig,
    ...importOrderConfig,
]);
