const CACHE_NAME = 'tech4all-kill-switch-v2';

console.log("Installing Ultimate Kill Switch Service Worker v2...");

self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  console.log("Activating Ultimate Kill Switch. Purging all caches permanently...");

  event.waitUntil(
    caches.keys().then(function (cacheNames) {
      return Promise.all(
        cacheNames.map(function (cacheName) {
          console.log('Obliterating cache:', cacheName);
          return caches.delete(cacheName);
        })
      );
    }).then(function () {
      return self.clients.claim();
    }).then(function () {
      // Force all open clients/tabs to reload immediately
      return self.clients.matchAll({ type: 'window' }).then(function (clients) {
        clients.forEach(function (client) {
          console.log('Forcing client reload:', client.url);
          client.navigate(client.url);
        });
      });
    })
  );
});

// A permanent bypass that guarantees NO cached assets are ever served or stored
self.addEventListener('fetch', function (event) {
  // Prevent caching of any assets, forcing fresh network fetches
  event.respondWith(
    fetch(event.request, { cache: 'no-store' }).catch(function () {
      // Fallback if no-store is not supported by event request type
      return fetch(event.request);
    })
  );
});
