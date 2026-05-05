import { createTheme } from '@mantine/core';

export const NAVY   = '#121C57';
export const ORANGE = '#F7752A';
export const BG     = '#f4f5f9';

export const theme = createTheme({
  primaryColor: 'orange',
  fontFamily: '"DM Sans", -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif',
  colors: {
    navy: [
      '#eef0f8',
      '#d5d9ee',
      '#adb4dd',
      '#848fcb',
      '#5c6aba',
      '#2e3d9c',
      '#121C57',
      '#0e1645',
      '#0a1033',
      '#060a21',
    ],
    orange: [
      '#fff3ec',
      '#ffe4d0',
      '#ffc9a0',
      '#ffad6f',
      '#ff913e',
      '#F7752A',
      '#ea5f1e',
      '#d44813',
      '#be3209',
      '#a81e00',
    ],
  },
  defaultRadius: 'md',
  components: {
    Button: {
      defaultProps: { radius: 'xl' },
    },
    TextInput: {
      defaultProps: { radius: 'xl' },
    },
    PasswordInput: {
      defaultProps: { radius: 'xl' },
    },
  },
});
