const defaultTheme = require('tailwindcss/defaultTheme')
const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './tmp/gems/*/app/views/**/*.html.erb',
    './tmp/gems/*/app/helpers/**/*.rb',
    './tmp/gems/*/app/assets/stylesheets/**/*.css',
    './tmp/gems/*/app/javascript/**/*.js',
  ],
  darkMode: 'media',
  theme: {
    extend: {
      fontSize: {
        'xs': '.81rem',
      },
      colors: {
        red: {
          400: '#ee8989',
          500: '#e86060',
          900: '#652424',
        },

        yellow: {
          400: '#fcedbe',
          500: '#fbe6a8',
          900: '#6e6446',
        },

        blue: {
          300: '#95acff', // light
          400: '#448eef', // lightish
          500: '#047bf8', // DEFAULT
          600: '#0362c6', // dark
          700: '#1c4cc3', // vividBlue-700
          800: '#0e369a', // vividBlue-800
          900: '#00369D', // darker
        },

        // This is a weird one-off for dark-mode.
        lilac: {
          200: '#b3bcde',
        },

        slate: {
          900: '#232942',
          800: '#2b344e',
          700: '#323c58',
          600: '#4D566F',
          500: '#777E94',
          400: '#9facc7',
          300: '#ccd9e8',
        },

        sealBlue: {
          100: '#232942', // slate-900
          200: '#b3bcde', // X
          300: '#2b344e', // slate-800
          400: '#323c58', // slate-700
          500: '#4D566F', // slate-600
          600: '#777E94', // slate-500
          700: '#9facc7', // slate-400
          800: '#b3bcde', // X
          900: '#ccd9e8', // slate-300
        },

        black: {
          100: '#000000',
          200: '#101112',
          300: '#171818',
          400: '#292b2c',
          DEFAULT: '#000000',
        }
      },
      fontFamily: {
        // "Avenir Next W01", "Proxima Nova W01", "", -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
