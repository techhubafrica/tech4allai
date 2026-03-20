const CACHE_NAME = 'tech4all-proxy-bypass-v2';

self.addEventListener('install', (event) => {
    console.log('[Proxy SW] Installing...');
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    console.log('[Proxy SW] Activating and destroying old caches...');
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames.map((cacheName) => {
                    console.log('[Proxy SW] Deleting cache:', cacheName);
                    return caches.delete(cacheName);
                })
            );
        }).then(() => {
            console.log('[Proxy SW] Claiming clients...');
            return self.clients.claim();
        })
    );
});

self.addEventListener('fetch', (event) => {
    if (event.request.method !== 'GET') {
        return;
    }
    event.respondWith(
        fetch(event.request, { cache: 'reload' }).catch((error) => {
            try {
                const url = new URL(event.request.url);
                url.searchParams.set('fw-bypass', Date.now());
                return fetch(url.toString(), { cache: 'reload' });
            } catch (e) {
                return fetch(event.request);
            }
        })
    );
});
