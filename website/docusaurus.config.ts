import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'ICR Implementation Guide',
  tagline: "How to implement UNICEF's Integrated Campaign Registry and its reference tools",
  favicon: 'img/favicon.ico',

  url: 'https://docs.healthcampaigns.org',
  baseUrl: '/',

  organizationName: 'recodelabs',
  projectName: 'icr',

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  i18n: {defaultLocale: 'en', locales: ['en']},

  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/recodelabs/icr/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: 'ICR Implementation Guide',
      items: [
        {type: 'docSidebar', sidebarId: 'tutorialSidebar', position: 'left', label: 'Docs'},
        {href: 'https://icr.healthcampaigns.org', label: 'FHIR IG', position: 'right'},
        {href: 'https://github.com/recodelabs/icr', label: 'GitHub', position: 'right'},
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'ICR',
          items: [
            {label: 'FHIR Implementation Guide', href: 'https://icr.healthcampaigns.org'},
            {label: 'GitHub', href: 'https://github.com/recodelabs/icr'},
          ],
        },
      ],
      copyright: "UNICEF Integrated Campaign Registry.",
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
