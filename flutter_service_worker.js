console.log("Installing Kill Switch Service Worker...");

self.addEventListener('install', function (event) {
    // Immediately install the new service worker, bypassing the waiting state
    self.skipWaiting();
});

self.addEventListener('activate', function (event) {
    console.log("Activating Kill Switch Service Worker. Initiating cache obliteration...");

    event.waitUntil(
        // 1. Delete all existing caches created by the old Flutter PWA
        caches.keys().then(function (cacheNames) {
            return Promise.all(
                cacheNames.map(function (cacheName) {
                    console.log('Deleting out-of-date cache:', cacheName);
                    return caches.delete(cacheName);
                })
            );
        }).then(function () {
            // 2. Unregister this service worker
            console.log("Caches wiped. Unregistering self...");
            return self.registration.unregister();
        }).then(function () {
            // 3. Force all open tabs to reload so they fetch the fresh un-cached index.html
            console.log("Self unregistered. Forcing refresh on all clients.");
            return self.clients.matchAll();
        }).then(function (clients) {
            clients.forEach(client => client.navigate(client.url));
        })
    );
});

self.addEventListener('fetch', function (event) {
    // Pass through all network requests directly, no caching
    event.respondWith(fetch(event.request));
});
