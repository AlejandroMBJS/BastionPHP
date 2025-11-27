<?php

return [
    // Global style system toggle
    // Set to true to use Tailwind CSS (CDN or built)
    // Set to false to use fallback CSS
    'useTailwind' => true,

    // Tailwind mode: 'cdn' or 'build'
    // 'cdn' - Load from CDN (faster development, no build required)
    // 'build' - Use compiled CSS from /public/css/app.css (production)
    'tailwindMode' => 'build',

    // Fallback CSS path (used when useTailwind = false)
    'fallbackCss' => '/css/fallback.css',
];
