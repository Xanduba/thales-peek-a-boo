/*
  Service worker: makes the app work fully offline after the first visit.

  IMPORTANT: when you change ANY file listed below (or add photos/sounds),
  bump CACHE_VERSION so installed devices download the new files.
*/
'use strict';

var CACHE_VERSION = 'v1';
var CACHE_NAME = 'peek-a-boo-' + CACHE_VERSION;

var APP_FILES = [
  './',
  'index.html',
  'tailwind.css',
  'manifest.webmanifest',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-maskable-512.png',
  'icons/apple-touch-icon.png',
  'Assets/images/mamae.png',
  'Assets/images/papai.png',
  'Assets/images/thales.png',
  'Assets/images/vovo.png',
  'Assets/audio/mamae.mp3',
  'Assets/audio/papai.mp3',
  'Assets/audio/thales.mp3',
  'Assets/audio/vovo.mp3'
];

/* ---------- Install: download everything up front ---------- */
self.addEventListener('install', function (event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function (cache) {
      // cache: 'reload' bypasses the browser's HTTP cache so we store fresh copies
      return cache.addAll(APP_FILES.map(function (url) {
        return new Request(url, { cache: 'reload' });
      }));
    }).then(function () {
      return self.skipWaiting();
    })
  );
});

/* ---------- Activate: remove caches from older versions ---------- */
self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (key) {
        if (key.indexOf('peek-a-boo-') === 0 && key !== CACHE_NAME) {
          return caches.delete(key);
        }
      }));
    }).then(function () {
      return self.clients.claim();
    })
  );
});

/* ---------- Fetch: cache first, network as fallback ---------- */
self.addEventListener('fetch', function (event) {
  var request = event.request;
  if (request.method !== 'GET') return;
  if (new URL(request.url).origin !== self.location.origin) return;

  // Page navigations always get the cached app shell (works offline).
  if (request.mode === 'navigate') {
    event.respondWith(
      caches.match('index.html', { cacheName: CACHE_NAME }).then(function (cached) {
        return cached || fetch(request);
      })
    );
    return;
  }

  // Audio on iOS Safari (and sometimes Chrome) is requested in byte ranges.
  // Serve the matching slice of the cached file as "206 Partial Content".
  if (request.headers.has('range')) {
    event.respondWith(
      caches.match(request.url, { cacheName: CACHE_NAME, ignoreSearch: true }).then(function (cached) {
        return cached ? rangeResponse(request, cached) : fetch(request);
      })
    );
    return;
  }

  event.respondWith(
    caches.match(request, { cacheName: CACHE_NAME, ignoreSearch: true }).then(function (cached) {
      return cached || fetch(request);
    })
  );
});

function rangeResponse(request, response) {
  return response.arrayBuffer().then(function (buffer) {
    var size = buffer.byteLength;
    var match = /^bytes=(\d*)-(\d*)$/.exec(request.headers.get('range').trim());
    var type = response.headers.get('Content-Type') || 'application/octet-stream';

    if (!match || (match[1] === '' && match[2] === '')) {
      return new Response(buffer, { status: 200, headers: { 'Content-Type': type } });
    }

    var start, end;
    if (match[1] === '') {                       // "bytes=-500" -> last 500 bytes
      start = Math.max(0, size - parseInt(match[2], 10));
      end = size - 1;
    } else {
      start = parseInt(match[1], 10);
      end = match[2] === '' ? size - 1 : Math.min(parseInt(match[2], 10), size - 1);
    }

    if (start >= size || start > end) {
      return new Response(null, {
        status: 416,
        statusText: 'Range Not Satisfiable',
        headers: { 'Content-Range': 'bytes */' + size }
      });
    }

    return new Response(buffer.slice(start, end + 1), {
      status: 206,
      statusText: 'Partial Content',
      headers: {
        'Content-Type': type,
        'Content-Range': 'bytes ' + start + '-' + end + '/' + size,
        'Content-Length': String(end - start + 1),
        'Accept-Ranges': 'bytes'
      }
    });
  });
}
